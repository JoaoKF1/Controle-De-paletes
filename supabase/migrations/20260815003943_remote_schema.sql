-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

SET check_function_bodies = false;

DROP POLICY "admin atualiza perfis" ON public.profiles;

DROP POLICY "admin le todos perfis" ON public.profiles;

CREATE FUNCTION public.is_admin()
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public'
  AS $function$
  select exists (
    select 1 from profiles where id = auth.uid() and perfil = 'admin'
  );
$function$;

GRANT ALL ON FUNCTION public.is_admin() TO anon;

GRANT ALL ON FUNCTION public.is_admin() TO authenticated;

GRANT ALL ON FUNCTION public.is_admin() TO service_role;

ALTER TABLE public.fichas_tecnicas
  ADD COLUMN gramatura numeric;

ALTER TABLE public.fichas_tecnicas
  ADD COLUMN coluna numeric;

ALTER TABLE public.fichas_tecnicas
  ADD COLUMN cobb_interno numeric;

ALTER TABLE public.fichas_tecnicas
  ADD COLUMN cobb_externo numeric;

ALTER TABLE public.fichas_tecnicas
  ADD COLUMN mullen numeric;

ALTER TABLE public.fichas_tecnicas
  ADD COLUMN compressao numeric;

ALTER TABLE public.fichas_tecnicas
  ADD COLUMN resina_interna text;

ALTER TABLE public.fichas_tecnicas
  ADD COLUMN resina_externa text;

CREATE POLICY "admin insere paletes" ON public.paletes
  FOR INSERT
  WITH CHECK (public.is_admin());

CREATE POLICY "admin atualiza perfis" ON public.profiles
  FOR UPDATE
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "admin le todos perfis" ON public.profiles
  FOR SELECT
  USING (public.is_admin());
