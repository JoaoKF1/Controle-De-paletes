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

- **App**: Flutter (`lib/`). Hoje builda e roda de verdade em **Windows desktop** (dev/teste do dia a dia) e **Android** (APK gerado e testado — ver seção 12). iOS ainda não foi construído; segue o plano original de build via Codemagic, sem depender de Mac local.
- **Gerenciamento de estado**: Riverpod (`flutter_riverpod`) — `Provider`, `FutureProvider` (com `.family` quando o dado depende de um parâmetro, ex. paletes de uma OP) e `StreamProvider` (dados que atualizam sozinhos, ex. fila de pendências offline).
- **Backend**: Supabase (Postgres + Auth + Realtime), client `supabase_flutter`. Schema sempre versionado em `supabase/migrations/`, aplicado via Supabase CLI (`supabase db push`) — nunca SQL colado direto no dashboard (ver seção 7).
- **Modo offline**: SQLite local via `drift` (+ `sqlite3_flutter_libs`, `path_provider`, `path`) — cache de leitura + fila de escrita (outbox), ver 9.12/9.13.
- **Configuração/segredos**: `flutter_dotenv`, lendo um `.env` (URL + chave pública do Supabase) empacotado como asset — a `service_role` key nunca entra no app, só na Edge Function (ver 9.8).
- **Gráficos (Dashboard)**: `fl_chart`, com paleta e padrões de acessibilidade validados via skill de dataviz (ver Sprint 7).
- **Conectividade**: `connectivity_plus` — usado só pra saber **quando** tentar sincronizar de novo, nunca pra decidir se uma ação individual é offline (isso é sempre pelo resultado real da chamada de rede, ver 9.12).
- **IDs offline**: `uuid` — gera IDs client-side pra registros criados sem conexão; o número sequencial "de verdade" continua sendo sempre definido pelo servidor no momento da sincronização.
- **Leitura de código de barras**: `mobile_scanner` — dependência já instalada, mas sem tela usando a câmera de verdade ainda (Sprint 6, adiado; as ações que dependeriam disso hoje funcionam por toque na lista, ver 9.5).
- **Etiqueta** (Sprint 6, adiado): `pdf` + `printing` já instalados pra quando o layout for aprovado pela gerência — geração de PDF A4 com código de barras, impressão via rede/WiFi.
- **Datas/horas**: `intl` pra formatação. Todo timestamp que vem do Supabase (gravado em UTC) passa por `.toLocal()` ao entrar no app, em todas as entidades — sem isso, qualquer usuário fora do UTC (Brasil é UTC-3) vê a hora adiantada. Foi um bug real encontrado testando no celular (nesse passe de design pré-piloto): o Dashboard já convertia certo, mas as entidades (`Palete`, `OrdemProducao`, `Refugo`, `OcorrenciaQualidade`) não — corrigido em todas.
- **CI**: GitHub Actions (`.github/workflows/ci.yml`) — `flutter analyze` + `flutter test` em todo push, rede de segurança complementar (não é gate — ver seção 7).

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
- **`composicoes`**: os "tipos de onda" (ex: `T140M130T140/B`), cada um com sua `espessura_mm`. `codigo` é gerado pelo app a partir de `tipo_onda` (`B`/`C` = onda simples, `DB`/`DC` = onda dupla) e dos papéis escolhidos (`papel_1`..`papel_5` — só 3 preenchidos na onda simples, os 5 na dupla), não é mais digitado livre — ver 5.1.
- **`fichas_tecnicas`**: o produto em si — código, cliente, composição, `comprimento_mm`/`largura_mm` (medida da chapa, ver 5.1), `qp_padrao` (número de pilhas por palete), as 8 colunas de qualidade opcionais (ver 9.6), até 5 vincos opcionais (ver 5.1) e os campos de paletização/arranjo da Conversão (ver 5.3).
- **`ordens_producao`**: a OP — número (cujo prefixo 802/803 define o roteamento, ver seção 1), ficha técnica, quantidade pedida, data do pedido e `status` (`aberta`/`concluida`).
- **`paletes`**: cada apontamento — OP, número sequencial (único por OP), `altura_medida_mm` (Onduladeira) ou `camadas` (Conversão) — um dos dois, nunca os dois —, quantidade calculada, `tipo_chapa`, `setor_origem` (`onduladeira`/`conversao`), código de barras (único globalmente, é o valor impresso na etiqueta), responsável, data/hora, e `revisado_por` (quem debitou saldo por último — ver 9.4).
- **`refugos`**: chapa perdida/descartada, vinculada à OP (não a um palete específico) — ver 9.3.
- **`ocorrencias_qualidade`** e **`historico_ocorrencia`**: ocorrências abertas sobre um palete e o histórico de mudança de status — ver 9.4.
- **`testes_qualidade`**: teste de qualidade de uma OP (Sprint 9, ver 9.6) — os 8 campos medidos, todos opcionais, mais quem registrou e quando.

