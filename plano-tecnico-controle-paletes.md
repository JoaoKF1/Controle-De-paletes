# Plano técnico — Controle de paletes semi-elaborados

## 1. Stack confirmada

- **App**: Flutter (mobile iOS/Android + desktop), build iOS via Codemagic (sem depender de Mac local)
- **Banco/Backend**: Supabase (Postgres + Auth + Realtime + Storage)
- **Offline**: SQLite local via pacote `drift`, sincronizando com Supabase ao reconectar
- **Etiqueta**: geração de PDF (A4, layout próprio com código de barras), impressão via rede/WiFi usando o suporte nativo do SO

---

## 2. Estrutura de pastas Flutter (feature-first)

```
lib/
├── core/
│   ├── config/              # variáveis de ambiente, chaves Supabase
│   ├── router/               # rotas e guards por perfil
│   ├── theme/
│   └── utils/                 # cálculo de quantidade, formatação, etc.
│
├── data/
│   ├── local/                 # drift: tabelas locais + fila de sincronização
│   ├── remote/                # clientes Supabase (queries, realtime channels)
│   └── repositories/          # abstrai local x remoto pra cada entidade
│
├── domain/
│   ├── entities/               # Cliente, Composicao, FichaTecnica, OrdemProducao,
│   │                            # Palete, Refugo, OcorrenciaQualidade, Usuario
│   └── services/               # cálculo de quantidade, geração de etiqueta, sync
│
├── features/
│   ├── auth/                   # login
│   ├── apontamento/            # home "Ordens em aberto" + form de apontamento (Onduladeira)
│   ├── conversao/              # equivalente da Onduladeira, mas para o setor Conversão
│   ├── consulta/                # tela somente leitura do setor oposto
│   ├── qualidade/               # abrir ocorrência + fila de análise + liberar/reprovar
│   ├── refugo/                   # lançamento de refugo
│   ├── cadastros/                # CRUD Cliente/Composição/FT/OP/Usuários (Admin)
│   └── dashboard/                 # gráficos e relatórios (desktop)
│
├── shared/
│   └── widgets/                   # componentes reutilizáveis (cards, badges de status)
│
└── main.dart
```

Cada pasta dentro de `features/` segue o mesmo padrão interno: `view/`, `controller/` (ou `bloc/`, a definir), `widgets/`.

---

## 3. Schema SQL (Supabase / Postgres)

```sql
-- Perfis de usuário (ligado ao auth.users nativo do Supabase)
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  login text not null unique,
  nome text not null,
  perfil text not null check (perfil in ('onduladeira', 'conversao', 'qualidade', 'admin')),
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);

create table clientes (
  id uuid primary key default gen_random_uuid(),
  razao_social text not null,
  cidade text not null,
  uf text not null,
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);

create table composicoes (
  id uuid primary key default gen_random_uuid(),
  codigo text not null unique,
  espessura_mm numeric not null check (espessura_mm > 0),
  created_at timestamptz not null default now()
);

create table fichas_tecnicas (
  id uuid primary key default gen_random_uuid(),
  codigo_ft text not null unique,
  cliente_id uuid not null references clientes(id),
  composicao_id uuid not null references composicoes(id),
  medida_chapa text not null,
  qp_padrao integer not null check (qp_padrao > 0),
  referencia text,
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);

create table ordens_producao (
  id uuid primary key default gen_random_uuid(),
  numero_op text not null unique,
  ficha_tecnica_id uuid not null references fichas_tecnicas(id),
  quantidade_pedida integer not null check (quantidade_pedida > 0),
  data_pedido date not null check (data_pedido <= current_date),
  status text not null default 'aberta' check (status in ('aberta', 'concluida')),
  created_at timestamptz not null default now()
);

create table paletes (
  id uuid primary key default gen_random_uuid(),
  ordem_producao_id uuid not null references ordens_producao(id),
  numero_sequencial integer not null,
  altura_medida_mm numeric not null check (altura_medida_mm > 0),
  quantidade_calculada integer not null,
  tipo_chapa text not null default 'semi_elaborado' check (tipo_chapa in ('semi_elaborado', 'elaborado')),
  setor_origem text not null check (setor_origem in ('onduladeira', 'conversao')),
  codigo_barras text unique,
  responsavel_id uuid not null references profiles(id),
  data_hora timestamptz not null default now(),
  unique (ordem_producao_id, numero_sequencial)
);

create table refugos (
  id uuid primary key default gen_random_uuid(),
  ordem_producao_id uuid not null references ordens_producao(id),
  responsavel_id uuid not null references profiles(id),
  quantidade integer not null check (quantidade > 0),
  motivo text not null,
  data_hora timestamptz not null default now()
);

create table ocorrencias_qualidade (
  id uuid primary key default gen_random_uuid(),
  palete_id uuid not null references paletes(id),
  quantidade_afetada integer not null check (quantidade_afetada > 0),
  motivo text not null,
  status text not null default 'em_analise' check (status in ('em_analise', 'liberado', 'reprovado')),
  aberto_por uuid not null references profiles(id),
  data_abertura timestamptz not null default now()
);

create table historico_ocorrencia (
  id uuid primary key default gen_random_uuid(),
  ocorrencia_id uuid not null references ocorrencias_qualidade(id),
  usuario_id uuid not null references profiles(id),
  status_anterior text not null,
  status_novo text not null,
  data_hora timestamptz not null default now()
);
```

