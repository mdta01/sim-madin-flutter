// ============================================================================
// SIM MADIN — FCM Push Notification Edge Function (v2 — REST API)
// ============================================================================
// Pakai FCM v1 REST API langsung dengan OAuth2 token dari service account.
// Tidak pakai firebase-admin SDK (kompatibilitas Deno issues).
//
// Flow:
//   1. Postgres trigger → pg_net POST ke Edge Function ini
//   2. Edge function terima { fcm_token, title, body, data, priority }
//   3. Get OAuth2 access token dari Google (JWT signed dengan private key)
//   4. POST ke FCM v1 API: https://fcm.googleapis.com/v1/projects/{project}/messages:send
//   5. Return success/failure
// ============================================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Firebase project ID
const FIREBASE_PROJECT_ID = "sim-madin-app";

/**
 * Create JWT untuk Google OAuth2 dari service account JSON.
 * Uses Web Crypto API (available in Deno).
 */
async function createJwt(serviceAccount: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const expiry = now + 3600; // 1 hour

  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: expiry,
    iat: now,
  };

  // Encode header and payload
  const encHeader = btoa(JSON.stringify(header))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
  const encPayload = btoa(JSON.stringify(payload))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const signInput = `${encHeader}.${encPayload}`;

  // Import private key
  const privateKeyPem = serviceAccount.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");

  // Decode base64 private key to ArrayBuffer
  const binaryStr = atob(privateKeyPem);
  const bytes = new Uint8Array(binaryStr.length);
  for (let i = 0; i < binaryStr.length; i++) {
    bytes[i] = binaryStr.charCodeAt(i);
  }

  // Import key
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    bytes.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  // Sign
  const encoder = new TextEncoder();
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    encoder.encode(signInput)
  );

  // Encode signature to base64url
  const sigBytes = new Uint8Array(signature);
  let sigB64 = "";
  for (let i = 0; i < sigBytes.length; i++) {
    sigB64 += String.fromCharCode(sigBytes[i]);
  }
  const encSignature = btoa(sigB64)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  return `${signInput}.${encSignature}`;
}

/**
 * Get OAuth2 access token dari Google menggunakan JWT.
 */
async function getAccessToken(serviceAccount: any): Promise<string> {
  const jwt = await createJwt(serviceAccount);

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const data = await response.json();
  return data.access_token;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { fcm_token, title, body, data, priority } = await req.json();

    if (!fcm_token || !title) {
      return new Response(
        JSON.stringify({ error: "fcm_token and title are required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get service account from env
    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT not set" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
    const serviceAccount = JSON.parse(serviceAccountJson);

    // Get OAuth2 access token
    const accessToken = await getAccessToken(serviceAccount);

    // Build FCM v1 message
    const fcmMessage = {
      message: {
        token: fcm_token,
        notification: {
          title: title,
          body: body || "",
        },
        data: data || {},
        android: {
          priority: priority === "URGENT" ? "HIGH" : "NORMAL",
          notification: {
            sound: "default",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      },
    };

    // Send via FCM v1 REST API
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;

    const fcmResponse = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(fcmMessage),
    });

    const fcmData = await fcmResponse.json();

    if (fcmResponse.status === 200) {
      return new Response(
        JSON.stringify({
          success: true,
          message_id: fcmData.name,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    } else {
      return new Response(
        JSON.stringify({
          success: false,
          error: fcmData.error?.message || "FCM send failed",
          status_code: fcmResponse.status,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
  } catch (error) {
    console.error("FCM Edge Function error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