Observações:
- `paletes.numero_sequencial` é único **por OP** (não globalmente).
- `quantidade_calculada` é sempre gravada pelo app a partir da fórmula em 9.1 — nunca editável direto pelo usuário.

### 5.1 Campos de qualidade da Ficha Técnica

Colunas adicionadas depois do Sprint 1, pra cobrir as especificações técnicas do produto (ver 9.6): `gramatura`, `coluna`, `cobb_interno_min/max`, `cobb_externo_min/max`, `mullen`, `compressao`, `resina_interna_min/max`, `resina_externa_min/max`. Todas opcionais (nullable) — nem toda FT precisa preencher tudo de cara.

**Cobb e Resina são cadastrados como faixa (mín/máx), não valor único** — na fábrica os dois sempre trabalham em faixa (ex: Cobb interno 15 a 22), nunca num valor fixo. Resina também virou numérico (era texto livre até o Sprint 9). Gramatura, Coluna, Mullen e Compressão continuam valor único (ver 9.6, comparação por tolerância).

**Medida da chapa** era um único campo de texto livre (`medida_chapa`, ex: `"733 x 1.964"`) — virou 2 colunas numéricas, `comprimento_mm` e `largura_mm`, ambas obrigatórias. A migração que fez a troca (nesse passe de design pré-piloto) leu o texto existente pra preencher as duas colunas novas antes de derrubar a antiga, então nenhuma FT já cadastrada perdeu dado.

**Vincos**: `vinco_1_mm` até `vinco_5_mm`, todas opcionais e sem ordem fixa entre si — uma caixa pode já sair vincada (linhas de dobra marcadas) direto da Onduladeira, então a FT guarda até 5 medidas de vinco conforme o desenho da caixa precisar.

### 5.2 Refugo e segregação (Sprint 5)

- **`refugos.motivo`** virou lista fechada via `check constraint`: `Quebra na produção`, `Erro de medida`, `Amassado/rasgado`, `Outro`.
- **`paletes`** ganhou `quantidade_reprovada` (o que já foi debitado por reprovação/segregação/exclusão) e `saldo_disponivel` (coluna gerada, `quantidade_calculada − quantidade_reprovada`). Não existe coluna "segregado": é só `quantidade_reprovada > 0`, o que naturalmente persiste mesmo com saldo zerado (ver 9.4).
- **`ocorrencias_qualidade`** ganhou `quantidade_reprovada` (nullable, só preenchida ao resolver) — separada de `quantidade_afetada` (o que foi flagrado originalmente), pra suportar liberação parcial (ver 9.4).

### 5.3 Paletização da Conversão

`fichas_tecnicas` ganhou `pacotes_por_camada` e `pecas_por_pacote` — opcionais no banco, mas **obrigatórios pra apontar como Conversão** (ver 9.1). FTs antigas continuam funcionando pra Onduladeira normalmente; só precisam desses 2 campos se a OP for 802. (Chegou a existir um terceiro campo, `altura_pacote_mm`, pra medir a pilha em mm igual a Onduladeira faz — foi removido: o operador da Conversão informa direto quantas **camadas** de pacote o palete tem, sem medir altura.)

