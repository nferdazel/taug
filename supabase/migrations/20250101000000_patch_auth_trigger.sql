-- Patch trigger handle_new_auth_user() to skip taug users
-- Run this in Supabase SQL Editor

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'auth', 'pg_catalog'
AS $function$
DECLARE
    v_username TEXT;
    v_expected_email TEXT;
    v_company_name TEXT;
    v_ceo_name TEXT;
    v_starting_cash NUMERIC;
BEGIN
    IF (NEW.raw_user_meta_data ->> 'app') = 'taug' THEN
        RETURN NEW;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.auth_user_id = NEW.id
    ) THEN
        RETURN NEW;
    END IF;

    v_username := public.normalize_username(NEW.raw_user_meta_data ->> 'username');
    v_company_name := NULLIF(trim(COALESCE(NEW.raw_user_meta_data ->> 'company_name', '')), '');
    v_ceo_name := NULLIF(trim(COALESCE(NEW.raw_user_meta_data ->> 'ceo_name', '')), '');

    IF v_username IS NULL THEN
        RAISE EXCEPTION 'Auth bootstrap requires raw_user_meta_data.username';
    END IF;

    IF v_company_name IS NULL THEN
        RAISE EXCEPTION 'Auth bootstrap requires raw_user_meta_data.company_name';
    END IF;

    IF v_ceo_name IS NULL THEN
        RAISE EXCEPTION 'Auth bootstrap requires raw_user_meta_data.ceo_name';
    END IF;

    v_expected_email := public.build_synthetic_auth_email(v_username);
    IF lower(COALESCE(NEW.email, '')) <> v_expected_email THEN
        RAISE EXCEPTION 'Auth bootstrap email mismatch for username %', v_username;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.username = v_username
    ) THEN
        RAISE EXCEPTION 'Username % is already registered.', v_username;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.users u
        WHERE u.company_name = v_company_name
    ) THEN
        RAISE EXCEPTION 'Company name % is already registered.', v_company_name;
    END IF;

    SELECT COALESCE(
        (SELECT g.starting_cash::NUMERIC FROM public.global_game_settings g LIMIT 1),
        15000000.00
    )
    INTO v_starting_cash;

    INSERT INTO public.users (
        auth_user_id,
        username,
        password_hash,
        company_name,
        ceo_name,
        cash,
        net_worth,
        last_active_at
    )
    VALUES (
        NEW.id,
        v_username,
        'supabase-auth:' || NEW.id::TEXT,
        v_company_name,
        v_ceo_name,
        v_starting_cash,
        v_starting_cash,
        NOW()
    );

    RETURN NEW;
END;
$function$;
