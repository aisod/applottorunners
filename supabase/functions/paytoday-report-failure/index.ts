
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
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { error_message, errand_id, payment_type, details } = await req.json()

    console.log(`Payment Failure Reported: ${error_message}`, { errand_id, payment_type, details })

    // In a real app, you might store this in a 'payment_logs' table
    // For now, we'll just log to the function logs and update the transaction status if possible

    if (errand_id && payment_type) {
      // Find the transaction
      const { data: tx } = await supabaseClient
        .from('paytoday_transactions')
        .select('id')
        .eq('errand_id', errand_id)
        .eq('payment_type', payment_type)
        .order('created_at', { ascending: false })
        .limit(1)
        .single()
      
      if (tx) {
        await supabaseClient
          .from('paytoday_transactions')
          .update({
             status: 'failed',
             error_message: error_message,
             updated_at: new Date().toISOString()
          })
          .eq('id', tx.id)
      }
    }

    return new Response(
      JSON.stringify({ success: true }),
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