`fichas_tecnicas` também ganhou `arranjo`: quantas **caixas** saem de 1 **chapa** no arranjo de impressão/vinco (ex: uma chapa da FT vira 3 caixas menores). Opcional — nulo é tratado como 1 (uma chapa = uma caixa, o comportamento original antes desse campo existir). Sem isso, "chapas disponíveis" no detalhe da OP de Conversão sempre debitava 1 chapa inteira por caixa apontada, o que deixava o saldo negativo pra qualquer FT com arranjo maior que 1 mesmo sobrando material de verdade (ver 9.1).

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
| 5 | Refugo (motivo pré-definido) + Ocorrências de Qualidade (segregação parcial/total, saldo do palete, ações por perfil, histórico) — **entregue**, testado em `feat/refugo-qualidade`. Leitura de código de barras de verdade fica pro Sprint 6 (ver 9.5) |
| 6 | Geração e impressão de etiqueta (PDF + rede WiFi) — **adiado**: layout da etiqueta depende de aprovação da gerência. Não bloqueia nenhum sprint seguinte (as ações que dependeriam de ler código de barras já funcionam por toque na lista — ver 9.5) |
| 7 | Dashboard e relatórios (desktop) — **entregue**. Acessível pelo Admin em Cadastros. KPIs (OPs abertas/concluídas, ocorrências em análise) + produção por dia/setor (linha) + refugo por motivo (barra), com `fl_chart` |
| 8 | Modo offline (SQLite local + sincronização) — **entregue**. Fase 1: cache de OPs/paletes + apontamento offline pra Onduladeira e Conversão (ver 9.12). Fase 2: refugo, pedir revisão de qualidade e cadastros do Admin, com fila genérica (ver 9.13) — o que depende de saldo atual do palete (segregar/resolver/corrigir/excluir) continua exigindo conexão de propósito |
| 9 | Testes de qualidade nas chapas: tela pra Qualidade registrar os resultados **medidos** de uma OP, comparando com os valores-alvo/faixa já cadastrados na Ficha Técnica, com selo de aprovado/reprovado por campo (ver 9.6). **Parte 1 implementada** (cadastro de faixa mín/máx pra Cobb/Resina na FT, tela de registro/histórico de teste, avaliação automática) — validando com o usuário. **Parte 2 pendente**: notificação push (Onduladeira/Gestão/Qualidade) ao registrar um teste, respeitando o turno de cada usuário |
| 10 | Testes com usuários piloto (Onduladeira, Conversão, Qualidade), ajustes finais — passe de design/UX já feito antes de começar (ver seção 11), incluindo a correção da semântica de `quantidade_pedida` por setor (ver 9.1) e o primeiro APK Android gerado e testado (ver seção 12) |

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

**`ordens_producao.quantidade_pedida` é sempre o total do produto final pedido pelo cliente — nunca o que a Onduladeira precisa produzir.** Numa OP 803 (sem Conversão) isso já é chapa, porque chapa é o produto final ali. Numa OP 802, é **caixa** — o total de caixas que o cliente quer no final, depois da Conversão. Isso importa porque o alvo de progresso é diferente por setor:

- **Onduladeira** (`OrdemProducaoInfo.alvoChapasOnduladeira`): quantas chapas ela precisa produzir pra alimentar a Conversão o bastante — `quantidade_pedida ÷ arranjo` (arredondado pra cima). Ex.: pedido de 10.000 caixas com arranjo 2 (2 caixas por chapa) → a Onduladeira só precisa de 5.000 chapas. Numa OP 803 (sem `arranjo` cadastrado, tratado como 1) o alvo é a própria `quantidade_pedida` — nada muda ali. O cartão "Produzido nesta OP" no detalhe da Onduladeira soma só paletes com `setor_origem = 'onduladeira'` (nunca as caixas da Conversão, que são outra unidade) contra esse alvo.
- **Conversão** (cartão "Progresso do pedido", ao lado do de "Chapas disponíveis"): usa `quantidade_pedida` direto, sem dividir — é a contagem de caixas que ela mesma está produzindo rumo ao total pedido.

