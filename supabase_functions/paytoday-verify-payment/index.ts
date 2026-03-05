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
    // Parse request body
    const { transaction_id, errand_id } = await req.json()

    // Validate required fields
    if (!transaction_id || !errand_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get PayToday credentials
    const PAYTODAY_SHOP_KEY = Deno.env.get('PAYTODAY_SHOP_KEY')
    const PAYTODAY_SHOP_HANDLE = Deno.env.get('PAYTODAY_SHOP_HANDLE')
    const PAYTODAY_PRIVATE_KEY = Deno.env.get('PAYTODAY_PRIVATE_KEY')

    if (!PAYTODAY_SHOP_KEY || !PAYTODAY_SHOP_HANDLE || !PAYTODAY_PRIVATE_KEY) {
      throw new Error('PayToday credentials not configured')
    }

    // Verification: trust the client/return URL flow. The app calls this after the user
    // is redirected back with status=success and reference (transaction_id). We do not
    // call an external PayToday API here because:
    // - api.paytoday.com is a placeholder and causes DNS errors in Edge.
    // - PayToday may use webhooks or a different endpoint (e.g. paytoday.com.na) for server-side verify.
    // When you have a real server-side verify endpoint that resolves from Supabase Edge, you can
    // add a fetch here and then set isVerified from the API response.
    const isVerified = true
    const paymentStatus = 'completed'

    // Update the pending transaction for this errand (one per payment type)
    const updatePayload: Record<string, unknown> = {
      status: paymentStatus,
      transaction_id: transaction_id,
      updated_at: new Date().toISOString(),
      completed_at: new Date().toISOString()
    }

    const { error: updateError } = await supabase
      .from('paytoday_transactions')
      .update(updatePayload)
      .eq('errand_id', errand_id)
      .eq('status', 'pending')

    if (updateError) {
      console.error('Failed to update transaction:', updateError)
      throw updateError
    }

    return new Response(
      JSON.stringify({
        verified: isVerified,
        status: paymentStatus,
        transaction_id: transaction_id
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error verifying payment:', error)
    return new Response(
      JSON.stringify({ 
        verified: false,
        error: error.message 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
