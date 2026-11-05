// ============================================================================
// SIM MADIN — FCM Push Notification Edge Function
// ============================================================================
// Edge Function yang menerima request dari Postgres trigger (pg_net)
// dan mengirim push notification via Firebase Cloud Messaging v1 API.
//
// Flow:
//   1. Postgres trigger (fn_send_fcm_notification) → pg_net POST ke edge function
//   2. Edge function terima { fcm_token, title, body, data }
//   3. Edge function kirim ke FCM v1 API via firebase-admin
//   4. Return success/failure
//
// Deploy:
//   supabase functions deploy send-fcm-notification --no-verify-jwt
//
// Setup:
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT='{ ...json... }'
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { initializeApp, cert, getApps } from "https://esm.sh/firebase-admin/app";
import { getMessaging, Message } from "https://esm.sh/firebase-admin/messaging";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { fcm_token, title, body, data, priority } = await req.json();

    if (!fcm_token || !title) {
      return new Response(
        JSON.stringify({ error: "fcm_token and title are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Firebase Admin (singleton — only once)
    if (getApps().length === 0) {
      const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
      if (!serviceAccountJson) {
        return new Response(
          JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT not set" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      const serviceAccount = JSON.parse(serviceAccountJson);
      initializeApp({
        credential: cert(serviceAccount),
        projectId: serviceAccount.project_id,
      });
    }

    // Build FCM message
    const message: Message = {
      token: fcm_token,
      notification: {
        title: title,
        body: body || "",
      },
      data: data || {},
      android: {
        priority: priority === "URGENT" ? "high" : "normal",
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
    };

    // Send via FCM v1 API
    const messaging = getMessaging();
    const messageId = await messaging.send(message);

    return new Response(
      JSON.stringify({ success: true, message_id: messageId }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("FCM send error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