Observações:
- `paletes.numero_sequencial` é único **por OP** (não globalmente), refletido no `unique (ordem_producao_id, numero_sequencial)`.
- `quantidade_calculada` é sempre gravada pelo app a partir da fórmula `(altura_medida_mm ÷ espessura_mm da composição) × qp_padrao da FT` — nunca editável direto pelo usuário.
- `codigo_barras` fica único globalmente, é o valor impresso na etiqueta e usado na consulta/leitura pela Conversão.

---

## 4. Políticas de segurança (RLS)

Regra geral: cada setor só **escreve** nos paletes da própria origem; qualquer perfil autenticado **lê** tudo.

```sql
alter table paletes enable row level security;

create policy "leitura geral" on paletes
  for select using (true);

create policy "onduladeira insere seus paletes" on paletes
  for insert with check (
    setor_origem = 'onduladeira'
    and exists (select 1 from profiles where id = auth.uid() and perfil = 'onduladeira')
  );

create policy "conversao insere seus paletes" on paletes
  for insert with check (
    setor_origem = 'conversao'
    and exists (select 1 from profiles where id = auth.uid() and perfil = 'conversao')
  );
```

O mesmo padrão (leitura geral + escrita restrita ao perfil dono) se repete para `refugos` (Onduladeira/Conversão podem lançar) e `ocorrencias_qualidade` (qualquer setor abre; só `qualidade` atualiza o `status`). Os cadastros base (`clientes`, `composicoes`, `fichas_tecnicas`, `ordens_producao`) ficam restritos a `insert`/`update`/`delete` apenas para `perfil = 'admin'`, com leitura liberada geral.

---

## 5. Fluxo de Git/GitHub

- **`main`**: sempre estável, é o que funciona
- **Uma branch por feature**, saindo de `main`: `feat/nome-da-feature` (ex: `feat/apontamento-palete`)
- **Correções pequenas**: `fix/nome-do-problema`
- **Commits no padrão Conventional Commits**: `feat:`, `fix:`, `chore:`, `docs:` — um commit por peça lógica de trabalho, não só um commit gigante por sprint
- Ao concluir a feature: merge pra `main`, apaga a branch, segue pra próxima
- **Sem PR/revisão intermediária** — o merge é direto, depois de testar a feature manualmente. Como rede de segurança complementar (não como gate), todo push roda CI (GitHub Actions, `.github/workflows/ci.yml`): `flutter analyze` + `flutter test`. Se quebrar, aparece no GitHub mesmo sem travar o merge.

---

## 6. Ordem de desenvolvimento (sprints)

| Sprint | Entrega |
|---|---|
| 0 | Criação do repositório no GitHub, setup do projeto Flutter, projeto Supabase, autenticação, deploy do schema + RLS |
| 1 | Cadastros base (Admin): Cliente, Composição, Ficha Técnica, OP — **entregue**, testado em `feat/cadastros` |
| 2 | Gestão de Usuários (Admin): criar/editar perfis direto pelo app — separado do Sprint 1 porque não bloqueia os próximos sprints (usuário novo pode ser criado manualmente no Supabase Auth, como foi feito pro `kenji`) |
| 3 | Apontamento de palete (Onduladeira): busca de OP, cálculo automático, gravação |
| 4 | Consulta em tempo real (Conversão) + leitura de código de barras |
| 5 | Refugo + Ocorrências de Qualidade (abrir, listar, liberar/reprovar, histórico) |
| 6 | Geração e impressão de etiqueta (PDF + rede WiFi) |
| 7 | Dashboard e relatórios (desktop) |
| 8 | Modo offline (SQLite local + sincronização) |
| 9 | Testes com usuários piloto (Onduladeira + Conversão), ajustes finais |

