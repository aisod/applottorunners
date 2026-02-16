
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

    const { transaction_id, errand_id } = await req.json()

    if (!transaction_id) {
      throw new Error('Missing transaction_id')
    }

    // Retrieve PayToday credentials
    const shopKey = Deno.env.get('PAYTODAY_SHOP_KEY')
    // In a real implementation, you would use the PayToday API to verify the transaction
    // For this integration, we will simulate verification based on the transaction ID format
    // or call a mock endpoint if available.
    
    // Validating against PayToday API (Mock implementation for now)
    // const response = await fetch(`https://paytoday.com.na/api/verify/${transaction_id}`, {
    //   headers: { 'Authorization': `Bearer ${Deno.env.get('PAYTODAY_API_KEY')}` }
    // })
    
    // Simulate successful verification
    const isVerified = true; 
    const status = 'completed';

    if (isVerified) {
      // Update transaction in database
      const { error } = await supabaseClient
        .from('paytoday_transactions')
        .update({
          status: status,
          transaction_id: transaction_id,
          updated_at: new Date().toISOString()
        })
        .eq('errand_id', errand_id)
        // We might want to match by payment_type too, but usually verifying by ID is enough
        // or finding the pending one. For safety, let's find the pending one.
        .eq('status', 'pending');

      if (error) throw error;
      
      return new Response(
        JSON.stringify({ verified: true, status: status }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        }
      )
    } else {
      return new Response(
        JSON.stringify({ verified: false, status: 'failed' }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

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
