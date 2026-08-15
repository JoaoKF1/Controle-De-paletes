# Plano técnico — Controle de paletes semi-elaborados

## 1. Contexto do negócio

O sistema controla a produção de embalagens de papelão ondulado. Papelão ondulado é formado por duas capas lisas de papel coladas ao redor de uma camada ondulada no meio (o miolo) — essa estrutura é o que dá resistência ao material. Esse conjunto colado e cortado no tamanho do pedido é a **chapa**.

A produção de uma chapa passa por até duas etapas, em setores diferentes:

1. **Onduladeira**: forma as camadas (capa + onda + capa) na composição definida pelo pedido (ex: `T140M130T140/B`) e corta nas medidas do pedido. Resultado: a **chapa semi-elaborada** — papelão pronto no tamanho certo, mas sem impressão e sem vinco.
2. **Impressão/Conversão**: recebe a chapa semi-elaborada e aplica a impressão (arte/logo do cliente) e o vinco (linhas marcadas que definem onde a chapa dobra pra formar a caixa). Resultado: a **chapa elaborada** — pronta pra ser dobrada e virar caixa.

Depois vai pra Expedição, que carrega pro cliente (fora do escopo do sistema por enquanto — ver seção 10).

Nem todo pedido passa pelas duas etapas: alguns terminam na chapa semi-elaborada mesmo — o cliente compra só a chapa cortada, sem impressão nem vinco (ex: "PEDIDO DE CHAPA", quando o cliente faz a conversão por conta própria ou usa a chapa lisa). Qual caminho a OP segue é identificado pelo **prefixo do número da OP**:

- **802** — a chapa vai virar elaborada: a OP passa pela Onduladeira e depois pela Conversão.
- **803** — fica só chapa: a OP passa só pela Onduladeira, o produto final já é a chapa semi-elaborada.

Isso importa pro app porque **o `tipo_chapa` de um apontamento reflete o setor que apontou, não o prefixo da OP**: todo apontamento feito pela Onduladeira é sempre `semi_elaborado` (é o que ela produz, esteja a OP destinada a virar elaborada depois ou não); todo apontamento feito pela Conversão é sempre `elaborado`. O prefixo 802/803 serve pra outra coisa — decidir se aquela OP **precisa** passar pela Conversão, o que afeta quando ela aparece na fila de trabalho da Conversão (Sprint 4) e quando ela é considerada `concluída`.

> ⚠️ **Pendência conhecida**: o código do Sprint 3 (`OrdemProducaoInfo.tipoChapa`, em `lib/domain/entities/palete.dart`) hoje deriva `tipo_chapa` do prefixo da OP (803→elaborado, 802→semi-elaborado) para o apontamento da Onduladeira. Isso está errado nos dois sentidos: o mapeamento ficou invertido, e mais fundamental — o apontamento da Onduladeira deveria sempre gravar `semi_elaborado`, direto, sem depender do prefixo nenhum. A corrigir.

---

## 2. Perfis e responsabilidades

| Perfil | O que faz no sistema |
|---|---|
| `admin` | Cadastros base (Cliente, Composição, Ficha Técnica, OP), gestão de Usuários, e acesso a todas as telas operacionais dos outros perfis — pra poder testar/apoiar qualquer fluxo |
| `onduladeira` | Aponta paletes de chapa semi-elaborada nas OPs em aberto |
| `conversao` | Aponta paletes de chapa elaborada, a partir do que a Onduladeira já produziu (Sprint 4/5 — ainda não implementado) |
| `qualidade` | Abre e decide ocorrências de qualidade sobre paletes já apontados; segrega material (Sprint 5 — ainda não implementado) |

(Fase 2, fora do escopo atual: perfil `expedicao` — ver seção 10.)

---

## 3. Stack confirmada

- **App**: Flutter (mobile iOS/Android + desktop), build iOS via Codemagic (sem depender de Mac local)
- **Banco/Backend**: Supabase (Postgres + Auth + Realtime + Storage)
- **Offline**: SQLite local via pacote `drift`, sincronizando com Supabase ao reconectar
- **Etiqueta**: geração de PDF (A4, layout próprio com código de barras), impressão via rede/WiFi usando o suporte nativo do SO

