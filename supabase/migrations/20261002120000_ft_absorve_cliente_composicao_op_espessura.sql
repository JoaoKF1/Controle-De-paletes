-- Simplificação dos cadastros (o ERP da empresa já é a fonte de cliente e
-- composição — este sistema só complementa apontamento e Qualidade):
--
-- 1. `clientes` e `composicoes` deixam de ser cadastro próprio. A Ficha
--    Técnica passa a guardar direto o nome do cliente, o tipo de onda, os
--    papéis e a espessura esperada da chapa. (As tabelas antigas ficam,
--    sem uso, até a validação — ver o fim da seção 1.)
-- 2. A OP ganha `espessura_medida_mm`: a Onduladeira mede a espessura real
--    da chapa ao cadastrar a OP, e é ela (não mais a espessura da
--    composição) que entra no cálculo de quantidade do palete. Não muda
--    depois do primeiro palete apontado — cada OP nova mede de novo, mesmo
--    sendo da mesma FT.
-- 3. Onduladeira passa a criar OP (antes só admin) e a poder encerrá-la —
--    o "Encerrar produção" da Onduladeira já existia no app, mas o RLS de
--    update era só admin, então o update afetava 0 linhas em silêncio.
--
-- Os dados existentes são de teste, mas são copiados mesmo assim (backfill)
-- pros campos novos.

-- ---------------------------------------------------------------------------
-- 1. Ficha Técnica absorve cliente e composição
-- ---------------------------------------------------------------------------

alter table fichas_tecnicas
  add column cliente_nome text,
  add column tipo_onda text,
  add column papel_1 text,
  add column papel_2 text,
  add column papel_3 text,
  add column papel_4 text,
  add column papel_5 text,
  -- 2 casas decimais: é a precisão que a fábrica mede. numeric (não float)
  -- pra o cálculo de quantidade nunca sofrer erro de ponto flutuante.
  add column espessura_esperada_mm numeric(6, 2);

update fichas_tecnicas ft
set
  cliente_nome = c.razao_social,
  -- composições antigas sem tipo_onda estruturado: tira do código ("…/B")
  tipo_onda = coalesce(co.tipo_onda, nullif(split_part(co.codigo, '/', 2), '')),
  papel_1 = co.papel_1,
  papel_2 = co.papel_2,
  papel_3 = co.papel_3,
  papel_4 = co.papel_4,
  papel_5 = co.papel_5,
  espessura_esperada_mm = round(co.espessura_mm, 2)
from clientes c, composicoes co
where c.id = ft.cliente_id
  and co.id = ft.composicao_id;

alter table fichas_tecnicas
  alter column cliente_nome set not null,
  alter column tipo_onda set not null,
  alter column papel_1 set not null,
  alter column papel_2 set not null,
  alter column papel_3 set not null,
  alter column espessura_esperada_mm set not null;

alter table fichas_tecnicas
  add constraint fichas_tecnicas_cliente_nome_check
    check (btrim(cliente_nome) <> ''),
  add constraint fichas_tecnicas_tipo_onda_check
    check (tipo_onda in ('B', 'C', 'DB', 'DC')),
  -- Onda simples (B/C) = 3 papéis; onda dupla (DB/DC) = 5. Garante no banco
  -- que nunca sobra nem falta papel pro tipo de onda escolhido.
  add constraint fichas_tecnicas_papeis_por_onda_check
    check (
      (tipo_onda in ('B', 'C') and papel_4 is null and papel_5 is null)
      or (tipo_onda in ('DB', 'DC') and papel_4 is not null and papel_5 is not null)
    ),
  add constraint fichas_tecnicas_espessura_esperada_mm_check
    check (espessura_esperada_mm > 0);

-- Transição reversível: `clientes`/`composicoes` e os vínculos antigos da
-- FT ficam no banco como cópia de segurança enquanto o novo modelo é
-- validado — o app não lê nem grava mais neles. Só deixam de ser
-- obrigatórios (FT nova não preenche). Apagar de vez é uma migration
-- separada, depois da validação.
alter table fichas_tecnicas
  alter column cliente_id drop not null,
  alter column composicao_id drop not null;

-- ---------------------------------------------------------------------------
-- 2. Espessura medida na OP
-- ---------------------------------------------------------------------------

alter table ordens_producao
  add column espessura_medida_mm numeric(6, 2);

-- OPs de teste já existentes: assume a espessura esperada da FT.
update ordens_producao op
set espessura_medida_mm = ft.espessura_esperada_mm
from fichas_tecnicas ft
where ft.id = op.ficha_tecnica_id;

alter table ordens_producao
  alter column espessura_medida_mm set not null,
  add constraint ordens_producao_espessura_medida_mm_check
    check (espessura_medida_mm > 0);

-- Depois do primeiro palete apontado, a espessura da OP fica travada:
-- mudar ali recalcularia (ou deixaria inconsistente) a quantidade de
-- paletes que já foram apontados com a espessura antiga.
create or replace function public.travar_espessura_op()
returns trigger
language plpgsql
as $$
begin
  if new.espessura_medida_mm is distinct from old.espessura_medida_mm
     and exists (select 1 from paletes where ordem_producao_id = old.id) then
    raise exception
      'A espessura da OP não pode ser alterada depois do primeiro palete apontado.'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger ordens_producao_travar_espessura
  before update on ordens_producao
  for each row execute function public.travar_espessura_op();

-- ---------------------------------------------------------------------------
-- 3. RLS de OP: admin e Onduladeira criam e atualizam (encerrar)
-- ---------------------------------------------------------------------------

-- Mesmo motivo do is_admin(): security definer evita recursão de RLS ao
-- consultar `profiles` de dentro de uma policy.
create or replace function public.perfil_atual()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select perfil from profiles where id = auth.uid() and ativo
$$;

revoke all on function public.perfil_atual() from public, anon;
grant execute on function public.perfil_atual() to authenticated;

drop policy "admin escreve ordens_producao" on ordens_producao;
drop policy "admin atualiza ordens_producao" on ordens_producao;

create policy "admin e onduladeira criam ordens_producao" on ordens_producao
  for insert
  with check (public.perfil_atual() in ('admin', 'onduladeira'));

create policy "admin e onduladeira atualizam ordens_producao" on ordens_producao
  for update
  using (public.perfil_atual() in ('admin', 'onduladeira'))
  with check (public.perfil_atual() in ('admin', 'onduladeira'));
