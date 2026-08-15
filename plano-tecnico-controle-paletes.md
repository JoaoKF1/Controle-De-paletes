# Plano técnico — Controle de paletes semi-elaborados

## 1. Contexto do negócio

O sistema controla a produção de embalagens de papelão ondulado. Papelão ondulado é formado por duas capas lisas de papel coladas ao redor de uma camada ondulada no meio (o miolo) — essa estrutura é o que dá resistência ao material. Esse conjunto colado e cortado no tamanho do pedido é a **chapa**.

A produção de uma chapa passa por até duas etapas, em setores diferentes:

1. **Onduladeira**: forma as camadas (capa + onda + capa) na composição definida pelo pedido (ex: `T140M130T140/B`) e corta nas medidas do pedido. Resultado: a **chapa semi-elaborada** — papelão pronto no tamanho certo, mas sem impressão e sem vinco.
2. **Impressão/Conversão**: recebe a chapa semi-elaborada e aplica a impressão (arte/logo do cliente) e o vinco (linhas marcadas que definem onde a chapa dobra pra formar a caixa). Resultado: a **chapa elaborada** — pronta pra ser dobrada e virar caixa.

Depois vai pra Expedição, que carrega pro cliente (fora do escopo do sistema por enquanto — ver seção 10).

Nem todo pedido passa pelas duas etapas: alguns terminam direto na saída da Onduladeira — o cliente compra só a chapa cortada, sem impressão nem vinco (ex: "PEDIDO DE CHAPA", quando o cliente faz a conversão por conta própria ou usa a chapa lisa). Qual caminho a OP segue é identificado pelo **prefixo do número da OP**:

- **803** — fica só chapa: a OP passa só pela Onduladeira, e esse já é o produto final daquela OP — vai direto pra Expedição, sem Conversão.
- **802** — a chapa ainda precisa da Conversão: sai da Onduladeira intermediária e só fica pronta depois de passar por lá (impressão + vinco).

Isso importa pro app porque **o `tipo_chapa` de um apontamento da Onduladeira depende do prefixo da OP**, não é sempre o mesmo valor: numa OP 803 ela grava `elaborado` (é o produto final dessa OP, mesmo sem ter passado por impressão/vinco — ver 9.1); numa OP 802 ela grava `semi_elaborado` (ainda vai virar outra coisa na Conversão). Já o apontamento da Conversão é sempre `elaborado` — ela só processa OP 802, e o que sai de lá é sempre o resultado final. O prefixo 802/803 também decide se a OP **precisa** passar pela fila de trabalho da Conversão (Sprint 4) — só 802 entra lá.

---

## 2. Perfis e responsabilidades

| Perfil | O que faz no sistema |
|---|---|
| `admin` | Cadastros base (Cliente, Composição, Ficha Técnica, OP), gestão de Usuários, e acesso a todas as telas operacionais dos outros perfis — pra poder testar/apoiar qualquer fluxo |
| `onduladeira` | Aponta paletes de chapa semi-elaborada nas OPs em aberto |
| `conversao` | Aponta paletes de chapa elaborada, a partir do que a Onduladeira já produziu — **entregue** |
| `qualidade` | Abre e decide ocorrências de qualidade sobre paletes já apontados; segrega material — **entregue** |

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

## 5. Schema (Supabase / Postgres)

O schema real do banco vive em `supabase/migrations/` — esse é o histórico versionado e a fonte de verdade, mantido sincronizado com `supabase db pull` e alterado com `supabase db push` (ver seção 7). Esta seção descreve as tabelas em prosa, pra entender o modelo de dados sem precisar abrir os arquivos de migration.

