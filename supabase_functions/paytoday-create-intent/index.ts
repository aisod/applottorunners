import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get PayToday credentials from Supabase secrets
    const PAYTODAY_SHOP_KEY = Deno.env.get('PAYTODAY_SHOP_KEY')
    const PAYTODAY_SHOP_HANDLE = Deno.env.get('PAYTODAY_SHOP_HANDLE')
    const PAYTODAY_PRIVATE_KEY = Deno.env.get('PAYTODAY_PRIVATE_KEY')

    if (!PAYTODAY_SHOP_KEY || !PAYTODAY_SHOP_HANDLE || !PAYTODAY_PRIVATE_KEY) {
      throw new Error('PayToday credentials not configured in Supabase secrets')
    }

    // Parse request body
    const { 
      errand_id, 
      amount, 
      currency, 
      payment_type,
      customer_id,
      runner_id,
      return_url,
      cancel_url,
      failure_url
    } = await req.json()

    // Validate required fields
    if (!errand_id || !amount || !payment_type || !customer_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Generate unique transaction reference
    const transactionRef = `${errand_id}_${payment_type}_${Date.now()}`

    // Create PayToday payment initialization HTML
    // This HTML will be loaded in the WebView and will initialize PayToday SDK
    const paymentHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PayToday Payment</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
            max-width: 400px;
            width: 100%;
        }
        .header {
            text-align: center;
            margin-bottom: 24px;
        }
        .amount {
            font-size: 32px;
            font-weight: bold;
            color: #2196F3;
            margin: 16px 0;
        }
        .label {
            color: #666;
            font-size: 14px;
        }
        #payment-button {
            width: 100%;
            padding: 16px;
            background: #2196F3;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            margin-top: 24px;
        }
        #payment-button:hover {
            background: #1976D2;
        }
        #payment-button:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        .loading {
            text-align: center;
            color: #666;
            margin-top: 16px;
        }
        .spinner {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #2196F3;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h2>Complete Payment</h2>
            <div class="label">Lotto Runners</div>
        </div>
        <div class="amount">${currency} ${amount.toFixed(2)}</div>
        <div class="label">Payment Type: ${payment_type === 'first_half' ? 'First Payment (50%)' : 'Final Payment (50%)'}</div>
        
        <button id="payment-button" onclick="initiatePayment()">Pay Now</button>
        
        <div id="loading" class="loading" style="display: none;">
            <div class="spinner"></div>
            <p>Processing payment...</p>
        </div>
    </div>

    <script>
        // PayToday SDK Integration
        const SHOP_KEY = '${PAYTODAY_SHOP_KEY}';
        const SHOP_HANDLE = '${PAYTODAY_SHOP_HANDLE}';
        const PRIVATE_KEY = '${PAYTODAY_PRIVATE_KEY}';
        
        async function initiatePayment() {
            const button = document.getElementById('payment-button');
            const loading = document.getElementById('loading');
            
            button.disabled = true;
            loading.style.display = 'block';
            
            try {
                // Initialize PayToday payment
                // NOTE: Replace this with actual PayToday SDK initialization
                // This is a placeholder - you need to integrate the real PayToday SDK
                
                // Simulate payment processing
                await new Promise(resolve => setTimeout(resolve, 2000));
                
                // For now, simulate success
                // In production, this should use the actual PayToday SDK
                const transactionId = 'PT_' + Date.now();
                
                // Redirect to success URL
                window.location.href = '${return_url}&transaction_id=' + transactionId;
                
            } catch (error) {
                console.error('Payment error:', error);
                // Redirect to failure URL
                window.location.href = '${failure_url}&error=' + encodeURIComponent(error.message);
            }
        }
        
        // Handle cancel
        function cancelPayment() {
            window.location.href = '${cancel_url}';
        }
    </script>
</body>
</html>
    `

    // Convert HTML to data URI
    const dataUri = `data:text/html;base64,${btoa(paymentHtml)}`

    // Return the data URI and intent details
    return new Response(
      JSON.stringify({
        data_uri: dataUri,
        intent_id: transactionRef,
        amount: amount,
        currency: currency,
        payment_type: payment_type
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error creating payment intent:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