---

## 4. Estrutura de pastas Flutter (feature-first)

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

## 5. Schema SQL (Supabase / Postgres)

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
- `quantidade_calculada` é sempre gravada pelo app a partir da fórmula `(altura_medida_mm ÷ espessura_mm da composição) × qp_padrao da FT` — nunca editável direto pelo usuário. Ver seção 9 para o detalhe de cada termo.
- `codigo_barras` fica único globalmente, é o valor impresso na etiqueta e usado na consulta/leitura pela Conversão e pela Qualidade.

### 5.1 Pendências de schema conhecidas (ainda não implementadas)

Coisas que já sabemos que vão exigir `alter table` quando os sprints correspondentes chegarem — registrado aqui pra não esquecer, mas **nada disso está no banco ainda**:

- **`fichas_tecnicas` — campos de qualidade do produto**: `gramatura`, `coluna`, `cobb_interno`, `cobb_externo`, `mullen`, `compressao`, `resina_interna`, `resina_externa`. São específicos de cada Ficha Técnica (não da Composição), e a tela de cadastro do Sprint 1 já foi entregue sem eles — falta adicionar tanto o schema quanto os campos no formulário.
- **`refugos.motivo` — hoje é texto livre**, mas a regra de negócio pede uma lista fechada: `Quebra na produção`, `Erro de medida`, `Amassado/rasgado`, `Outro`. Falta o `check constraint` (ou uma tabela de domínio) e o formulário virar um seletor em vez de texto livre.
- **`ocorrencias_qualidade` / segregação de palete** — o schema atual não modela: (a) o **saldo disponível** do palete (quantidade original menos o que já foi debitado por reprovação), (b) o **flag "segregado"** que precisa persistir no histórico mesmo depois do saldo zerar, nem (c) a distinção entre as ações possíveis por perfil (ver seção 9.4). Isso será desenhado no Sprint 5, mas provavelmente exige uma coluna de saldo em `paletes` (ex: `quantidade_reprovada`, com `saldo_disponivel` calculado) e talvez um campo de "ação" em `ocorrencias_qualidade`.

---

## 6. Políticas de segurança (RLS)

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

## 7. Fluxo de Git/GitHub

- **`main`**: sempre estável, é o que funciona
- **Uma branch por feature**, saindo de `main`: `feat/nome-da-feature` (ex: `feat/apontamento-palete`)
- **Correções pequenas**: `fix/nome-do-problema`
- **Commits no padrão Conventional Commits**: `feat:`, `fix:`, `chore:`, `docs:` — um commit por peça lógica de trabalho, não só um commit gigante por sprint
- Ao concluir a feature: merge pra `main`, apaga a branch, segue pra próxima
- **Sem PR/revisão intermediária** — o merge é direto, depois de testar a feature manualmente. Como rede de segurança complementar (não como gate), todo push roda CI (GitHub Actions, `.github/workflows/ci.yml`): `flutter analyze` + `flutter test`. Se quebrar, aparece no GitHub mesmo sem travar o merge.

---

## 8. Ordem de desenvolvimento (sprints)

| Sprint | Entrega |
|---|---|
| 0 | Criação do repositório no GitHub, setup do projeto Flutter, projeto Supabase, autenticação, deploy do schema + RLS |
| 1 | Cadastros base (Admin): Cliente, Composição, Ficha Técnica, OP — **entregue**, testado em `feat/cadastros`. Falta os campos de qualidade da FT (ver 5.1) |
| 2 | Gestão de Usuários (Admin): criar/editar/trocar senha/desativar direto pelo app — **entregue**, testado em `feat/usuarios` |
| 3 | Apontamento de palete (Onduladeira): tela operacional, cálculo automático, gravação — **entregue**, testado em `feat/apontamento-palete`. Tem a pendência do `tipo_chapa` (ver seção 1) |
| 4 | Consulta em tempo real (Conversão) + leitura de código de barras — só OPs com prefixo **802** (as que precisam de Conversão) entram na fila de trabalho dela |
| 5 | Refugo (motivo pré-definido) + Ocorrências de Qualidade (segregação parcial/total, saldo do palete, ações por perfil, histórico) |
| 6 | Geração e impressão de etiqueta (PDF + rede WiFi) |
| 7 | Dashboard e relatórios (desktop) |
| 8 | Modo offline (SQLite local + sincronização) |
| 9 | Testes com usuários piloto (Onduladeira + Conversão), ajustes finais |

