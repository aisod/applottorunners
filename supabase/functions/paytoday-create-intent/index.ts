
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import * as crypto from "https://deno.land/std@0.177.0/node/crypto.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    let amount, currency, errand_id, payment_type, return_url;

    if (req.method === 'POST') {
      const body = await req.json();
      amount = body.amount;
      currency = body.currency;
      errand_id = body.errand_id;
      payment_type = body.payment_type;
      return_url = body.return_url;
    } else if (req.method === 'GET') {
      const url = new URL(req.url);
      amount = url.searchParams.get('amount');
      currency = url.searchParams.get('currency');
      errand_id = url.searchParams.get('errand_id');
      payment_type = url.searchParams.get('payment_type');
      return_url = url.searchParams.get('return_url');
    }

    // Validate request
    if (!amount || !errand_id || !payment_type) {
      throw new Error('Missing required fields');
    }

    // Retrieve PayToday credentials from secrets
    const shopKey = Deno.env.get('PAYTODAY_SHOP_KEY')
    const shopHandle = Deno.env.get('PAYTODAY_SHOP_HANDLE')

    if (!shopKey || !shopHandle) {
      throw new Error('PayToday credentials not configured')
    }

    // Construct HTML content
    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>PayToday Payment</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: #f5f5f5; }
          .loader { border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 30px; height: 30px; animation: spin 1s linear infinite; }
          @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
          .message { text-align: center; margin-top: 20px; color: #666; }
        </style>
      </head>
      <body>
        <div>
          <div class="loader"></div>
          <div class="message">Initializing secure payment...</div>
        </div>
        
        <form id="paytoday-form" action="https://paytoday.com.na/pay" method="POST" style="display:none;">
          <input type="hidden" name="shop_key" value="${shopKey}">
          <input type="hidden" name="shop_handle" value="${shopHandle}">
          <input type="hidden" name="amount" value="${amount}">
          <input type="hidden" name="currency" value="${currency || 'NAD'}">
          <input type="hidden" name="ref" value="${errand_id}_${payment_type}_${Date.now()}">
          <input type="hidden" name="return_url" value="${return_url}">
          <input type="hidden" name="cancel_url" value="${return_url.replace('success', 'cancel')}">
          <input type="hidden" name="notify_url" value="${Deno.env.get('SUPABASE_URL')}/functions/v1/paytoday-webhook">
        </form>

        <script>
          window.onload = function() {
            document.getElementById('paytoday-form').submit();
          };
        </script>
      </body>
      </html>
    `;

    if (req.method === 'GET') {
      return new Response(htmlContent, {
        headers: { ...corsHeaders, 'Content-Type': 'text/html' },
        status: 200,
      });
    }

    // Encode HTML to data URI for WebView (backwards compatibility for mobile/windows)
    const dataUri = `data:text/html;base64,${btoa(htmlContent)}`;
    const intentId = crypto.randomUUID();

    return new Response(
      JSON.stringify({ 
        data_uri: dataUri,
        intent_id: intentId,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