**Encerramento da OP (`status` vira `concluida`) é sempre uma ação explícita da Onduladeira, nunca automática por bater a quantidade pedida** — em alguns casos a quantidade apontada passa do pedido (a última pilha raramente fecha exatamente no número), então não dá pra fechar sozinho só por atingir o alvo. Duas formas de encerrar, mesmo efeito: o botão "Encerrar produção" no detalhe da OP (`CadastrosRepository.encerrarOrdemProducao`), ou marcar "Este é o último palete desta OP" ao confirmar um apontamento (encerra logo depois de gravar aquele palete). Depois de encerrada, a OP some da lista de "Ordens em aberto" e não aceita mais apontamento novo, mas continua acessível pra busca/histórico (ver 9.2) e pra teste de qualidade (ver 9.6) — testar depois de fechada é o caso comum.

Na tela de detalhe da OP (Conversão) aparece **Chapas total** e **Chapas disponíveis**. `chapas_total` é a soma do `saldo_disponivel` de tudo que a Onduladeira já apontou nessa OP (líquido de reprovação de qualidade do lado dela). `chapas_disponiveis` é esse total menos as chapas já consumidas pela Conversão — e consumo **não** é sempre 1 caixa = 1 chapa: depende do `arranjo` da FT (ver 5.3), quantas caixas saem de 1 chapa no arranjo de impressão. As caixas já apontadas (soma de `quantidade_calculada` de tudo que a Conversão apontou nessa OP) são convertidas de volta em chapas dividindo pelo `arranjo` (arredondando pra cima, `ceil`, pra nunca superestimar o que sobrou). FT sem `arranjo` cadastrado usa 1 (uma chapa = uma caixa, igual ao comportamento antes desse campo existir). Fica vermelho se ficar negativo (apontou mais caixa do que tinha chapa disponível), mas isso é só aviso visual — não bloqueia o apontamento. O apontamento da Conversão continua sendo feito palete a palete, quando aquele palete estiver completo.

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

### 9.6 Campos de qualidade da Ficha Técnica e teste de qualidade (Sprint 9)

Cada Ficha Técnica tem especificações técnicas próprias do produto (não da Composição/tipo de onda, que é compartilhada entre várias FTs): `Gramatura`, `Coluna`, `Cobb Interno`, `Cobb Externo`, `Mullen`, `Compressão`, `Resina Interna`, `Resina Externa`. Todos opcionais no cadastro — ver 5.1.

**Teste de qualidade** (`testes_qualidade`): a Qualidade registra os valores medidos de uma OP — sempre por **OP**, nunca por palete específico, porque o teste representa uma amostragem do lote, não uma chapa isolada. Os 8 campos do teste são todos opcionais e independentes entre si: nem toda chapa tem, por exemplo, Cobb ou Resina testado, então não faz sentido obrigar o preenchimento de tudo pra salvar um teste.

O app compara cada campo medido com o alvo/faixa da FT daquela OP e mostra um **selo por campo** (aprovado/reprovado/neutro) — não existe um selo único resumindo o teste inteiro, porque cada campo é independente. Neutro é o selo de um campo que não foi medido nesse teste, ou cuja FT não tem alvo/faixa cadastrado pra comparar (não dá pra aprovar nem reprovar sem ter o que comparar). A regra de aprovação muda por campo:

- **Cobb interno/externo e Resina interna/externa** (cadastrados como faixa mín/máx na FT — ver 5.1): aprovado se o valor medido cair dentro da faixa `[mín, máx]`, reprovado se ficar fora (pra cima ou pra baixo).
- **Gramatura, Coluna, Mullen, Compressão** (valor único na FT): aprovado se o medido estiver dentro de **±5% de tolerância** do valor cadastrado — fixo no código por enquanto (`toleranciaPadrao` em `lib/domain/services/avaliacao_qualidade.dart`), sem cadastro de tolerância por campo ainda.

A Parte 2 desse sprint adiciona notificação push quando um teste é registrado — só pros usuários **operadores da Onduladeira** (não Gestão, não Qualidade — quem registrou o teste não precisa ser avisado do próprio teste), respeitando o turno de cada um. `profiles.turno` já existe pra isso (obrigatório pra todo usuário, não só Onduladeira): `primeiro` (07:00–16:48), `segundo` (16:48–01:48) ou `comercial` — cadastrado/editado na tela de Usuários junto com nome/perfil. O resto da Parte 2 (projeto Firebase, tokens de dispositivo, Edge Function de envio) ainda está em andamento.

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

