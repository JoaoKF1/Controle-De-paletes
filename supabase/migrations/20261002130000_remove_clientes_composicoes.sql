-- Fim da transição iniciada em 20261002120000: o modelo novo (cliente e
-- composição direto na Ficha Técnica) foi validado, e os dados de teste
-- foram zerados pra começar os testes do zero — não há mais o que
-- preservar nas tabelas antigas. O app não lê nem grava nelas desde a
-- migration anterior.
alter table fichas_tecnicas
  drop column cliente_id,
  drop column composicao_id;

drop table clientes;
drop table composicoes;
