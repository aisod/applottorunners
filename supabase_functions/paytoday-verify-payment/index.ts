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

    // Call PayToday API to verify transaction
    // NOTE: Replace this URL with the actual PayToday verification endpoint
    const verifyUrl = 'https://api.paytoday.com/verify' // Placeholder URL
    
    const verifyResponse = await fetch(verifyUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${PAYTODAY_PRIVATE_KEY}`,
        'X-Shop-Key': PAYTODAY_SHOP_KEY,
        'X-Shop-Handle': PAYTODAY_SHOP_HANDLE
      },
      body: JSON.stringify({
        transaction_id: transaction_id
      })
    })

    if (!verifyResponse.ok) {
      throw new Error(`PayToday API error: ${verifyResponse.status}`)
    }

    const verifyData = await verifyResponse.json()

    // Check transaction status from PayToday
    const isVerified = verifyData.status === 'completed' || verifyData.status === 'success'
    const paymentStatus = isVerified ? 'completed' : 'failed'

    // Update transaction in database
    const { error: updateError } = await supabase
      .from('paytoday_transactions')
      .update({
        status: paymentStatus,
        transaction_id: transaction_id,
        payment_intent_data: verifyData,
        updated_at: new Date().toISOString(),
        ...(isVerified && { completed_at: new Date().toISOString() })
      })
      .eq('errand_id', errand_id)
      .eq('transaction_id', transaction_id)

    if (updateError) {
      console.error('Failed to update transaction:', updateError)
      throw updateError
    }

    return new Response(
      JSON.stringify({
        verified: isVerified,
        status: paymentStatus,
        transaction_id: transaction_id,
        details: verifyData
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