### 9.12 Modo offline — Fase 1 (Sprint 8)

Cobre só o caminho crítico: continuar apontando palete mesmo sem internet, pra Onduladeira e Conversão. Refugo, ocorrências de qualidade e cadastros continuam exigindo conexão (Fase 2, mesma infraestrutura, ainda não construída).

**Padrão usado — fila de escrita (outbox) separada de cache de leitura, não replicação total do banco:**

- **Cache de leitura** (`LocalOrdens`, banco SQLite local via `drift`, arquivo próprio fora do Supabase): guarda as OPs em aberto. Toda vez que a Onduladeira busca a lista online com sucesso, o cache é **substituído por inteiro** (não acumula — evita o "armazenamento progressivo"). A busca da Conversão, por ser um subconjunto (só 802 com palete da Onduladeira), só complementa o cache sem apagar o que já tem. Offline, cada tela lê desse mesmo cache, filtrando localmente pela mesma regra da versão online (Conversão perde só a checagem exata de "já tem palete da Onduladeira" — vira aproximação por prefixo, até reconectar).
- **Cache de paletes** (`LocalPaletes`): guarda os paletes de uma OP assim que a tela de detalhe é aberta com sucesso online — não é pré-carregado pra toda OP aberta, só pra quem o operador realmente visitou (mantém o cache pequeno).
- **Fila de pendentes**: um apontamento feito offline vira uma linha em `LocalPaletes` com `sincronizado = false` e um **id gerado no aparelho** (uuid) — nunca um número sequencial, porque dois aparelhos offline apontando pra mesma OP não têm como combinar quem fica com qual número. O `numero_sequencial` definitivo só é atribuído pelo servidor no momento da sincronização (mesma lógica de sempre: pega o maior da OP e soma 1). O palete aparece na lista com "PENDENTE DE ENVIO" enquanto isso.
- **Detecção de rede**: não confia num status de conectividade isolado — cada chamada ao Supabase tem timeout de 6s, e falha de rede (timeout, `SocketException`, etc.) é o que decide cair pro caminho offline, não uma verificação prévia. O pacote `connectivity_plus` só é usado pra saber **quando tentar de novo** (dispara `sincronizarPendentes()` sempre que a conexão volta), não pra decidir se uma ação individual deve ir direto pro cache.
- **Sincronização**: percorre a fila item a item; cada um só sai da fila se o servidor confirmar. Se falhar (ex: a OP foi concluída por outra pessoa enquanto estava offline), a linha fica marcada com o erro em vez de sumir ou tentar de novo sozinha sem avisar — aparece na lista como "erro: …".
- **Ações que dependem do palete já existir no servidor** (pedir revisão, segregar, corrigir, excluir — ver 9.5) ficam bloqueadas num palete ainda pendente, com aviso explicando o motivo.

### 9.13 Modo offline — Fase 2 (refugo, ocorrência, cadastros)

Estende a mesma fila de pendentes da Fase 1, mas de forma genérica: uma única tabela local (`PendingOperations`, `tipo` + `payload` json) em vez de uma tabela por entidade. Cobre só as escritas que **não dependem de ler o estado atual de nada no servidor antes** — por isso o recorte não é "tudo", é bem específico:

- **Entram na fila**: lançar refugo, pedir revisão de qualidade, criar Cliente/Composição/Ficha Técnica/OP, editar Ficha Técnica. Nenhuma dessas precisa saber o que já existe no servidor pra ser válida — só grava um registro novo (ou atualiza um id que o app já tem).
- **Não entram — continuam exigindo conexão**: segregar inteiro, resolver ocorrência, corrigir apontamento, excluir totalmente. Todas essas debitam em cima do **saldo atual** do palete; fazer isso com um número que pode estar desatualizado (por exemplo, outra ocorrência já debitou uma parte enquanto o aparelho estava offline) arrisca um débito incorreto que o app não teria como perceber sozinho. Diferente do `numero_sequencial` do palete (que só é "cosmético" e se resolve sozinho no servidor), aqui o próprio valor sendo gravado depende do estado — não dá pra adiar a leitura com segurança.
- **Diferença de visibilidade em relação à Fase 1**: apontamento de palete tem cache próprio, então o item pendente aparece na lista de paletes da OP, junto com os outros. Refugo/ocorrência/cadastros não têm lista em cache — o item some da tela de origem até sincronizar. A confirmação de que "salvou, só não sincronizou ainda" fica na tela **Pendências de sincronização** (Admin, em Cadastros), que mostra as duas filas (apontamentos + fila genérica) ao vivo, com o erro de cada item que falhar e um botão de sincronizar manualmente.
- O dispatcher da fila genérica (`Sincronizador._enviar`) interpreta `tipo` como `<tabela>_criar` ou `<tabela>_atualizar` pros cadastros, e como `refugo`/`ocorrencia_abrir` pros outros dois — não precisa de um caso novo por tabela, só de payload com as mesmas chaves que o insert/update já usaria.

