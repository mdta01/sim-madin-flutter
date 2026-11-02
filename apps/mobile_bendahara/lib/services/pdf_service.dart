// ============================================================================
// SIM MADIN — PDF Service (Phase 3 — mobile_bendahara)
// ============================================================================
// Generate PDF lokal di device pakai package `pdf` + `printing`.
//
// Dokumen yang bisa di-generate:
//   - Kwitansi Pembayaran (untuk slip pembayaran santri)
//   - Slip Honor Guru (untuk slip honor periode)
//
// Desain: A5 portrait, Islamic green header, gold accent.
// Font: pakai default PDF font (Helvetica) — untuk Indonesian characters
// cukup. Kalau butuh Arabic, tambahkan font NotoNaskhArabic nanti.
// ============================================================================

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared/shared.dart';
import 'package:path_provider/path_provider.dart';

import 'package:api_client/api_client.dart';

class PdfService {
  PdfService._();

  // ---------------------------------------------------------------------------
  // Kwitansi Pembayaran
  // ---------------------------------------------------------------------------

  /// Generate + cetak/share kwitansi pembayaran.
  /// Pakai `Printing.sharePdf` supaya user bisa share ke WA/email/print.
  static Future<void> shareKwitansiPembayaran(PaymentModel payment) async {
    final doc = _buildKwitansiPembayaran(payment);
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'kwitansi-${payment.invoiceNo}.pdf',
    );
  }

  /// Simpan PDF ke file (untuk preview via Printing.layoutPdf).
  static Future<File?> saveKwitansiPembayaran(PaymentModel payment) async {
    final doc = _buildKwitansiPembayaran(payment);
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/kwitansi-${payment.invoiceNo}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  static pw.Document _buildKwitansiPembayaran(PaymentModel payment) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            _Header(title: 'KWITANSI PEMBAYARAN'),
            pw.SizedBox(height: 16),

            // Invoice info
            _InfoLine(label: 'No. Invoice', value: payment.invoiceNo),
            _InfoLine(
                label: 'Tanggal',
                value: DateFormat('d MMMM yyyy, HH:mm')
                    .format(payment.paymentDate.toLocal())),
            _InfoLine(label: 'Metode', value: PaymentMethod.label(payment.paymentMethod)),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 12),

            // Penerima
            pw.Text('Diterima dari:',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(payment.santriName ?? 'Santri',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (payment.santriNis != null)
              pw.Text('NIS: ${payment.santriNis}',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            if (payment.tagihanCode != null)
              pw.Text('Untuk: ${payment.tagihanCode}',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
            pw.SizedBox(height: 16),

            // Amount (besar)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFD1FAE5),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromInt(0xFF0D7A4F)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Jumlah Diterima',
                      style: pw.TextStyle(
                          fontSize: 11, color: PdfColor.fromInt(0xFF0A5C38))),
                  pw.SizedBox(height: 4),
                  pw.Text(formatRupiah(payment.amount),
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF0A5C38),
                      )),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Status
            pw.Row(
              children: [
                pw.Text('Status: ',
                    style: pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey700)),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: payment.status == PaymentStatus.verified
                        ? PdfColor.fromInt(0xFFD1FAE5)
                        : payment.status == PaymentStatus.pending
                            ? PdfColor.fromInt(0xFFFEF3C7)
                            : PdfColor.fromInt(0xFFFEE2E2),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    payment.status,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: payment.status == PaymentStatus.verified
                          ? PdfColor.fromInt(0xFF0A5C38)
                          : payment.status == PaymentStatus.pending
                              ? PdfColor.fromInt(0xFF92400E)
                              : PdfColor.fromInt(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
            if (payment.note != null && payment.note!.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('Catatan:',
                  style: pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700)),
              pw.Text(payment.note!,
                  style: const pw.TextStyle(fontSize: 11)),
            ],

            pw.Spacer(),

            // Footer signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Penerima Pembayaran,',
                        style: pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey700)),
                    pw.SizedBox(height: 60),
                    pw.Text('(Bendahara Madrasah)',
                        style: pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Hormat kami,',
                        style: pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey700)),
                    pw.SizedBox(height: 60),
                    pw.Text('SIM MADIN',
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF0D7A4F))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  // ---------------------------------------------------------------------------
  // Slip Honor Guru
  // ---------------------------------------------------------------------------

  static Future<void> shareSlipHonorGuru(HonorGuruModel honor) async {
    final doc = _buildSlipHonorGuru(honor);
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'slip-honor-${honor.periode}-${honor.id}.pdf',
    );
  }

  static pw.Document _buildSlipHonorGuru(HonorGuruModel honor) {
    final pdf = pw.Document();
    final total = honor.totalHonor > 0
        ? honor.totalHonor
        : computeTotalHonor(honor);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _Header(title: 'SLIP HONOR GURU'),
            pw.SizedBox(height: 16),

            // Header info
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF9FAFB),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromInt(0xFFE5E7EB)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _InfoLine(label: 'Nama Guru', value: honor.guruName ?? '-'),
                  if (honor.guruSpecialization != null)
                    _InfoLine(
                        label: 'Spesialisasi', value: honor.guruSpecialization!),
                  _InfoLine(label: 'Periode', value: honor.periodeLabel),
                  _InfoLine(label: 'Status',
                      value: HonorGuruStatus.label(honor.status)),
                  if (honor.paidAt != null)
                    _InfoLine(
                        label: 'Tanggal Bayar',
                        value:
                            DateFormat('d MMMM yyyy').format(honor.paidAt!.toLocal())),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Komponen honor table
            pw.Text('Rincian Honor',
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _HonorTable(honor: honor, total: total),

            pw.SizedBox(height: 16),

            // Total box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFD1FAE5),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromInt(0xFF0D7A4F)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL HONOR DITERIMA',
                      style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF0A5C38))),
                  pw.Text(formatRupiah(total),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF0A5C38),
                      )),
                ],
              ),
            ),

            if (honor.catatan != null && honor.catatan!.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text('Catatan:',
                  style: pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700)),
              pw.Text(honor.catatan!,
                  style: const pw.TextStyle(fontSize: 11)),
            ],

            pw.Spacer(),

            // Footer
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                    'Dicetak: ${DateFormat('d MMMM yyyy, HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey500)),
                pw.Text('SIM MADIN',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF0D7A4F))),
              ],
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  // ---------------------------------------------------------------------------
  // Laporan Keuangan (optional, untuk export bulanan)
  // ---------------------------------------------------------------------------

  static Future<void> shareLaporanKeuangan(LaporanKeuangan laporan) async {
    final doc = _buildLaporanKeuangan(laporan);
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'laporan-keuangan-${laporan.year}-${laporan.month.toString().padLeft(2, '0')}.pdf',
    );
  }

  static pw.Document _buildLaporanKeuangan(LaporanKeuangan laporan) {
    final pdf = pw.Document();
    final months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final monthLabel = '${months[laporan.month]} ${laporan.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _Header(title: 'LAPORAN KEUANGAN — $monthLabel'),
        build: (ctx) => [
          pw.SizedBox(height: 12),

          // Summary
          pw.Row(
            children: [
              pw.Expanded(
                child: _SummaryBox(
                  label: 'Pemasukan',
                  value: formatRupiah(laporan.pemasukan),
                  color: PdfColor.fromInt(0xFF0D7A4F),
                  bg: PdfColor.fromInt(0xFFD1FAE5),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _SummaryBox(
                  label: 'Pengeluaran',
                  value: formatRupiah(laporan.pengeluaran),
                  color: PdfColor.fromInt(0xFFB91C1C),
                  bg: PdfColor.fromInt(0xFFFEE2E2),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _SummaryBox(
                  label: 'Saldo',
                  value: formatRupiah(laporan.saldo),
                  color: laporan.saldo >= 0
                      ? PdfColor.fromInt(0xFF0D7A4F)
                      : PdfColor.fromInt(0xFFB91C1C),
                  bg: PdfColor.fromInt(0xFFF3F4F6),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Pemasukan per kategori
          pw.Text('Pemasukan per Kategori',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _KategoriTable(data: laporan.pemasukanPerKategori),
          pw.SizedBox(height: 16),

          // Pengeluaran per kategori
          pw.Text('Pengeluaran per Kategori',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _KategoriTable(data: laporan.pengeluaranPerKategori),
          pw.SizedBox(height: 16),

          // Detail transaksi
          pw.Text('Detail Transaksi (${laporan.transaksi.length})',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _TransaksiTable(transaksi: laporan.transaksi),
        ],
      ),
    );

    return pdf;
  }
}

// ---------------------------------------------------------------------------
// PDF Widget helpers
// ---------------------------------------------------------------------------

class _Header extends pw.StatelessWidget {
  _Header({required this.title});

  final String title;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF0D7A4F),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text('SIM MADIN',
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
              pw.Spacer(),
              pw.Text('Madrasah Diniyah',
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.white)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends pw.StatelessWidget {
  _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey700)),
          ),
          pw.Text(': ',
              style: pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey700)),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}

class _HonorTable extends pw.StatelessWidget {
  _HonorTable({required this.honor, required this.total});

  final HonorGuruModel honor;
  final double total;

  @override
  pw.Widget build(pw.Context context) {
    final rows = <List<String>>[
      ['Honor Mengajar', formatRupiah(honor.honorMengajar)],
      ['Insentif', '+ ${formatRupiah(honor.insentif)}'],
      ['Tunjangan', '+ ${formatRupiah(honor.tunjangan)}'],
      ['Potongan', '- ${formatRupiah(honor.potongan)}'],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE5E7EB)),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        for (final row in rows)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(row[0],
                    style: pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey700)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(row[1],
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.normal)),
              ),
            ],
          ),
      ],
    );
  }
}

