
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

    // ref format: bookingId_paymentType_bookingType_timestamp
    if (ref) {
      const parts = ref.split('_')
      const bookingId = parts[0]
      const paymentType = parts[1]
      const bookingType = parts[2] || 'errand' // Default to errand for backward compatibility

      if (status === 'OK' || status === 'SUCCESS') {
        const now = new Date().toISOString()

        // Update transaction database
        const { error: txError } = await supabaseClient
          .from('paytoday_transactions')
          .update({
            status: 'completed',
            transaction_id: transaction_id,
            updated_at: now,
            completed_at: now
          })
          .eq('errand_id', bookingId) // Using errand_id field for all booking types in paytoday_transactions
          .eq('payment_type', paymentType)

        if (txError) throw txError

        // Determine which table to update based on bookingType
        let tableName = 'errands'
        if (bookingType === 'transportation') tableName = 'transportation_bookings'
        else if (bookingType === 'contract') tableName = 'contract_bookings'
        else if (bookingType === 'bus') tableName = 'bus_service_bookings'

        // If it's a full payment, update the booking's escrow status
        if (paymentType === 'full_payment') {
          const { error: bookingError } = await supabaseClient
            .from(tableName)
            .update({
              payment_status: 'in_escrow',
              updated_at: now
            })
            .eq('id', bookingId)

          if (bookingError) throw bookingError
        }

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