---

## 10. Fora de escopo por agora (Fase 2)

- **Dados de Conversão no cadastro da FT**: cores de tinta, clichê, arranjo, peças por amarrado. (Paletização — altura/pacotes/camada — já saiu daqui e foi implementada, ver 5.3.)
- **Perfil `expedicao`**: consulta de OPs 802 em produção, carregamento pro cliente.
- Chapa elaborada com fluxo de Quebra mais refinado.
- OCR de etiqueta.
- **Modo offline — ações que dependem de saldo atual do palete** (segregar inteiro, resolver ocorrência, corrigir apontamento, excluir totalmente): continuam exigindo conexão de propósito — ver 9.13.

---

## 11. Identidade visual e padrões de tela

Passe de design feito depois do Sprint 8, preparando o terreno pros sprints seguintes (9 — testes de qualidade — e 10 — piloto). Cobriu duas coisas ao mesmo tempo: a camada visual em si (tema, componentes, layout) e, ao revisar tela por tela, algumas correções reais de regra de negócio que só ficaram óbvias olhando a UI de novo (documentadas onde fazem sentido — 9.1 — e só referenciadas aqui).

**Tema e fundamentos**

- **Cor de marca**: `#0EA9F6` (azul institucional da empresa), semente do `ColorScheme` do app (`lib/core/theme/app_theme.dart`), com tema claro e escuro. Independente da paleta usada nos gráficos do Dashboard (`#2A78D6`/`#EB6834`), escolhida à parte por contraste pra daltonismo — ver seção do Dashboard no Sprint 7.
- **Responsivo por padrão**: o app roda tanto em desktop (Windows, usado hoje pra admin/cadastros e testes) quanto em celular/tablet no chão de fábrica (onde o operador vai usar o leitor de código de barras via `mobile_scanner`, Sprint 6). Formulários e listas ficam com largura máxima confortável em telas largas e ocupam a tela toda em telas estreitas, via `LarguraFormulario` (`lib/shared/widgets/apontamento_kit.dart`) — o padrão é 480px (uma coluna), mas telas em grade ou com gráfico (home de Cadastros, Dashboard) passam um `maxWidth` maior (800px) pra caber mais colunas/largura de gráfico.

**Kit de widgets compartilhado** (`lib/shared/widgets/apontamento_kit.dart`) — usado em toda tela do app, cadastro ou operacional, pra não reinventar formulário/lista tela por tela:

- `RotuloSecao` (rótulo discreto acima de um campo) e `RotuloSecaoMaiuscula` (rótulo em caixa alta, mais forte, pra separar blocos dentro de uma tela — ex.: seções da home de Cadastros, "Qualidade"/"Vincos"/"Paletização" no formulário de Ficha Técnica).
- `CampoRotulado` e `DropdownRotulado`: campo de texto/dropdown com `RotuloSecao` acima e hint dentro, no lugar do label flutuante padrão do Material — é o padrão de formulário do app inteiro agora (cadastros, login, e todos os diálogos de ação sobre palete/refugo/ocorrência). `linhaDupla()` põe dois desses lado a lado (ex.: Comprimento/Largura, QP padrão/Referência) e `validarNumeroPositivo()` é o validador padrão de campo numérico obrigatório.
- `CartaoInfo` (cartão neutro com linhas rótulo+valor, pra dados de referência como Cliente/Composição/Medida/QP padrão ou uma linha avulsa como "Próximo palete desta OP"), `CartaoProgresso` (métrica + barra + percentual — "produzido nesta OP" da Onduladeira, "chapas disponíveis" e "progresso do pedido" da Conversão, e a prévia de progresso nas listas de OP), `CartaoResultado` (destaque de um resultado calculado — quantidade calculada antes de confirmar um apontamento, ou a nova quantidade ao corrigir um palete), `BotaoAcaoPrincipal` (botão de alto contraste, sempre a última ação da tela) e `CartaoLista` (linha de lista em cartão arredondado — com barra de progresso opcional —, substituindo `ListTile` cru em toda lista do app).