- **`profiles`**: um perfil por usuário autenticado, ligado ao `auth.users` nativo do Supabase. Guarda `login` (o "usuário" curto que a pessoa digita), `nome`, `perfil` (`onduladeira`/`conversao`/`qualidade`/`admin`) e `ativo`.
- **`clientes`**: cadastro simples — razão social, cidade, UF, ativo.
- **`composicoes`**: os "tipos de onda" (ex: `T140M130T140/B`), cada um com sua `espessura_mm`.
- **`fichas_tecnicas`**: o produto em si — código, cliente, composição, medida da chapa, `qp_padrao` (número de pilhas por palete), as 8 colunas de qualidade opcionais (ver 9.6) e os 2 campos de paletização da Conversão (ver 5.3).
- **`ordens_producao`**: a OP — número (cujo prefixo 802/803 define o roteamento, ver seção 1), ficha técnica, quantidade pedida, data do pedido e `status` (`aberta`/`concluida`).
- **`paletes`**: cada apontamento — OP, número sequencial (único por OP), `altura_medida_mm` (Onduladeira) ou `camadas` (Conversão) — um dos dois, nunca os dois —, quantidade calculada, `tipo_chapa`, `setor_origem` (`onduladeira`/`conversao`), código de barras (único globalmente, é o valor impresso na etiqueta), responsável, data/hora, e `revisado_por` (quem debitou saldo por último — ver 9.4).
- **`refugos`**: chapa perdida/descartada, vinculada à OP (não a um palete específico) — ver 9.3.
- **`ocorrencias_qualidade`** e **`historico_ocorrencia`**: ocorrências abertas sobre um palete e o histórico de mudança de status — ver 9.4.

Observações:
- `paletes.numero_sequencial` é único **por OP** (não globalmente).
- `quantidade_calculada` é sempre gravada pelo app a partir da fórmula em 9.1 — nunca editável direto pelo usuário.

### 5.1 Campos de qualidade da Ficha Técnica

Colunas adicionadas depois do Sprint 1, pra cobrir as especificações técnicas do produto (ver 9.6): `gramatura`, `coluna`, `cobb_interno`, `cobb_externo`, `mullen`, `compressao`, `resina_interna`, `resina_externa`. Todas opcionais (nullable) — nem toda FT precisa preencher tudo de cara.

### 5.2 Refugo e segregação (Sprint 5)

- **`refugos.motivo`** virou lista fechada via `check constraint`: `Quebra na produção`, `Erro de medida`, `Amassado/rasgado`, `Outro`.
- **`paletes`** ganhou `quantidade_reprovada` (o que já foi debitado por reprovação/segregação/exclusão) e `saldo_disponivel` (coluna gerada, `quantidade_calculada − quantidade_reprovada`). Não existe coluna "segregado": é só `quantidade_reprovada > 0`, o que naturalmente persiste mesmo com saldo zerado (ver 9.4).
- **`ocorrencias_qualidade`** ganhou `quantidade_reprovada` (nullable, só preenchida ao resolver) — separada de `quantidade_afetada` (o que foi flagrado originalmente), pra suportar liberação parcial (ver 9.4).

### 5.3 Paletização da Conversão

`fichas_tecnicas` ganhou `pacotes_por_camada` e `pecas_por_pacote` — opcionais no banco, mas **obrigatórios pra apontar como Conversão** (ver 9.1). FTs antigas continuam funcionando pra Onduladeira normalmente; só precisam desses 2 campos se a OP for 802. (Chegou a existir um terceiro campo, `altura_pacote_mm`, pra medir a pilha em mm igual a Onduladeira faz — foi removido: o operador da Conversão informa direto quantas **camadas** de pacote o palete tem, sem medir altura.)

### 5.4 Edição dos cadastros base

Sprint 1 só tinha `insert` pros cadastros base (Cliente, Composição, Ficha Técnica, OP) — não dava pra corrigir nada depois de criado. A Ficha Técnica agora tem edição pelo app (tela de lista, toca num item, abre o mesmo formulário preenchido, salva com `update`), o que exigiu adicionar a policy de `update` que faltava (ver 9.10). Clientes, Composições e OP ainda só têm tela de criação — mesma pendência, ainda não resolvida pra essas três.

