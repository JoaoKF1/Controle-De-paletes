-- Sprint 9 parte 2: token de push (Firebase Cloud Messaging) por
-- dispositivo logado — usado pela Edge Function que notifica a Onduladeira
-- quando um teste de qualidade é registrado (ver plano técnico, 9.6/12).
-- Um usuário pode ter mais de 1 aparelho logado, por isso é tabela própria
-- em vez de coluna em `profiles`. `token` é único porque o mesmo token
-- físico deve apontar sempre pro usuário logado mais recente naquele
-- aparelho (reinstalar/trocar de conta reatribui, não duplica).
create table device_tokens (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references profiles(id),
  token text not null unique,
  criado_em timestamptz not null default now()
);

alter table device_tokens enable row level security;

-- Ninguém lê a tabela pelo app — só a Edge Function, com a service_role key
-- (que ignora RLS). O client só precisa gravar/atualizar o próprio token.
create policy "usuario gerencia seu token" on device_tokens
  for all
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());