**Apontamento embutido na tela de detalhe da OP, sem tela nem diálogo à parte**: `OrdemDetalheView` (Onduladeira) e `OrdemDetalheConversaoView` (Conversão) trazem o contexto da FT, os cartões de progresso, o campo de medida (altura ou camadas), "Próximo palete desta OP", a quantidade calculada e o botão de confirmar todos juntos, no topo da própria tela. Depois de confirmar um apontamento a tela não navega pra lugar nenhum: só limpa o campo de medida, pra apontar o próximo palete em sequência sem sair da tela. Ficha Técnica aparece só como contexto (campo desabilitado com os dados da FT embaixo), já que a escolha aconteceu na tela anterior (lista de OPs) — não tem mais campo de busca de FT/OP nessa tela. O histórico de paletes já apontados **não** fica mais na mesma tela: fica atrás de um botão "Paletes apontados (N)", que abre `PaletesApontadosView`/`PaletesApontadosConversaoView` — telas dedicadas só pra essa lista, com data completa (`dd/MM HH:mm`, não só a hora) em cada linha. (Existiu uma versão intermediária com uma tela cheia separada de apontamento, alcançada por um FAB — foi abandonada por pedido do usuário antes de qualquer commit; não existe no histórico do repositório.)

**Prévia de progresso nas listas de OP**: `OrdensAbertasView` (Onduladeira) e `OrdensDisponiveisView` (Conversão) mostram uma barra de progresso fina em cada cartão, sem precisar abrir o detalhe — vem de uma query agregada só (`_comProgressoOnduladeira`/`_comProgressoConversao` em `paletes_repository.dart`, não é N+1) que falha de forma silenciosa (a lista continua aparecendo sem a barra) se der erro. Offline, a barra não aparece pra OPs nunca visitadas, porque o cache local não guarda esse agregado.

**Home do Admin reorganizada**: `CadastrosHomeView` trocou a lista única por um cabeçalho próprio (avatar com iniciais, nome, perfil, botão de sair) e os itens agrupados em 3 seções — CADASTROS, OPERACIONAL (com uma "pill" mostrando o setor em vez de seta), GESTÃO — numa grade responsiva (`_GradeMenu`, calcula colunas pelo espaço disponível, sem breakpoint fixo).

**Etiqueta continua adiada**: nenhum botão de confirmar apontamento promete impressão de etiqueta (fica só "Confirmar apontamento") — isso é do Sprint 6, ainda sem data.

**Cadastro de Ordem de Produção**: formulário passou pro padrão `CampoRotulado`/`DropdownRotulado`, e o campo "Data do pedido" (que pedia pra escolher manualmente num date picker) saiu — a data é sempre a de hoje, gravada automaticamente ao salvar. `OrdemProducao` ganhou o getter `unidadePedido` (`chapas` pra OP 803, `caixas` pra 802 — mesma regra do prefixo, ver seção 1), usado na lista pra não rotular tudo como "chapas" incondicionalmente.

**Cadastro de Composição virou papel por papel**: em vez de digitar o `codigo` livre (ex.: `T140M130T140/B`), o admin escolhe o **tipo de onda** — `B`/`C` (onda simples, 3 papéis: capa/miolo/capa) ou `DB`/`DC` (onda dupla, 5 papéis: capa/miolo/capa/miolo/capa) — e um papel por campo (lista fixa de exemplo por enquanto: `T090`, `T110`, `T140`, `T170`, `T190`, `T210`, ver `papeisDisponiveis` em `lib/domain/entities/composicao.dart`). O `codigo` é gerado pelo app a partir disso (papéis concatenados + `/` + tipo de onda) e mostrado como prévia antes de salvar — não é mais digitado direto, mesmo padrão de "o app calcula" já usado em `quantidade_calculada`. As 2 composições já cadastradas foram migradas pros campos novos com backfill, sem perder dado.