**Fase 2 (pós-MVP)**: apontamento próprio da Conversão, chapa elaborada com Quebra, OCR de etiqueta, perfil Expedição.

---

## 7. Regras de negócio (consultas)

**Visibilidade de OP para a Conversão**: uma OP aparece na tela inicial ("Ordens disponíveis") da Conversão assim que existir **pelo menos 1 palete** com `setor_origem = 'onduladeira'` vinculado a ela — não é necessário que a Onduladeira tenha concluído a quantidade pedida inteira. Não exige campo novo no schema, é resolvido via query:

```sql
select distinct op.*
from ordens_producao op
join paletes p on p.ordem_producao_id = op.id
where p.setor_origem = 'onduladeira';
```

**Login por usuário, não por email**: o Supabase Auth exige um email por baixo dos panos, mas a pessoa nunca digita nem vê isso — o campo `login` de `profiles` é o "usuário" (curto, sem espaço, ex: `kenji`), e o app monta um email técnico automaticamente no padrão `<login>@controle-paletes.app` só pra autenticar. Ao criar um usuário novo no Supabase Auth, o email cadastrado lá deve seguir esse mesmo padrão.

**RLS obrigatório em `profiles`**: como qualquer usuário logado precisa ler seu próprio perfil, a política mínima é:

```sql
create policy "leitura do proprio perfil" on profiles
  for select using (auth.uid() = id);
```

Sem essa política, o Supabase bloqueia toda leitura da tabela por padrão assim que o RLS é ativado — mesmo para o dono da própria linha.

**RLS de admin em `profiles` (Sprint 2 — gestão de Usuários)**: a tela de Usuários precisa que o admin liste todo mundo e edite nome/perfil/ativo de qualquer um, não só a própria linha:

```sql
create policy "admin le todos perfis" on profiles
  for select using (
    exists (select 1 from profiles where id = auth.uid() and perfil = 'admin')
  );

create policy "admin atualiza perfis" on profiles
  for update using (
    exists (select 1 from profiles where id = auth.uid() and perfil = 'admin')
  ) with check (
    exists (select 1 from profiles where id = auth.uid() and perfil = 'admin')
  );
```

**Criar usuário e trocar senha não passam pelo app direto**: essas duas ações exigem a `service_role` key do Supabase (privilégio de admin do Auth), que nunca pode ser embutida no app Flutter — quem extrair o app teria acesso total ao banco, ignorando todo o RLS. Por isso rodam numa Edge Function (`supabase/functions/admin-usuarios`), que guarda a `service_role` key como segredo do projeto e só executa depois de confirmar, via `profiles`, que quem chamou é admin. Editar nome/perfil e desativar continuam diretos pelo app, cobertos pelas policies acima.

**Admin tem acesso a tudo, inclusive telas operacionais**: o perfil `admin` não fica restrito aos cadastros — ele também acessa as telas de cada setor (Onduladeira, Conversão, Qualidade) a partir da própria home de Cadastros, pra poder testar/apoiar qualquer fluxo. Isso exige que as policies de escrita de cada setor também aceitem admin, não só o dono do setor:

```sql
create policy "admin insere paletes" on paletes
  for insert with check (public.is_admin());
```

O mesmo padrão (uma policy extra de insert com `with check (public.is_admin())`, além da policy do próprio setor) deve ser repetido em `refugos` e `ocorrencias_qualidade` quando esses sprints chegarem.

**RLS dos cadastros base (`clientes`, `composicoes`, `fichas_tecnicas`, `ordens_producao`)**: leitura liberada pra qualquer autenticado, escrita restrita a admin.

```sql
alter table clientes enable row level security;
alter table composicoes enable row level security;
alter table fichas_tecnicas enable row level security;
alter table ordens_producao enable row level security;

create policy "leitura geral clientes" on clientes for select using (true);
create policy "leitura geral composicoes" on composicoes for select using (true);
create policy "leitura geral fichas_tecnicas" on fichas_tecnicas for select using (true);
create policy "leitura geral ordens_producao" on ordens_producao for select using (true);

create policy "admin escreve clientes" on clientes for insert with check (
  exists (select 1 from profiles where id = auth.uid() and perfil = 'admin')
);
create policy "admin escreve composicoes" on composicoes for insert with check (
  exists (select 1 from profiles where id = auth.uid() and perfil = 'admin')
);
create policy "admin escreve fichas_tecnicas" on fichas_tecnicas for insert with check (
  exists (select 1 from profiles where id = auth.uid() and perfil = 'admin')
);
create policy "admin escreve ordens_producao" on ordens_producao for insert with check (
  exists (select 1 from profiles where id = auth.uid() and perfil = 'admin')
);
```
