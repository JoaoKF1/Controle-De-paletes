-- Quem revisou/segregou um palete fica registrado direto nele (mais simples
-- de exibir do que navegar o histórico da ocorrência toda vez).
alter table paletes
  add column revisado_por uuid references profiles(id);

-- Conversão não mede altura em mm: o operador informa direto quantas
-- camadas de pacote o palete tem. altura_medida_mm continua sendo o que a
-- Onduladeira usa, então vira opcional; camadas é o equivalente da
-- Conversão (ver plano técnico, 9.1).
alter table paletes
  alter column altura_medida_mm drop not null;

alter table paletes
  add column camadas integer check (camadas > 0);

-- altura_pacote_mm não é mais necessário — o cálculo agora é
-- camadas × pacotes_por_camada × pecas_por_pacote, direto.
alter table fichas_tecnicas
  drop column altura_pacote_mm;

-- Faltava policy de update nos cadastros base — só tinha insert. Sem isso
-- não dá pra corrigir/completar uma Ficha Técnica já cadastrada.
create policy "admin atualiza clientes" on clientes
  for update using (public.is_admin()) with check (public.is_admin());
create policy "admin atualiza composicoes" on composicoes
  for update using (public.is_admin()) with check (public.is_admin());
create policy "admin atualiza fichas_tecnicas" on fichas_tecnicas
  for update using (public.is_admin()) with check (public.is_admin());
create policy "admin atualiza ordens_producao" on ordens_producao
  for update using (public.is_admin()) with check (public.is_admin());
