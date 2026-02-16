
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const PAYTODAY_SDK_URL =
  'https://nedbankstorage.blob.core.windows.net/nedbankclouddatadisk/staticazure/web/sdk/paytoday-sdk.js';

// CORS headers helper
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  console.log('PayToday Function Invoked:', req.method, req.url);

  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  try {

    // Only allow POST and GET requests
    if (req.method !== 'POST' && req.method !== 'GET') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        {
          status: 405,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    }

    // AUTHENTICATION CHECK
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    let user = null;
    let isAnon = false;
    const authHeader = req.headers.get('Authorization');
    const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') || '';

    // 1. Try standard header auth
    if (authHeader) {
      const token = authHeader.replace('Bearer ', '');
      if (token === SUPABASE_ANON_KEY) {
        isAnon = true;
      } else {
        const { data: { user: u } } = await supabaseClient.auth.getUser(token);
        if (u) user = u;
      }
    }


    // 2. If no user from header, check query param (for Web GET requests)
    if (!user && req.method === 'GET') {
      const url = new URL(req.url);
      const authToken = url.searchParams.get('auth_token');
      if (authToken) {
        // Create a new client to verify this specific token
        const authClient = createClient(
          Deno.env.get('SUPABASE_URL') ?? '',
          Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        );
        const { data: { user: u }, error } = await authClient.auth.getUser(authToken);
        if (u) user = u;
      }
    }

    // If still no user and not anon, block access
    if (!user && !isAnon) {
      console.error('Unauthorized: No valid user found via Header or Query Param');
      return new Response(
        JSON.stringify({ error: 'Unauthorized', message: 'Valid token or anon key required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }



    // Get PayToday credentials from environment variables
    const PAYTODAY_SHOP_KEY = Deno.env.get('PAYTODAY_SHOP_KEY');
    const PAYTODAY_SHOP_HANDLE = Deno.env.get('PAYTODAY_SHOP_HANDLE');
    const PAYTODAY_PRIVATE_KEY = Deno.env.get('PAYTODAY_PRIVATE_KEY');

    // Validate credentials
    if (!PAYTODAY_SHOP_KEY || !PAYTODAY_SHOP_HANDLE) {
      console.error('PayToday credentials not configured properly');
    }

    // Parse request data from JSON body (POST) or query parameters (GET)
    let requestData;
    if (req.method === 'POST') {
      try {
        requestData = await req.json();
      } catch (e) {
        return new Response(
          JSON.stringify({
            error: 'Invalid JSON in request body',
            message: e.message || e.toString(),
          }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              'Content-Type': 'application/json',
            },
          }
        );
      }
    } else {
      // GET request - parse from query parameters
      const url = new URL(req.url);
      requestData = {
        amount: parseFloat(url.searchParams.get('amount') || '0'),
        errand_id: url.searchParams.get('errand_id') || '',
        payment_type: url.searchParams.get('payment_type') || '',
        user_email: url.searchParams.get('user_email') || '',
        user_phone_number: url.searchParams.get('user_phone_number') || '',
        user_first_name: url.searchParams.get('user_first_name') || 'Customer',
        user_last_name: url.searchParams.get('user_last_name') || 'Name',
        return_url: url.searchParams.get('return_url') || '',
      };
    }

    /*
      Mapping fields from our app to the PayToday SDK expectation:
      - errand_id -> used for invoice_number
      - payment_type -> used for invoice_number suffix
      - amount -> amount
      - user_email -> user_email
    */

    const {
      amount,
      errand_id,
      payment_type,
      user_email,
      user_phone_number,
      user_first_name, // Optional, can be passed from app
      user_last_name, // Optional, can be passed from app
      return_url,
    } = requestData;

    // Validate required fields
    if (!amount || !errand_id || !payment_type) {
      return new Response(
        JSON.stringify({
          error: 'Missing required fields: amount, errand_id, payment_type',
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        }
      );
    }

    // Construct invoice number (unique ref)
    const invoice_number = `${errand_id}_${payment_type}_${Date.now()}`;

    // Validate amount is reasonable (not accidentally in cents)
    if (amount > 1000000) {
      console.warn(`⚠️ Amount seems unusually large: ${amount}. PayToday expects dollars (NAD), not cents`);
    }

    // Defaults
    const ptFirstName = user_first_name || 'Customer';
    const ptLastName = user_last_name || 'Name';
    const ptEmail = user_email || user?.email || 'customer@example.com';

    console.log('📤 Creating PayToday payment intent (SDK Style)...');
    console.log(`💰 Amount: N$${amount}`);
    console.log(`📝 Invoice: ${invoice_number}`);

    // Generate HTML content with PayToday SDK (Reference Style)
    // Using the spinner and simple layout from the working reference
    const htmlContent = `<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PayToday Payment</title>
    <script src="${PAYTODAY_SDK_URL}"></script>
</head>
<body style="display: flex; justify-content: center; align-items: center; height: 100vh; font-family: sans-serif; margin: 0;">
    <div id="status" style="text-align: center;">
        <div style="border: 4px solid #f3f3f3; border-top: 4px solid #3498db; border-radius: 50%; width: 40px; height: 40px; animation: spin 2s linear infinite; margin: 0 auto 20px;"></div>
        <p>Initializing secure payment...</p>
        <div id="error-msg" style="color: red; margin-top: 10px; display: none;"></div>
    </div>
    <style>@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }</style>
    <script>
        window.onload = function() {
            function showError(msg) {
                const el = document.getElementById('error-msg');
                if (el) {
                    el.innerText = msg;
                    el.style.display = 'block';
                }
                const status = document.getElementById('status');
                if (status) {
                     // Keep spinner or hide it? Reference keeps it but changes text.
                     // We will append error.
                }
            }

            if (typeof PayToday === 'undefined') {
                showError('Error: PayToday SDK failed to load.');
                return;
            }

            // PayToday credentials from Env
            const shopKey = "${PAYTODAY_SHOP_KEY || ''}";
            const shopHandle = "${PAYTODAY_SHOP_HANDLE || ''}";
            const privateKey = "${PAYTODAY_PRIVATE_KEY || ''}";

            const paytoday = new PayToday({
                shopKey: shopKey,
                shopHandle: shopHandle,
                privateKey: privateKey,
                environment: 'production',
            });

            console.log('PayToday: Initializing...');
            
            paytoday.initialize().then(success => {
                if (success) {
                    console.log('PayToday: Initialized. Creating intent...');
                    
                    const phoneNumber = "${user_phone_number || '0000000000'}".trim() || '0000000000';
                    
                    paytoday.createPaymentIntent({
                        amount: ${amount}, // Keep as dollars/NAD per previous instructions
                        invoice_number: "${invoice_number}",
                        user_first_name: "${ptFirstName}",
                        user_last_name: "${ptLastName}",
                        user_email: "${ptEmail}",
                        user_phone_number: phoneNumber,
                        return_url: "${return_url || ''}",
                    }).then(intent => {
                        console.log('PayToday: Intent created', intent);
                        const url = intent?.data?.payment_url || intent?.data?.checkout_url || intent?.payment_url;
                        if (url) {
                            console.log('PayToday: Redirecting to', url);
                            window.location.href = url;
                        } else {
                            showError('Error: Could not get payment URL from PayToday response.');
                            console.error('PayToday Response:', intent);
                        }
                    }).catch(e => {
                        console.error('PayToday Intent Error:', e);
                        showError('Error: ' + (e.message || e));
                    });
                } else {
                    showError('Error: PayToday initialization failed.');
                }
            }).catch(e => {
                console.error('PayToday Init Error:', e);
                showError('Error: ' + (e.message || e));
            });
        };
    </script>
</body>
</html>`;

    // For GET requests (Web browsers), return HTML directly
    // For POST requests (mobile apps), return data URI in JSON
    if (req.method === 'GET') {
      return new Response(htmlContent, {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'text/html; charset=utf-8',
        },
      });
    }

    // For POST requests, encode to data URI and return in JSON
    const uint8Array = new TextEncoder().encode(htmlContent);
    let binaryString = '';
    const chunkSize = 8192;
    for (let i = 0; i < uint8Array.length; i += chunkSize) {
      const chunk = uint8Array.slice(i, Math.min(i + chunkSize, uint8Array.length));
      for (let j = 0; j < chunk.length; j++) {
        binaryString += String.fromCharCode(chunk[j]);
      }
    }
    const base64Content = btoa(binaryString);
    const dataUri = `data:text/html;charset=utf-8;base64,${base64Content}`;
    const intentId = crypto.randomUUID();

    return new Response(
      JSON.stringify({
        data_uri: dataUri,
        html_content: htmlContent,
        intent_id: intentId,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );

  } catch (error) {
    console.error('Error in function:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        message: error.message || error.toString(),
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      }
    );
  }
});