---

## 6. Políticas de segurança (RLS)

Regra geral: cada setor só **escreve** nos paletes da própria origem; qualquer perfil autenticado **lê** tudo. `paletes` tem RLS habilitado com uma policy de leitura geral e uma policy de insert por setor, cada uma conferindo que `setor_origem` bate com o `perfil` de quem está inserindo (consultando `profiles`). O mesmo padrão (leitura geral + escrita restrita ao perfil dono) se repete para `refugos` (Onduladeira/Conversão podem lançar) e `ocorrencias_qualidade` (qualquer setor abre; só `qualidade` atualiza o `status`). Os cadastros base (`clientes`, `composicoes`, `fichas_tecnicas`, `ordens_producao`) ficam com `insert`/`update` restritos a `perfil = 'admin'` (sem `delete` ainda — ver 9.10), com leitura liberada geral. O SQL de cada policy vive versionado em `supabase/migrations/`.

---

## 7. Fluxo de Git/GitHub

- **`main`**: sempre estável, é o que funciona
- **Uma branch por feature**, saindo de `main`: `feat/nome-da-feature` (ex: `feat/apontamento-palete`)
- **Correções pequenas**: `fix/nome-do-problema`
- **Commits no padrão Conventional Commits**: `feat:`, `fix:`, `chore:`, `docs:` — um commit por peça lógica de trabalho, não só um commit gigante por sprint
- Ao concluir a feature: merge pra `main`, apaga a branch, segue pra próxima
- **Sem PR/revisão intermediária** — o merge é direto, depois de testar a feature manualmente. Como rede de segurança complementar (não como gate), todo push roda CI (GitHub Actions, `.github/workflows/ci.yml`): `flutter analyze` + `flutter test`. Se quebrar, aparece no GitHub mesmo sem travar o merge.
- **Mudança de schema é migration, não SQL colado no dashboard**: arquivo novo em `supabase/migrations/`, aplicado com `supabase db push` (projeto já linkado via `supabase link`). `supabase db pull` mantém essa pasta sincronizada com o banco real. O schema real do banco é sempre o que está lá — este documento explica o *porquê* de cada coisa, não é uma lista de comandos pra rodar.

---

## 8. Ordem de desenvolvimento (sprints)

| Sprint | Entrega |
|---|---|
| 0 | Criação do repositório no GitHub, setup do projeto Flutter, projeto Supabase, autenticação, deploy do schema + RLS |
| 1 | Cadastros base (Admin): Cliente, Composição, Ficha Técnica (com campos de qualidade), OP — **entregue** |
| 2 | Gestão de Usuários (Admin): criar/editar/trocar senha/desativar direto pelo app — **entregue**, testado em `feat/usuarios` |
| 3 | Apontamento de palete (Onduladeira): tela operacional, cálculo automático, gravação — **entregue**, testado em `feat/apontamento-palete` |
| 4 | Consulta em tempo real (Conversão) + apontamento próprio (chapa elaborada) — **entregue**, testado em `feat/consulta-conversao`. Só OPs com prefixo **802** entram na fila de trabalho da Conversão. Fórmula própria por pacote/camada, com campos novos na FT (ver 5.3, 9.1) |
| 5 | Refugo (motivo pré-definido) + Ocorrências de Qualidade (segregação parcial/total, saldo do palete, ações por perfil, histórico) — implementado em `feat/refugo-qualidade`, aguardando teste. Leitura de código de barras de verdade fica pro Sprint 6 (ver 9.5) |
| 6 | Geração e impressão de etiqueta (PDF + rede WiFi) |
| 7 | Dashboard e relatórios (desktop) |
| 8 | Modo offline (SQLite local + sincronização) |
| 9 | Testes com usuários piloto (Onduladeira + Conversão), ajustes finais |

---

## 9. Regras de negócio

### 9.1 Cálculo de quantidade do palete

