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
    const { 
      error_message, 
      errand_id, 
      payment_type,
      additional_data 
    } = await req.json()

    // Validate required fields
    if (!error_message || !errand_id || !payment_type) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Log the error to a payment_errors table (create if needed)
    const { error: logError } = await supabase
      .from('payment_errors')
      .insert({
        errand_id,
        payment_type,
        error_message,
        additional_data,
        created_at: new Date().toISOString()
      })

    if (logError) {
      console.error('Failed to log payment error:', logError)
      // Don't throw - we still want to return success to the client
    }

    // Also log to console for immediate debugging
    console.error('PayToday Payment Failure:', {
      errand_id,
      payment_type,
      error_message,
      additional_data,
      timestamp: new Date().toISOString()
    })

    return new Response(
      JSON.stringify({ 
        success: true,
        message: 'Error logged successfully' 
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error in report-failure function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
