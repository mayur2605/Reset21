-- Create daily_logs table for SyncQueue synchronization
CREATE TABLE IF NOT EXISTS public.daily_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    date TEXT NOT NULL, -- "YYYY-MM-DD"
    habits JSONB NOT NULL,
    score DOUBLE PRECISION NOT NULL,
    xp INTEGER NOT NULL,
    streak INTEGER NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (user_id, date)
);

-- Enable RLS (Row Level Security)
ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to insert/select their own logs
CREATE POLICY "Users can manage their own logs" ON public.daily_logs
    FOR ALL
    USING (auth.uid()::text = user_id)
    WITH CHECK (auth.uid()::text = user_id);