A Onduladeira conta **chapas**, medindo a altura da pilha em mm. A Conversão conta **caixas** já paletizadas, mas não mede altura nenhuma — o produto dela vem embalado em pacotes (ex: pacote de 30 caixas), com vários pacotes lado a lado por camada, e o operador só informa **quantas camadas** o palete tem:

```
Onduladeira: floor( (altura_medida_mm ÷ espessura_mm da composição) × qp_padrao da FT )
Conversão:   camadas × pacotes_por_camada da FT × pecas_por_pacote da FT
```

- **`altura_medida_mm`** (só Onduladeira): altura da pilha de chapas, medida pelo operador na hora do apontamento.
- **`espessura_mm`** (da Composição/tipo de onda): espessura de uma chapa individual — `altura ÷ espessura` dá quantas chapas cabem numa pilha daquela altura.
- **`qp_padrao`** (da Ficha Técnica): número de **pilhas por palete** daquele produto — um palete físico é montado com várias pilhas lado a lado, então multiplicar pelo `qp_padrao` dá o total de chapas do palete inteiro.
- **`camadas`** (só Conversão): quantas camadas de pacote o palete tem — contado direto pelo operador, não calculado a partir de medida nenhuma.
- **`pacotes_por_camada`** (da Ficha Técnica): quantos pacotes ficam lado a lado em cada camada.
- **`pecas_por_pacote`** (da Ficha Técnica): quantas caixas tem em 1 pacote (ex: 30). `camadas × pacotes_por_camada × pecas_por_pacote` dá o total de caixas do palete — como os três são inteiros, não precisa arredondar.
- A fórmula da Onduladeira arredonda **pra baixo** (`floor`): só conta chapa inteira.
- `tipo_chapa` nunca é seleção manual. Pra Conversão é sempre `elaborado`. Pra Onduladeira depende do prefixo da OP: `elaborado` se a OP começa com 803 (produto final), `semi_elaborado` se começa com 802 (ainda intermediário) — ver seção 1.
- O apontamento da Conversão só funciona se a Ficha Técnica tiver os 2 campos de paletização preenchidos (ver 5.3) — sem eles o app recusa com uma mensagem, em vez de calcular errado.

Na tela de detalhe da OP (Conversão), aparece um resumo com o total produzido pela Onduladeira e o total já apontado pela Conversão — informativo, não é um débito automático de estoque (as unidades são diferentes: chapas de um lado, caixas de outro). O apontamento da Conversão continua sendo feito palete a palete, quando aquele palete estiver completo.

### 9.2 Visibilidade de OP para a Conversão

Uma OP só entra na fila de trabalho da Conversão se (a) tiver **prefixo 802** (única que passa por Conversão — ver seção 1) e (b) já existir **pelo menos 1 palete** com `setor_origem = 'onduladeira'` vinculado a ela — não é necessário que a Onduladeira tenha concluído a quantidade pedida inteira. Na prática é uma consulta que junta `ordens_producao` com `paletes` filtrando por `setor_origem = 'onduladeira'` e pelo prefixo do `numero_op`.

### 9.3 Refugo

Chapa perdida ou descartada durante o processo (Onduladeira ou Conversão). Regras:

- Lançamento **independente** de um apontamento de palete — vinculado obrigatoriamente à **OP**, não a um palete específico.
- Motivo vem de uma lista pré-definida: `Quebra na produção`, `Erro de medida`, `Amassado/rasgado`, `Outro` (ver 5.2).
- Registrado por **qualquer operador do setor onde ocorreu** (Onduladeira ou Conversão), não só quem apontou o palete relacionado.
- Reprovações de qualidade também **somam automaticamente** ao refugo da OP (ver 9.4) — o refugo de uma OP não é só o que foi lançado manualmente, é a soma dos lançamentos manuais + o que a Qualidade reprovou.

### 9.4 Ocorrência de qualidade e segregação

