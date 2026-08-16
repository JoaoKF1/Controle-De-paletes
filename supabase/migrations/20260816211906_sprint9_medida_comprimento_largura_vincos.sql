-- Medida da chapa era um texto livre ("733 x 1.964"), difícil de validar e
-- de usar em cálculo. Vira 2 campos numéricos — comprimento e largura.
-- Backfill assume "comprimento x largura" (a ordem que já era usada nos
-- textos existentes) antes de derrubar a coluna antiga.
alter table fichas_tecnicas
  add column comprimento_mm numeric,
  add column largura_mm numeric;

update fichas_tecnicas
set
  comprimento_mm = nullif(trim(split_part(medida_chapa, 'x', 1)), '')::numeric,
  largura_mm = nullif(trim(split_part(medida_chapa, 'x', 2)), '')::numeric
where medida_chapa is not null;

alter table fichas_tecnicas
  add constraint fichas_tecnicas_comprimento_mm_check
    check (comprimento_mm is null or comprimento_mm > 0),
  add constraint fichas_tecnicas_largura_mm_check
    check (largura_mm is null or largura_mm > 0);

alter table fichas_tecnicas drop column medida_chapa;

-- Vincos: linhas de dobra que viram a chapa plana em caixa — até 5 por FT
-- (uma caixa pode já sair vincada da Onduladeira). Todos opcionais, sem
-- ordem fixa de importância entre eles.
alter table fichas_tecnicas
  add column vinco_1_mm numeric,
  add column vinco_2_mm numeric,
  add column vinco_3_mm numeric,
  add column vinco_4_mm numeric,
  add column vinco_5_mm numeric;

alter table fichas_tecnicas
  add constraint fichas_tecnicas_vinco_1_mm_check check (vinco_1_mm is null or vinco_1_mm > 0),
  add constraint fichas_tecnicas_vinco_2_mm_check check (vinco_2_mm is null or vinco_2_mm > 0),
  add constraint fichas_tecnicas_vinco_3_mm_check check (vinco_3_mm is null or vinco_3_mm > 0),
  add constraint fichas_tecnicas_vinco_4_mm_check check (vinco_4_mm is null or vinco_4_mm > 0),
  add constraint fichas_tecnicas_vinco_5_mm_check check (vinco_5_mm is null or vinco_5_mm > 0);