---

## 9. Regras de negócio

### 9.1 Cálculo de quantidade do palete

```
quantidade_calculada = floor( (altura_medida_mm ÷ espessura_mm da composição) × qp_padrao da FT )
```

- **`altura_medida_mm`**: altura da pilha de chapas empilhadas, medida pelo operador na hora do apontamento.
- **`espessura_mm`** (da Composição/tipo de onda): espessura de uma chapa individual — `altura ÷ espessura` dá quantas chapas cabem numa pilha daquela altura.
- **`qp_padrao`** (da Ficha Técnica): número de **pilhas por palete** daquele produto — um palete físico é montado com várias pilhas lado a lado, então multiplicar pelo `qp_padrao` dá o total de chapas do palete inteiro.
- Arredondado **pra baixo** (`floor`): só conta chapa inteira, a pilha não fecha uma chapa parcial.
- `tipo_chapa` do apontamento é sempre `semi_elaborado` quando quem aponta é a Onduladeira, e sempre `elaborado` quando é a Conversão — não depende de seleção manual nem do prefixo da OP (ver seção 1).

### 9.2 Visibilidade de OP para a Conversão

Uma OP só entra na fila de trabalho da Conversão se (a) tiver **prefixo 802** (única que passa por Conversão — ver seção 1) e (b) já existir **pelo menos 1 palete** com `setor_origem = 'onduladeira'` vinculado a ela — não é necessário que a Onduladeira tenha concluído a quantidade pedida inteira:

```sql
select distinct op.*
from ordens_producao op
join paletes p on p.ordem_producao_id = op.id
where p.setor_origem = 'onduladeira'
  and op.numero_op like '802%';
```

### 9.3 Refugo

Chapa perdida ou descartada durante o processo (Onduladeira ou Conversão). Regras:

- Lançamento **independente** de um apontamento de palete — vinculado obrigatoriamente à **OP**, não a um palete específico.
- Motivo vem de uma lista pré-definida: `Quebra na produção`, `Erro de medida`, `Amassado/rasgado`, `Outro` (ver pendência de schema em 5.1).
- Registrado por **qualquer operador do setor onde ocorreu** (Onduladeira ou Conversão), não só quem apontou o palete relacionado.
- Reprovações de qualidade também **somam automaticamente** ao refugo da OP (ver 9.4) — o refugo de uma OP não é só o que foi lançado manualmente, é a soma dos lançamentos manuais + o que a Qualidade reprovou.

### 9.4 Ocorrência de qualidade e segregação

- **Quem abre**: qualquer setor pode abrir uma ocorrência (parcial ou total) sobre um palete **já apontado**. Nasce com status `em_analise`.
- **Quem decide**: só o perfil `qualidade` decide o status final (`liberado` ou `reprovado`) — nenhum outro perfil resolve uma ocorrência aberta.
- **Ao reprovar**: a quantidade reprovada é debitada do **saldo disponível** do palete (não apaga o registro do palete) e é somada automaticamente ao **refugo da OP**.
- **Badge "segregado"**: o palete recebe uma marca visual de segregado e continua aparecendo na lista/consulta mesmo depois de 100% da quantidade ter sido debitada — nunca desaparece, fica no histórico.

### 9.5 Ações por leitura de código de barras (por perfil)

Ao ler o código de barras de um palete, as ações disponíveis mudam conforme quem está lendo:

- **Qualidade**:
  - *Pedir revisão* — abre uma ocorrência normal, `em_analise`, pra alguém da Qualidade decidir depois.
  - *Segregar inteiro* — reprova na hora, sem passar por análise: debita o saldo inteiro do palete e soma ao refugo da OP direto.