- **Quem abre**: qualquer setor pode abrir uma ocorrência (parcial ou total) sobre um palete **já apontado**. Nasce com status `em_analise`, com uma `quantidade_afetada` (o que foi flagrado pra revisão).
- **Quem decide**: só o perfil `qualidade` decide o resultado — nenhum outro perfil resolve uma ocorrência aberta. A decisão não é só um binário liberar/reprovar: a Qualidade informa **quanto** da `quantidade_afetada` é reprovado (`quantidade_reprovada` na ocorrência, de 0 até o total afetado) — 0 libera tudo, o total afetado reprova tudo, qualquer valor no meio é uma **liberação parcial** (o resto volta pro saldo disponível normalmente). `status` fecha em `liberado` se nada foi reprovado, `reprovado` se algo foi (parcial ou total).
- **Ao reprovar (total ou parcial)**: a quantidade reprovada é debitada do **saldo disponível** do palete (não apaga o registro do palete) e é somada automaticamente ao **refugo da OP**.
- **Rótulo de segregação**: o palete recebe uma marca visual e continua aparecendo na lista/consulta mesmo depois de 100% da quantidade ter sido debitada — nunca desaparece, fica no histórico. O texto muda conforme sobrou saldo ou não: **"SEGREGADO PARCIALMENTE"** se ainda tem saldo disponível depois do débito, **"SEGREGADO"** se o saldo zerou.
- **Quem revisou**: toda resolução (inclusive "Segregar inteiro", que pula a análise, e "Excluir totalmente", feito pelo próprio setor) grava quem debitou o saldo em `paletes.revisado_por` — aparece direto na lista de paletes ("revisado por Fulano") sem precisar navegar histórico nenhum. `historico_ocorrencia` continua guardando o rastro completo de mudanças de status pra auditoria mais detalhada.

### 9.5 Ações por leitura de código de barras (por perfil)

Ao ler o código de barras de um palete, as ações disponíveis mudam conforme quem está lendo:

- **Qualidade**:
  - *Pedir revisão* — abre uma ocorrência normal, `em_analise`, pra alguém da Qualidade decidir depois.
  - *Segregar inteiro* — reprova na hora, sem passar por análise: debita o saldo inteiro do palete e soma ao refugo da OP direto.
- **Apontador de produção (Onduladeira/Conversão)**:
  - *Corrigir quantidade* — ajusta um erro do próprio apontamento (ex: digitou a altura errada).
  - *Excluir totalmente* — descarta o que ele mesmo produziu; vai direto pro refugo da OP, sem passar pela Qualidade.

`codigo_barras` só existe de verdade a partir do Sprint 6 (etiqueta impressa), então por enquanto essas ações ficam atrás de **tocar no palete na lista** (nas telas de detalhe de OP), não de uma leitura de câmera de verdade. "Pedir revisão" fica disponível pra qualquer perfil autenticado que tocar num palete (não só Qualidade), porque a regra de negócio em 9.4 diz que qualquer setor pode abrir ocorrência — as outras três ações (segregar/corrigir/excluir) ficam restritas a quem tem o perfil certo pro palete em questão. Quando o Sprint 6 trouxer leitura de câmera de verdade, ela deve preencher o mesmo fluxo, só trocando "tocar na lista" por "escanear".

### 9.6 Campos de qualidade da Ficha Técnica

Cada Ficha Técnica tem especificações técnicas próprias do produto (não da Composição/tipo de onda, que é compartilhada entre várias FTs): `Gramatura`, `Coluna`, `Cobb Interno`, `Cobb Externo`, `Mullen`, `Compressão`, `Resina Interna`, `Resina Externa`. Todos opcionais no cadastro — ver 5.1.

### 9.7 Login por usuário, não por email

O Supabase Auth exige um email por baixo dos panos, mas a pessoa nunca digita nem vê isso — o campo `login` de `profiles` é o "usuário" (curto, sem espaço, ex: `kenji`), e o app monta um email técnico automaticamente no padrão `<login>@controle-paletes.app` só pra autenticar. Ao criar um usuário novo no Supabase Auth, o email cadastrado lá deve seguir esse mesmo padrão.

