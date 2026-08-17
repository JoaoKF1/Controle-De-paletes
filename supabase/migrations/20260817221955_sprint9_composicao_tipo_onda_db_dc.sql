-- Correção: onda dupla não é um tipo genérico "Dupla" — são 2 tipos
-- distintos, DB e DC, no mesmo padrão de nomenclatura de B/C da onda
-- simples (ver exemplo real já cadastrado: "T110T090T090T090T090/DB").
alter table composicoes drop constraint composicoes_tipo_onda_check;

update composicoes set tipo_onda = 'DB' where tipo_onda = 'Dupla';

alter table composicoes
  add constraint composicoes_tipo_onda_check
    check (tipo_onda is null or tipo_onda in ('B', 'C', 'DB', 'DC'));