- **Apontador de produção (Onduladeira/Conversão)**:
  - *Corrigir quantidade* — ajusta um erro do próprio apontamento (ex: digitou a altura errada).
  - *Excluir totalmente* — descarta o que ele mesmo produziu; vai direto pro refugo da OP, sem passar pela Qualidade.

### 9.6 Campos de qualidade da Ficha Técnica

Cada Ficha Técnica tem especificações técnicas próprias do produto (não da Composição/tipo de onda, que é compartilhada entre várias FTs): `Gramatura`, `Coluna`, `Cobb Interno`, `Cobb Externo`, `Mullen`, `Compressão`, `Resina Interna`, `Resina Externa`. Ainda não implementados — ver pendência em 5.1.

### 9.7 Login por usuário, não por email

O Supabase Auth exige um email por baixo dos panos, mas a pessoa nunca digita nem vê isso — o campo `login` de `profiles` é o "usuário" (curto, sem espaço, ex: `kenji`), e o app monta um email técnico automaticamente no padrão `<login>@controle-paletes.app` só pra autenticar. Ao criar um usuário novo no Supabase Auth, o email cadastrado lá deve seguir esse mesmo padrão.

### 9.8 RLS obrigatório em `profiles`

Como qualquer usuário logado precisa ler seu próprio perfil, a política mínima é:

```sql
create policy "leitura do proprio perfil" on profiles
  for select using (auth.uid() = id);
```

Sem essa política, o Supabase bloqueia toda leitura da tabela por padrão assim que o RLS é ativado — mesmo para o dono da própria linha.

**RLS de admin em `profiles` (Sprint 2 — gestão de Usuários)**: a tela de Usuários precisa que o admin liste todo mundo e edite nome/perfil/ativo de qualquer um, não só a própria linha. Usa uma função `security definer` (`is_admin()`) em vez de subconsulta direta porque uma policy em `profiles` que consulta a própria `profiles` pode entrar em recursão:

```sql
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from profiles where id = auth.uid() and perfil = 'admin'
  );
$$;

create policy "admin le todos perfis" on profiles
  for select using (public.is_admin());

create policy "admin atualiza perfis" on profiles
  for update using (public.is_admin()) with check (public.is_admin());
```

**Criar usuário e trocar senha não passam pelo app direto**: essas duas ações exigem a `service_role` key do Supabase (privilégio de admin do Auth), que nunca pode ser embutida no app Flutter — quem extrair o app teria acesso total ao banco, ignorando todo o RLS. Por isso rodam numa Edge Function (`supabase/functions/admin-usuarios`), que guarda a `service_role` key como segredo do projeto e só executa depois de confirmar, via `profiles`, que quem chamou é admin. Editar nome/perfil e desativar continuam diretos pelo app, cobertos pelas policies acima.

### 9.9 Admin tem acesso a tudo, inclusive telas operacionais

O perfil `admin` não fica restrito aos cadastros — ele também acessa as telas de cada setor (Onduladeira, Conversão, Qualidade) a partir da própria home de Cadastros, pra poder testar/apoiar qualquer fluxo. Isso exige que as policies de escrita de cada setor também aceitem admin, não só o dono do setor:

```sql
create policy "admin insere paletes" on paletes
  for insert with check (public.is_admin());
```

O mesmo padrão (uma policy extra de insert com `with check (public.is_admin())`, além da policy do próprio setor) deve ser repetido em `refugos` e `ocorrencias_qualidade` quando esses sprints chegarem.

### 9.10 RLS dos cadastros base

`clientes`, `composicoes`, `fichas_tecnicas`, `ordens_producao`: leitura liberada pra qualquer autenticado, escrita restrita a admin.

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

---

## 10. Fora de escopo por agora (Fase 2)

- **Dados de Conversão no cadastro da FT**: cores de tinta, clichê, arranjo, peças por amarrado.
- **Dados de Paletização no cadastro da FT**: peças por palete padrão, medidas do palete.
- **Perfil `expedicao`**: consulta de OPs 802 em produção, carregamento pro cliente.
- Chapa elaborada com fluxo de Quebra mais refinado.
- OCR de etiqueta.
