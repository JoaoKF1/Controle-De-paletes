-- Dados de paletização da Conversão: caixas são empacotadas (ex: 30 caixas
-- por pacote), pacotes ficam lado a lado por camada (ex: 2), e o palete
-- empilha várias camadas. O apontamento da Conversão mede a altura da
-- pilha igual a Onduladeira faz, só que dividindo pela altura de 1 pacote
-- em vez da espessura de 1 chapa.
alter table fichas_tecnicas
  add column altura_pacote_mm numeric,
  add column pacotes_por_camada integer,
  add column pecas_por_pacote integer;

alter table fichas_tecnicas
  add constraint fichas_tecnicas_altura_pacote_mm_check
    check (altura_pacote_mm is null or altura_pacote_mm > 0),
  add constraint fichas_tecnicas_pacotes_por_camada_check
    check (pacotes_por_camada is null or pacotes_por_camada > 0),
  add constraint fichas_tecnicas_pecas_por_pacote_check
    check (pecas_por_pacote is null or pecas_por_pacote > 0);
