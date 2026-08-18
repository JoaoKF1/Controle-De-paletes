-- Sprint 9: teste de qualidade da OP — a Qualidade registra os valores
-- medidos e o app compara com os alvos/faixas já cadastrados na FT (ver
-- plano técnico, 9.1/9.6). Um teste é por OP (não por palete específico),
-- com os 8 campos todos opcionais — nem toda chapa tem, por exemplo, Cobb
-- ou Resina testado, então não faz sentido obrigar o preenchimento de tudo.
create table testes_qualidade (
  id uuid primary key default gen_random_uuid(),
  ordem_producao_id uuid not null references ordens_producao(id),
  gramatura_medida numeric,
  coluna_medida numeric,
  cobb_interno_medido numeric,
  cobb_externo_medido numeric,
  mullen_medido numeric,
  compressao_medida numeric,
  resina_interna_medida numeric,
  resina_externa_medida numeric,
  registrado_por uuid not null references profiles(id),
  criado_em timestamptz not null default now()
);

alter table testes_qualidade enable row level security;

create policy "leitura geral testes_qualidade" on testes_qualidade
  for select using (true);

-- Só quem tem perfil qualidade (ou admin, que acessa tudo — ver 9.9)
-- registra teste, mesmo padrão de "quem decide" já usado em ocorrência de
-- qualidade (ver 9.4/9.11).
create policy "qualidade registra teste" on testes_qualidade
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and perfil = 'qualidade')
    or public.is_admin()
  );
