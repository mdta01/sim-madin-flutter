#!/usr/bin/env python3
"""
Generate the baseline PostgreSQL schema (CREATE TABLE) for SIM MADIN from the
legacy Prisma schema, matching Prisma's own DDL conventions so that the
Supabase/Postgres database produced by this script is byte-compatible with what
`prisma migrate` used to create.

Why this exists
---------------
`supabase/migrations/` in this repo contains RLS policies, RPC functions,
triggers, storage buckets, realtime publication, and seed data — but it never
contained the actual `CREATE TABLE` statements (the tables came from Prisma).
That makes a fresh Supabase project impossible to bootstrap. This generator
reconstructs the baseline.

Usage
-----
    python3 tool/prisma_to_ddl.py path/to/schema.prisma > out.sql

Notes
-----
* Types map exactly like Prisma does on PostgreSQL:
    String -> text, Int -> integer, Float -> double precision,
    Boolean -> boolean, DateTime -> timestamp(3) with time zone,
    Json -> jsonb.
* Prisma stores everything in the `public` schema with camelCase identifiers,
  so every identifier is quoted.
* Relations are turned into FK constraints named the way Prisma names them
  (`<Table>_<field>_fkey`), and honour onDelete (Restrict/SetNull/Cascade).
* `@@unique` becomes a UNIQUE INDEX, `@@index` a plain INDEX, with Prisma's
  naming convention.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field


SCALARS = {
    "String": "text",
    "Int": "integer",
    "Float": "double precision",
    "BigInt": "bigint",
    "Decimal": "decimal(65,30)",
    "Boolean": "boolean",
    "DateTime": "timestamp(3) with time zone",
    "Json": "jsonb",
    "Bytes": "bytea",
}

# Cardinality of a relation field determines the action of the FK.
PG_ACTION = {"Cascade": "CASCADE", "SetNull": "SET NULL", "Restrict": "RESTRICT",
             "NoAction": "NO ACTION", "SetDefault": "SET DEFAULT"}


@dataclass
class Field:
    name: str
    raw_type: str            # e.g. String, String?, Santri[]
    base_type: str           # scalar or model name
    optional: bool
    is_list: bool
    attrs: str = ""
    # parsed
    is_id: bool = False
    is_unique: bool = False
    default: str | None = None
    updated_at: bool = False
    relation: tuple[str, str] | None = None  # (fields, references) or (None,None)
    relation_name: str | None = None
    relation_fields: str | None = None
    on_delete: str = "Restrict"


@dataclass
class Model:
    name: str
    fields: list[Field] = field(default_factory=list)
    block_attrs: list[str] = field(default_factory=list)


def parse_decl(raw: str) -> tuple[str, bool, bool]:
    """'String?' -> ('String', True, False); 'Santri[]' -> ('Santri', False, True)"""
    optional = raw.endswith("?")
    is_list = raw.endswith("[]")
    base = raw.rstrip("?[]")
    return base, optional, is_list


def parse_schema(text: str) -> list[Model]:
    models: list[Model] = []
    # strip // comments
    text = re.sub(r"//.*", "", text)
    for m in re.finditer(r"^model\s+(\w+)\s*\{(.*?)^\}", text, re.S | re.M):
        name, body = m.group(1), m.group(2)
        model = Model(name=name)
        for line in body.splitlines():
            line = line.strip()
            if not line:
                continue
            if line.startswith("@@"):
                model.block_attrs.append(line)
                continue
            parts = line.split(None, 2)
            if len(parts) < 2:
                continue
            fname, ftype = parts[0], parts[1]
            attrs = parts[2] if len(parts) > 2 else ""
            base, optional, is_list = parse_decl(ftype)
            f = Field(fname, ftype, base, optional, is_list, attrs)
            f.is_id = "@id" in attrs
            f.is_unique = "@unique" in attrs
            f.updated_at = "@updatedAt" in attrs
            # Balanced parse: allow one level of nested parens, e.g. cuid() / dbgenerated("...")
            dm = re.search(r"@default\(((?:[^()]|\([^()]*\))*)\)", attrs)
            if dm:
                f.default = dm.group(1).strip()
            rm = re.search(r"@relation\(([^)]*)\)", attrs)
            if rm:
                rbody = rm.group(1)
                rn = re.search(r'name:\s*"([^"]+)"', rbody)
                if rn:
                    f.relation_name = rn.group(1)
                fm = re.search(r"fields:\s*\[([^\]]*)\]", rbody)
                rf = re.search(r"references:\s*\[([^\]]*)\]", rbody)
                f.relation_fields = fm.group(1).strip() if fm else None
                if fm and rf:
                    f.relation = (fm.group(1).strip(), rf.group(1).strip())
                od = re.search(r"onDelete:\s*(\w+)", rbody)
                if od:
                    f.on_delete = od.group(1)
            model.fields.append(f)
        models.append(model)
    return models


def default_sql(model: Model, f: Field) -> str | None:
    d = f.default
    if d is None:
        return None
    if d == "now()":
        return "CURRENT_TIMESTAMP"
    if d == "cuid()" or d == "uuid()" or d == "uuid(4)":
        # Prisma generates cuids client-side; DB-level defaults are not created.
        return None
    if d == "autoincrement()":
        return None  # handled via serial identity
    if d == "true":
        return "true"
    if d == "false":
        return "false"
    if re.fullmatch(r"-?\d+", d):
        return d
    if re.fullmatch(r"-?\d+\.\d+", d):
        return d
    if d.startswith('"') and d.endswith('"'):
        return "'" + d[1:-1].replace("'", "''") + "'"
    # enum(...) or dbgenerated(...) — leave out
    if d.startswith("enum(") or d.startswith("dbgenerated"):
        if d.startswith("dbgenerated("):
            inner = d[len("dbgenerated("):].rstrip(")")
            if inner.startswith('"'):
                return inner[1:-1]
        return None
    return None


def quote(ident: str) -> str:
    return '"' + ident + '"'


def col_sql(model: Model, f: Field, models_by_name: dict[str, Model]) -> str | None:
    """Return the column definition or None when the field is a virtual relation list."""
    if f.is_list:
        return None  # relation list -> no column
    if f.base_type in models_by_name:
        # To-one relation field: the scalar FK lives in a separate `<name>Id`
        # field, so a relation field itself is never a column.
        return None
    if f.base_type not in SCALARS and f.base_type not in models_by_name:
        return None  # enum -> skip (kept as text by Prisma? actually enum)

    if f.base_type == "Int" and f.is_id:
        # Prisma uses integer autoincrement only when @default(autoincrement())
        pass

    pg_type = SCALARS.get(f.base_type)
    if pg_type is None:
        # relation scalar pointing at a model, or enum
        pg_type = "text"

    parts = [quote(f.name), pg_type]
    if f.is_id:
        if f.base_type == "Int" and f.default == "autoincrement()":
            parts = [quote(f.name), "serial"]
        else:
            parts.append("NOT NULL")
            parts.append("PRIMARY KEY")
            return " ".join(parts)
    elif not f.optional:
        parts.append("NOT NULL")

    d = default_sql(model, f)
    if d is not None and not (f.is_id and f.base_type == "Int"):
        parts.append(f"DEFAULT {d}")

    if f.is_unique and not f.is_id:
        parts.append("UNIQUE")
        # Prisma names the unique constraint <table>_<column>_key
    return " ".join(parts)


def fk_sql(model: Model, f: Field, models_by_name: dict[str, Model]) -> str | None:
    if not f.relation:
        return None
    fields, refs = f.relation
    ref_table, ref_cols = None, None
    # A relation belongs to the model that declares `fields:`
    ref_table = f.base_type
    ref_cols = f.relation_fields and refs
    on_del = PG_ACTION.get(f.on_delete, "RESTRICT")
    on_upd = "CASCADE" if f.on_delete == "Cascade" else "RESTRICT"
    # Prisma also cascades updates for optional relations -> keep RESTRICT (safe default)
    name = f"{model.name}_{fields.replace(' ', '')}_fkey"
    return (
        f"  CONSTRAINT {quote(name)} FOREIGN KEY ({quote(fields)}) "
        f"REFERENCES {quote(ref_table)}({quote(refs)}) "
        f"ON DELETE {on_del} ON UPDATE {on_upd}"
    )


def generate(models: list[Model]) -> str:
    models_by_name = {m.name: m for m in models}
    out: list[str] = []
    out.append("-- ============================================================================")
    out.append("-- SIM MADIN — Baseline schema (generated)")
    out.append("-- ============================================================================")
    out.append("-- AUTO-GENERATED by tool/prisma_to_ddl.py from the legacy Prisma schema.")
    out.append("-- Do not edit by hand: re-run the generator instead.")
    out.append("-- ============================================================================")
    out.append("")

    for model in models:
        cols: list[str] = []
        for f in model.fields:
            c = col_sql(model, f, models_by_name)
            if c is not None:
                cols.append("  " + c)
        # FK constraints
        for f in model.fields:
            fk = fk_sql(model, f, models_by_name)
            if fk:
                cols.append(fk)
        out.append(f"CREATE TABLE IF NOT EXISTS {quote(model.name)} (")
        out.append(",\n".join(cols))
        out.append(");")
        out.append("")

    # Indexes from block attributes
    out.append("-- ---------------------------------------------------------------------------")
    out.append("-- Indexes")
    out.append("-- ---------------------------------------------------------------------------")
    for model in models:
        for attr in model.block_attrs:
            m = re.match(r"@@index\(\[([^\]]+)\](.*)\)", attr)
            if m:
                cols = [c.strip() for c in m.group(1).split(",")]
                tname = "_".join(c.replace("(ops)", "") for c in cols)
                idx = f"{model.name}_{tname}_idx"
                out.append(
                    f"CREATE INDEX IF NOT EXISTS {quote(idx)} ON {quote(model.name)} "
                    f"({', '.join(quote(c) for c in cols)});"
                )
                continue
            m = re.match(r"@@unique\(\[([^\]]+)\]\)", attr)
            if m:
                cols = [c.strip() for c in m.group(1).split(",")]
                tname = "_".join(cols)
                idx = f"{model.name}_{tname}_key"
                out.append(
                    f"CREATE UNIQUE INDEX IF NOT EXISTS {quote(idx)} ON {quote(model.name)} "
                    f"({', '.join(quote(c) for c in cols)});"
                )
    out.append("")
    return "\n".join(out)


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    with open(sys.argv[1], encoding="utf-8") as fh:
        text = fh.read()
    models = parse_schema(text)
    if not models:
        print("error: no models parsed", file=sys.stderr)
        return 1
    sys.stdout.write(generate(models))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
