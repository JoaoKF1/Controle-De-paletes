-- Composição passa a ser cadastrada papel por papel em vez de um código
-- livre: onda simples (B ou C) tem 3 papéis (capa/miolo/capa), onda dupla
-- tem 5 (capa/miolo/capa/miolo/capa). `codigo` continua existindo — o app
-- passa a gerar ele sozinho a partir do tipo de onda + papéis, em vez do
-- admin digitar (mesmo padrão de "o app calcula, nunca o usuário digita
-- direto" já usado em quantidade_calculada — ver plano técnico, 9.1).
alter table composicoes
  add column tipo_onda text,
  add column papel_1 text,
  add column papel_2 text,
  add column papel_3 text,
  add column papel_4 text,
  add column papel_5 text;

alter table composicoes
  add constraint composicoes_tipo_onda_check
    check (tipo_onda is null or tipo_onda in ('B', 'C', 'Dupla'));

-- Backfill das 2 composições já cadastradas (texto livre da época),
-- pra não ficarem sem os campos estruturados novos.
update composicoes
set tipo_onda = 'C', papel_1 = 'T170', papel_2 = 'T190', papel_3 = 'T170'
where codigo = 'T170T190T170/C';

update composicoes
set
  tipo_onda = 'Dupla',
  papel_1 = 'T110',
  papel_2 = 'T090',
  papel_3 = 'T090',
  papel_4 = 'T090',
  papel_5 = 'T090'
where codigo = 'T110T090T090T090T090/DB';
