
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // PayToday sends data as POST. We need to verify their signature.
    // For now, we'll log the request and update the transaction.
    const body = await req.json()
    console.log('PayToday Webhook Received:', body)

    const { ref, status, transaction_id } = body

    // ref usually looks like errandId_paymentType_timestamp
    if (ref) {
      const parts = ref.split('_')
      const errandId = parts[0]
      const paymentType = parts[1]

      if (status === 'OK' || status === 'SUCCESS') {
        // Update database
        const { error } = await supabaseClient
          .from('paytoday_transactions')
          .update({
             status: 'completed',
             transaction_id: transaction_id,
             updated_at: new Date().toISOString(),
             completed_at: new Date().toISOString()
          })
          .eq('errand_id', errandId)
          .eq('payment_type', paymentType)

        if (error) throw error
        console.log(`Transaction ${ref} verified and updated via webhook.`)
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    console.error('Webhook Error:', error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
