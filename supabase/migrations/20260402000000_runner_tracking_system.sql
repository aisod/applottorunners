-- Create runner tracking table for live GPS
CREATE TABLE IF NOT EXISTS public.runner_tracking (
    errand_id UUID PRIMARY KEY REFERENCES public.errands(id) ON DELETE CASCADE,
    runner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    heading DOUBLE PRECISION,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create index for faster updates
CREATE INDEX IF NOT EXISTS idx_runner_tracking_runner_id ON public.runner_tracking(runner_id);

-- Enable RLS
ALTER TABLE public.runner_tracking ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if running multiple times
DROP POLICY IF EXISTS "Runners can manage their own tracking data" ON public.runner_tracking;
DROP POLICY IF EXISTS "Customers can view tracking for their errands" ON public.runner_tracking;

-- Allow runners to insert/update their own tracking data
CREATE POLICY "Runners can manage their own tracking data" ON public.runner_tracking
    FOR ALL
    USING (auth.uid() = runner_id)
    WITH CHECK (auth.uid() = runner_id);

-- Customers can view tracking data for their own errands
CREATE POLICY "Customers can view tracking for their errands" ON public.runner_tracking
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.errands
            WHERE errands.id = runner_tracking.errand_id
            AND errands.customer_id = auth.uid()
        )
    );

-- Add to Realtime publication if not already there
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime' AND tablename = 'runner_tracking'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.runner_tracking;
    END IF;
END
$$;
