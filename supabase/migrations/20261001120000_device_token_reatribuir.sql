-- Corrige o registro de token de push num aparelho compartilhado (troca de
-- conta no mesmo celular): o upsert direto do app esbarrava na policy
-- "usuario gerencia seu token" — a linha existente pertencia ao usuário
-- anterior, então o `using (usuario_id = auth.uid())` bloqueava o update e
-- o token continuava apontando pra conta antiga (a Edge Function mandava o
-- push pra pessoa errada). A função roda como `security definer` pra
-- reatribuir o token, mas sempre pro próprio `auth.uid()` de quem chamou —
-- não dá pra registrar token em nome de outro usuário.
create or replace function public.registrar_device_token(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'não autenticado' using errcode = '42501';
  end if;

  insert into device_tokens (usuario_id, token)
  values (auth.uid(), p_token)
  on conflict (token) do update
    set usuario_id = excluded.usuario_id,
        criado_em = now();
end;
$$;

revoke all on function public.registrar_device_token(text) from public, anon;
grant execute on function public.registrar_device_token(text) to authenticated;