---

## 12. Build Android (APK)

Primeiro APK gerado e testado num celular de verdade nesse passe de design pré-piloto. Duas coisas precisaram de ajuste pra funcionar — nenhuma delas é regra de negócio, são só configuração de build:

- **Faltava a permissão de internet**: `android/app/src/main/AndroidManifest.xml` não tinha `<uses-permission android:name="android.permission.INTERNET"/>`. Sem ela o app abre normalmente, mas todo acesso ao Supabase (login incluído) falha em silêncio — nenhuma das dependências do projeto declarava essa permissão sozinha (diferente de, por exemplo, `mobile_scanner`, que já traz `CAMERA` na própria manifest).
- **Bug do compilador Kotlin no Windows quando projeto e cache do Flutter ficam em drives diferentes** (aqui: projeto em `F:`, pub cache em `C:`) — a compilação incremental do Kotlin tenta calcular caminho relativo entre os dois e quebra com `this and base files have different roots`. Corrigido desligando a otimização em `android/gradle.properties` (`kotlin.incremental=false`). Só deixa o build Android um pouco mais lento (recompila do zero o Kotlin dos plugins a cada vez) — não afeta o app instalado nem o build Windows.

**Como gerar**: `flutter build apk --release`, gera `build/app/outputs/flutter-apk/app-release.apk` (~74 MB, universal — roda em qualquer Android). Assinado com a chave de debug (`signingConfig` já configurado assim em `android/app/build.gradle.kts`, comentário original do template) — serve pra teste interno/piloto, não pra publicar na Play Store, que exigiria uma chave de release própria.

### 12.1 Firebase (push notification, Sprint 9 parte 2)

Projeto Firebase `controle-de-paletes-36a14`, criado só pra Android — o app roda em Windows (dev/admin) e Android, mas o Firebase só foi configurado pra Android (`flutterfire configure --platforms=android`, gerou `lib/firebase_options.dart` e `android/app/google-services.json`). `main.dart` só chama `Firebase.initializeApp` quando `Platform.isAndroid`; em qualquer outra plataforma isso é pulado de propósito — `firebase_core`/`firebase_messaging` compilam para Windows (o link do `firebase_app.lib` funciona), mas nunca são inicializados lá.

- **`PushNotificationsService`** (`lib/data/services/push_notifications_service.dart`): chamado depois de todo login bem-sucedido (`AuthController._carregarPerfil`), fire-and-forget — pede permissão de notificação, pega o token do FCM e grava/atualiza em `device_tokens` (um token por aparelho, `upsert` por `token`). Nunca lança erro: falha de permissão, sem Google Play Services etc. não pode derrubar o login.
- **`device_tokens`**: tabela nova, RLS restringe cada usuário a gerenciar só o próprio token — quem lê de verdade é a Edge Function, via `service_role` (ignora RLS).
- **Edge Function `notificar-teste-qualidade`**: chamada pelo app logo depois de `QualidadeRepository.registrarTeste` salvar com sucesso (não dispara se o insert cair pra fila offline). Calcula o turno atual a partir da hora do servidor (Brasil = UTC-3), busca quem é `perfil = 'onduladeira'` e está nesse turno, pega os tokens desses usuários e manda o push via `firebase-admin` (Admin SDK, autenticado com a service account do projeto, guardada como secret `FIREBASE_SERVICE_ACCOUNT_JSON`). Só Onduladeira recebe — Gestão e Qualidade não, porque quem registra o teste é a própria Qualidade.
- **Turno do usuário** (`profiles.turno`, obrigatório): `primeiro` (07:00–16:48), `segundo` (16:48–01:48, e cobre também o intervalo residual até as 07:00) ou `comercial` (sem correspondência de turno na Edge Function — hoje só usado por quem não é Onduladeira, então nunca entra no filtro de notificação). Cadastrado/editado na tela de Usuários.