### 9.8 RLS em `profiles`

Como qualquer usuário logado precisa ler seu próprio perfil, existe uma policy mínima liberando `select` quando `auth.uid()` bate com o `id` da linha — sem ela, o Supabase bloqueia toda leitura da tabela por padrão assim que o RLS é ativado, mesmo para o dono da própria linha.

**RLS de admin em `profiles` (Sprint 2 — gestão de Usuários)**: a tela de Usuários precisa que o admin liste todo mundo e edite nome/perfil/ativo de qualquer um, não só a própria linha. Isso usa uma função `security definer` (`public.is_admin()`) em vez de subconsulta direta na própria policy — uma policy em `profiles` que consulta a própria `profiles` dentro da subconsulta pode entrar em recursão; a função `security definer` resolve isso porque roda a consulta interna ignorando o RLS.

**Criar usuário e trocar senha não passam pelo app direto**: essas duas ações exigem a `service_role` key do Supabase (privilégio de admin do Auth), que nunca pode ser embutida no app Flutter — quem extrair o app teria acesso total ao banco, ignorando todo o RLS. Por isso rodam numa Edge Function (`supabase/functions/admin-usuarios`), que guarda a `service_role` key como segredo do projeto e só executa depois de confirmar, via `profiles`, que quem chamou é admin. Editar nome/perfil e desativar continuam diretos pelo app, cobertos pelas policies acima.

### 9.9 Admin tem acesso a tudo, inclusive telas operacionais

O perfil `admin` não fica restrito aos cadastros — ele também acessa as telas de cada setor (Onduladeira, Conversão, Qualidade) a partir da própria home de Cadastros, pra poder testar/apoiar qualquer fluxo. Isso exige que as policies de escrita de cada setor também aceitem admin (via `is_admin()`), não só o dono do setor — vale pra `paletes`, `refugos` e `ocorrencias_qualidade`.

### 9.10 RLS dos cadastros base

`clientes`, `composicoes`, `fichas_tecnicas`, `ordens_producao`: leitura liberada pra qualquer autenticado, `insert` e `update` restritos a quem tem `perfil = 'admin'` (via `is_admin()`). Não existe `delete` em nenhuma das quatro ainda — cadastro errado hoje só dá pra corrigir editando (FT já tem tela pra isso, ver 5.4), não apagando.

### 9.11 RLS de refugo, ocorrência e correção de palete (Sprint 5)

- **`paletes` ganhou policy de `update`** (antes só tinha `select`/`insert`): o setor dono do palete (comparando `perfil` com `setor_origem`) pode corrigir seu próprio apontamento; a Qualidade (ou admin) pode debitar `quantidade_reprovada` ao reprovar/segregar.
- **`refugos`**: leitura geral; insere quem tem perfil `onduladeira`, `conversao` ou `qualidade` (ou admin) — cobre tanto lançamento manual quanto os débitos automáticos vindos de reprovação/exclusão.
- **`ocorrencias_qualidade`**: leitura geral; **insert** liberado pra qualquer autenticado (é a regra "qualquer setor abre ocorrência" de 9.4); **update** do `status` só pra `qualidade` (ou admin) — ninguém mais resolve uma ocorrência.
- **`historico_ocorrencia`**: leitura geral; insert só quando a Qualidade (ou admin) resolve uma ocorrência.

---

## 10. Fora de escopo por agora (Fase 2)

- **Dados de Conversão no cadastro da FT**: cores de tinta, clichê, arranjo, peças por amarrado. (Paletização — altura/pacotes/camada — já saiu daqui e foi implementada, ver 5.3.)
- **Perfil `expedicao`**: consulta de OPs 802 em produção, carregamento pro cliente.
- Chapa elaborada com fluxo de Quebra mais refinado.
- OCR de etiqueta.
