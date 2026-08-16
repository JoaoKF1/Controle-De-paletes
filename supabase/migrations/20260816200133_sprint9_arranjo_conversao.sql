-- Arranjo de impressão: quantas caixas saem de 1 chapa quando a Conversão
-- imprime/vinca (ex: uma chapa da FT pode ser recortada em 3 caixas menores
-- no arranjo da faca). Sem isso, "chapas disponíveis" assumia sempre 1
-- caixa apontada = 1 chapa consumida, o que fazia o saldo ficar negativo
-- pra qualquer FT com arranjo > 1. Nulo (FTs antigas) é tratado como 1 no
-- app — comportamento igual ao que já existia antes desse campo.
alter table fichas_tecnicas
  add column arranjo integer;

alter table fichas_tecnicas
  add constraint fichas_tecnicas_arranjo_check
    check (arranjo is null or arranjo > 0);
