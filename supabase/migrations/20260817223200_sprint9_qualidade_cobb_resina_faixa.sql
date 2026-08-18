-- Sprint 9: Cobb e Resina passam a ser cadastrados como faixa (mín/máx) na
-- FT, porque na fábrica os dois sempre trabalham em faixa, nunca em valor
-- único (ex.: Cobb interno 15 a 22) — Resina segue a mesma lógica (ver
-- plano técnico, 9.6). Resina também vira numérico (era texto livre).
-- Confirmado antes de derrubar as colunas antigas: nenhuma FT já cadastrada
-- tinha valor preenchido em nenhum desses 4 campos, então não há backfill.
alter table fichas_tecnicas
  drop column cobb_interno,
  drop column cobb_externo,
  drop column resina_interna,
  drop column resina_externa;

alter table fichas_tecnicas
  add column cobb_interno_min numeric,
  add column cobb_interno_max numeric,
  add column cobb_externo_min numeric,
  add column cobb_externo_max numeric,
  add column resina_interna_min numeric,
  add column resina_interna_max numeric,
  add column resina_externa_min numeric,
  add column resina_externa_max numeric;

alter table fichas_tecnicas
  add constraint fichas_tecnicas_cobb_interno_faixa_check
    check (cobb_interno_min is null or cobb_interno_max is null or cobb_interno_min <= cobb_interno_max),
  add constraint fichas_tecnicas_cobb_externo_faixa_check
    check (cobb_externo_min is null or cobb_externo_max is null or cobb_externo_min <= cobb_externo_max),
  add constraint fichas_tecnicas_resina_interna_faixa_check
    check (resina_interna_min is null or resina_interna_max is null or resina_interna_min <= resina_interna_max),
  add constraint fichas_tecnicas_resina_externa_faixa_check
    check (resina_externa_min is null or resina_externa_max is null or resina_externa_min <= resina_externa_max);
