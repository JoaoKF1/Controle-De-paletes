-- Sprint 9 parte 2: turno do usuário — usado pra decidir quem recebe
-- notificação push de teste de qualidade (só operador da Onduladeira, no
-- turno que está rolando agora — ver plano técnico, 9.6/12). Obrigatório
-- pra todo usuário, não só Onduladeira, porque é um dado de cadastro
-- simples e uniforme; contas existentes foram migradas pra 'comercial' já
-- que nenhuma tinha esse dado antes (admin ajusta depois quem for turno
-- de fábrica de verdade).
alter table profiles
  add column turno text not null default 'comercial'
    check (turno in ('primeiro', 'segundo', 'comercial'));
