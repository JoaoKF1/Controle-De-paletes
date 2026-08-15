-- Qualidade precisa poder liberar só parte de uma ocorrência (o resto
-- reprovado), não só um dos dois extremos.
alter table ocorrencias_qualidade
  add column quantidade_reprovada integer;

alter table ocorrencias_qualidade
  add constraint ocorrencias_qualidade_quantidade_reprovada_check
    check (
      quantidade_reprovada is null
      or (quantidade_reprovada >= 0 and quantidade_reprovada <= quantidade_afetada)
    );
