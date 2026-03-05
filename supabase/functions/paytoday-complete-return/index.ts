import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

/**
 * Completes a payment return from the PayToday redirect.
 * Uses service role so the DB update always runs (no RLS / auth timing issues).
 * Call this from the /payment-return page so the transaction is updated and you get logs here.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      console.error("paytoday-complete-return: missing or invalid Authorization");
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const { errand_id, payment_type, transaction_id, status } = body;

    if (!errand_id || !payment_type) {
      console.error("paytoday-complete-return: missing errand_id or payment_type", body);
      return new Response(
        JSON.stringify({ error: "Missing errand_id or payment_type" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const isSuccess = status === "completed" || status === "success";
    const paymentStatus = isSuccess ? "completed" : "failed";
    const errorMessage = isSuccess ? undefined : "Payment cancelled or failed";

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const updatePayload: Record<string, unknown> = {
      status: paymentStatus,
      updated_at: new Date().toISOString(),
      ...(transaction_id && { transaction_id }),
      ...(errorMessage && { error_message: errorMessage }),
      ...(isSuccess && { completed_at: new Date().toISOString() }),
    };

    const { data, error } = await supabase
      .from("paytoday_transactions")
      .update(updatePayload)
      .eq("errand_id", errand_id)
      .eq("payment_type", payment_type)
      .eq("status", "pending")
      .select("id, status")
      .maybeSingle();

    if (error) {
      console.error("paytoday-complete-return: update error", error);
      return new Response(
        JSON.stringify({ error: error.message, updated: false }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!data) {
      console.warn(
        "paytoday-complete-return: no pending row found",
        errand_id,
        payment_type
      );
      return new Response(
        JSON.stringify({
          updated: false,
          message: "No pending transaction found for this errand and payment type",
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(
      "paytoday-complete-return: updated",
      data.id,
      "to",
      paymentStatus,
      "errand_id=",
      errand_id,
      "payment_type=",
      payment_type
    );

    return new Response(
      JSON.stringify({ updated: true, status: paymentStatus, row: data }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("paytoday-complete-return: unexpected error", e);
    return new Response(
      JSON.stringify({ error: String(e), updated: false }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
