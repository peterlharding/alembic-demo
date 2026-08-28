CREATE OR REPLACE FUNCTION public.set_when_modified()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.when_modified := now();
    RETURN NEW;
END;
$$;
