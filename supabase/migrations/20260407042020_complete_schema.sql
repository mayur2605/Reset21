-- ============================================================================
-- Reset21 — Complete Database Schema
-- Migration: 20260407042020_complete_schema.sql
--
-- Drops the old minimal daily_logs table and creates a proper 5-table schema:
--   1. profiles        — User identity + stats (extends auth.users)
--   2. habits          — Master habit definitions per user
--   3. daily_logs      — One row per user per day (session summary)
--   4. habit_entries   — One row per habit per day (granular tracking)
--   5. analytics_events — Persistent event logging
-- ============================================================================

-- ── 0. CLEANUP ──────────────────────────────────────────────────────────────
-- Drop the old table from the initial migration (no production data exists)
DROP TABLE IF EXISTS public.daily_logs CASCADE;


-- ============================================================================
-- 1. PROFILES
-- ============================================================================
-- Extends auth.users with app-specific state. Auto-created via trigger.

CREATE TABLE public.profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name    TEXT,
    current_day     INTEGER NOT NULL DEFAULT 1
                        CHECK (current_day BETWEEN 1 AND 21),
    current_streak  INTEGER NOT NULL DEFAULT 0
                        CHECK (current_streak >= 0),
    total_xp        INTEGER NOT NULL DEFAULT 0
                        CHECK (total_xp >= 0),
    level           TEXT NOT NULL DEFAULT 'Beginner'
                        CHECK (level IN ('Beginner', 'Starter', 'Warrior', 'Elite')),
    day_locked      BOOLEAN NOT NULL DEFAULT FALSE,
    last_completed_date DATE,
    paywall_shown   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.profiles IS 'App-specific user profile extending auth.users';


-- ============================================================================
-- 2. HABITS
-- ============================================================================
-- Master list of habits per user. Seeded with 10 defaults on sign-up.

CREATE TABLE public.habits (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    subtitle    TEXT,
    is_bonus    BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.habits IS 'Master habit definitions per user';


-- ============================================================================
-- 3. DAILY_LOGS
-- ============================================================================
-- One row per user per day — created when user taps LOCK DAY.

CREATE TABLE public.daily_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date            DATE NOT NULL,
    score           DOUBLE PRECISION NOT NULL DEFAULT 0.0
                        CHECK (score BETWEEN 0.0 AND 1.0),
    xp_earned       INTEGER NOT NULL DEFAULT 0
                        CHECK (xp_earned >= 0),
    streak_at_lock  INTEGER NOT NULL DEFAULT 0
                        CHECK (streak_at_lock >= 0),
    is_perfect      BOOLEAN NOT NULL DEFAULT FALSE,
    synced_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, date)
);

COMMENT ON TABLE public.daily_logs IS 'Daily session summary, one per user per day';


-- ============================================================================
-- 4. HABIT_ENTRIES
-- ============================================================================
-- One row per habit per day — granular completion tracking.

CREATE TABLE public.habit_entries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_log_id    UUID NOT NULL REFERENCES public.daily_logs(id) ON DELETE CASCADE,
    habit_id        UUID NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date            DATE NOT NULL,
    is_completed    BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (habit_id, date)
);

COMMENT ON TABLE public.habit_entries IS 'Per-habit per-day completion record';


-- ============================================================================
-- 5. ANALYTICS_EVENTS
-- ============================================================================
-- Persistent event logging (replaces console-only AnalyticsService).

CREATE TABLE public.analytics_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    event_name  TEXT NOT NULL,
    event_data  JSONB DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.analytics_events IS 'Persistent analytics event log';


-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================
-- Every table: users can only read/write their own data.

-- profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- habits
ALTER TABLE public.habits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own habits"
    ON public.habits FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- daily_logs
ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own daily logs"
    ON public.daily_logs FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- habit_entries
ALTER TABLE public.habit_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own habit entries"
    ON public.habit_entries FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- analytics_events
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own analytics events"
    ON public.analytics_events FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ============================================================================
-- INDEXES
-- ============================================================================

-- daily_logs: fast lookup for duplicate-sync guard & date queries
CREATE INDEX idx_daily_logs_user_date
    ON public.daily_logs (user_id, date);

-- habit_entries: daily checklist reconstruction
CREATE INDEX idx_habit_entries_user_date
    ON public.habit_entries (user_id, date);

-- habit_entries: per-habit completion stats
CREATE INDEX idx_habit_entries_habit
    ON public.habit_entries (habit_id);

-- analytics_events: timeline queries
CREATE INDEX idx_analytics_events_user_time
    ON public.analytics_events (user_id, created_at DESC);

-- habits: ordered habit list per user
CREATE INDEX idx_habits_user_order
    ON public.habits (user_id, sort_order);


-- ============================================================================
-- AUTO-PROFILE TRIGGER
-- ============================================================================
-- Automatically creates a profiles row when a new user signs up via auth.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email, 'User')
    );
    RETURN NEW;
END;
$$;

-- Drop if exists to make migration idempotent
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();


-- ============================================================================
-- DEFAULT HABIT SEEDING FUNCTION
-- ============================================================================
-- Called after profile creation to seed the 10 default Reset21 habits.

CREATE OR REPLACE FUNCTION public.seed_default_habits()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.habits (user_id, title, subtitle, is_bonus, sort_order)
    VALUES
        (NEW.id, 'Wake up @ 6am',       '7:00 AM',     FALSE, 1),
        (NEW.id, 'Meditation',           NULL,           FALSE, 2),
        (NEW.id, 'Exercise',             NULL,           FALSE, 3),
        (NEW.id, 'Skin Care Routine',    NULL,           FALSE, 4),
        (NEW.id, 'Complete 10K steps',   '5,635 steps',  FALSE, 5),
        (NEW.id, '3L Water',             '1.5L',         FALSE, 6),
        (NEW.id, 'No Junk & Sugar',      NULL,           TRUE,  7),
        (NEW.id, '1 hr Study',           NULL,           FALSE, 8),
        (NEW.id, 'Read book',            NULL,           FALSE, 9),
        (NEW.id, 'Plan next day',        NULL,           FALSE, 10);
    RETURN NEW;
END;
$$;

-- Trigger: seed habits right after profile is created
DROP TRIGGER IF EXISTS on_profile_created ON public.profiles;
CREATE TRIGGER on_profile_created
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.seed_default_habits();


-- ============================================================================
-- AUTO-UPDATE updated_at TRIGGER FOR PROFILES
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at();
