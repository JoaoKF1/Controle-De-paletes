-- Sprint 5: Refugo + Ocorrencias de Qualidade / segregacao.
-- Ver plano tecnico, secoes 5.2, 9.3, 9.4, 9.5.

-- Saldo disponivel do palete: quantidade_reprovada acumula o que a
-- Qualidade debitou (reprovacao/segregacao) ou o proprio setor descartou
-- (exclusao total). saldo_disponivel eh sempre quantidade_calculada menos
-- isso. "segregado" nao vira coluna: eh so quantidade_reprovada > 0.
alter table paletes
  add column quantidade_reprovada integer not null default 0
    check (quantidade_reprovada >= 0),
  add column saldo_disponivel integer
    generated always as (quantidade_calculada - quantidade_reprovada) stored;

alter table paletes
  add constraint paletes_quantidade_reprovada_le_calculada
    check (quantidade_reprovada <= quantidade_calculada);

-- Setor de origem corrige ou zera (exclui) o proprio palete; Qualidade
-- tambem escreve em paletes pra debitar saldo ao reprovar/segregar.
create policy "setor corrige seu palete" on paletes
  for update using (
    exists (select 1 from profiles where id = auth.uid() and perfil = setor_origem)
    or public.is_admin()
  ) with check (
    exists (select 1 from profiles where id = auth.uid() and perfil = setor_origem)
    or public.is_admin()
  );

create policy "qualidade debita saldo do palete" on paletes
  for update using (
    exists (select 1 from profiles where id = auth.uid() and perfil = 'qualidade')
    or public.is_admin()
  ) with check (
    exists (select 1 from profiles where id = auth.uid() and perfil = 'qualidade')
    or public.is_admin()
  );

-- Refugo: motivo vira lista fechada (ver 9.3).
alter table refugos
  add constraint refugos_motivo_check check (
    motivo in ('Quebra na produção', 'Erro de medida', 'Amassado/rasgado', 'Outro')
  );

create policy "leitura geral refugos" on refugos
  for select using (true);

create policy "setor lanca refugo" on refugos
  for insert with check (
    exists (
      select 1 from profiles
      where id = auth.uid() and perfil in ('onduladeira', 'conversao', 'qualidade')
    )
    or public.is_admin()
  );

-- Ocorrencia de qualidade: qualquer setor autenticado abre; so qualidade
-- (ou admin) resolve o status.
create policy "leitura geral ocorrencias" on ocorrencias_qualidade
  for select using (true);

create policy "qualquer setor abre ocorrencia" on ocorrencias_qualidade
  for insert with check (auth.uid() is not null);

create policy "qualidade resolve ocorrencia" on ocorrencias_qualidade
  for update using (
    exists (select 1 from profiles where id = auth.uid() and perfil = 'qualidade')
    or public.is_admin()
  ) with check (
    exists (select 1 from profiles where id = auth.uid() and perfil = 'qualidade')
    or public.is_admin()
  );

-- Historico de ocorrencia: leitura geral, insert so quando qualidade
-- resolve (ou admin agindo por ela).
create policy "leitura geral historico ocorrencia" on historico_ocorrencia
  for select using (true);

create policy "qualidade registra historico" on historico_ocorrencia
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and perfil = 'qualidade')
    or public.is_admin()
  );