class _SummaryBox extends pw.StatelessWidget {
  _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  final String label;
  final String value;
  final PdfColor color;
  final PdfColor bg;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 10, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _KategoriTable extends pw.StatelessWidget {
  _KategoriTable({required this.data});

  final Map<String, double> data;

  @override
  pw.Widget build(pw.Context context) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE5E7EB)),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Kategori',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Jumlah',
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        for (final entry in sorted)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(entry.key,
                    style: const pw.TextStyle(fontSize: 11)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(formatRupiah(entry.value),
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.normal)),
              ),
            ],
          ),
      ],
    );
  }
}

class _TransaksiTable extends pw.StatelessWidget {
  _TransaksiTable({required this.transaksi});

  final List<TransaksiKasModel> transaksi;

  @override
  pw.Widget build(pw.Context context) {
    if (transaksi.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF9FAFB),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Center(
          child: pw.Text('Tidak ada transaksi pada periode ini.',
              style: pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey500)),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE5E7EB)),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FixedColumnWidth(60), // Tanggal
        1: pw.FlexColumnWidth(2),   // Kategori
        2: pw.FlexColumnWidth(2),   // Keterangan
        3: pw.FixedColumnWidth(70), // Kas
        4: pw.FixedColumnWidth(80), // Jumlah
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
          children: [
            _headerCell('Tanggal'),
            _headerCell('Kategori'),
            _headerCell('Keterangan'),
            _headerCell('Kas'),
            _headerCell('Jumlah'),
          ],
        ),
        for (final t in transaksi)
          pw.TableRow(
            children: [
              _cell(DateFormat('d/M').format(t.transaksiDate.toLocal())),
              _cell(TransaksiKasCategory.label(t.category)),
              _cell(t.description),
              _cell(t.kasName ?? '-'),
              _cell(
                (t.type == TransaksiKasType.pemasukan ? '+' : '-') +
                    formatRupiah(t.amount),
                color: t.type == TransaksiKasType.pemasukan
                    ? PdfColor.fromInt(0xFF0D7A4F)
                    : PdfColor.fromInt(0xFFB91C1C),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _headerCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold)),
      );

  pw.Widget _cell(String text, {PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(fontSize: 9, color: color)),
      );
}
