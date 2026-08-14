-- Migration unit 1: schema_changes
-- Transaction mode: transactional
-- Boundary reason: default

DROP EXTENSION pg_net;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT DELETE, INSERT, SELECT, UPDATE ON TABLES TO anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON ROUTINES TO anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT DELETE, INSERT, SELECT, UPDATE ON TABLES TO authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON ROUTINES TO authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT DELETE, INSERT, SELECT, UPDATE ON TABLES TO service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT, USAGE ON SEQUENCES TO service_role;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON ROUTINES TO service_role;

CREATE TABLE public.clientes (
  id           uuid                     DEFAULT gen_random_uuid() NOT NULL,
  razao_social text                     NOT NULL,
  cidade       text                     NOT NULL,
  uf           text                     NOT NULL,
  ativo        boolean                  DEFAULT true NOT NULL,
  created_at   timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.clientes
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.clientes
  ADD CONSTRAINT clientes_pkey PRIMARY KEY (id);

GRANT ALL ON public.clientes TO anon;

GRANT ALL ON public.clientes TO authenticated;

GRANT ALL ON public.clientes TO service_role;

CREATE POLICY "leitura geral clientes" ON public.clientes
  FOR SELECT
  USING (true);

CREATE TABLE public.composicoes (
  id           uuid                     DEFAULT gen_random_uuid() NOT NULL,
  codigo       text                     NOT NULL,
  espessura_mm numeric                  NOT NULL,
  created_at   timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.composicoes
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.composicoes
  ADD CONSTRAINT composicoes_codigo_key UNIQUE (codigo);

ALTER TABLE public.composicoes
  ADD CONSTRAINT composicoes_espessura_mm_check CHECK (espessura_mm > 0::numeric);

ALTER TABLE public.composicoes
  ADD CONSTRAINT composicoes_pkey PRIMARY KEY (id);

GRANT ALL ON public.composicoes TO anon;

GRANT ALL ON public.composicoes TO authenticated;

GRANT ALL ON public.composicoes TO service_role;

CREATE POLICY "leitura geral composicoes" ON public.composicoes
  FOR SELECT
  USING (true);

CREATE TABLE public.fichas_tecnicas (
  id            uuid                     DEFAULT gen_random_uuid() NOT NULL,
  codigo_ft     text                     NOT NULL,
  cliente_id    uuid                     NOT NULL,
  composicao_id uuid                     NOT NULL,
  medida_chapa  text                     NOT NULL,
  qp_padrao     integer                  NOT NULL,
  referencia    text,
  ativo         boolean                  DEFAULT true NOT NULL,
  created_at    timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.fichas_tecnicas
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.fichas_tecnicas
  ADD CONSTRAINT fichas_tecnicas_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);

ALTER TABLE public.fichas_tecnicas
  ADD CONSTRAINT fichas_tecnicas_codigo_ft_key UNIQUE (codigo_ft);

ALTER TABLE public.fichas_tecnicas
  ADD CONSTRAINT fichas_tecnicas_composicao_id_fkey FOREIGN KEY (composicao_id) REFERENCES public.composicoes(id);

ALTER TABLE public.fichas_tecnicas
  ADD CONSTRAINT fichas_tecnicas_pkey PRIMARY KEY (id);

ALTER TABLE public.fichas_tecnicas
  ADD CONSTRAINT fichas_tecnicas_qp_padrao_check CHECK (qp_padrao > 0);

GRANT ALL ON public.fichas_tecnicas TO anon;

GRANT ALL ON public.fichas_tecnicas TO authenticated;

GRANT ALL ON public.fichas_tecnicas TO service_role;

CREATE POLICY "leitura geral fichas_tecnicas" ON public.fichas_tecnicas
  FOR SELECT
  USING (true);

CREATE TABLE public.historico_ocorrencia (
  id              uuid                     DEFAULT gen_random_uuid() NOT NULL,
  ocorrencia_id   uuid                     NOT NULL,
  usuario_id      uuid                     NOT NULL,
  status_anterior text                     NOT NULL,
  status_novo     text                     NOT NULL,
  data_hora       timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.historico_ocorrencia
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.historico_ocorrencia
  ADD CONSTRAINT historico_ocorrencia_pkey PRIMARY KEY (id);

GRANT ALL ON public.historico_ocorrencia TO anon;

GRANT ALL ON public.historico_ocorrencia TO authenticated;

GRANT ALL ON public.historico_ocorrencia TO service_role;

CREATE TABLE public.ocorrencias_qualidade (
  id                 uuid                     DEFAULT gen_random_uuid() NOT NULL,
  palete_id          uuid                     NOT NULL,
  quantidade_afetada integer                  NOT NULL,
  motivo             text                     NOT NULL,
  status             text                     DEFAULT 'em_analise'::text NOT NULL,
  aberto_por         uuid                     NOT NULL,
  data_abertura      timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.ocorrencias_qualidade
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.ocorrencias_qualidade
  ADD CONSTRAINT ocorrencias_qualidade_pkey PRIMARY KEY (id);

ALTER TABLE public.historico_ocorrencia
  ADD CONSTRAINT historico_ocorrencia_ocorrencia_id_fkey FOREIGN KEY (ocorrencia_id) REFERENCES public.ocorrencias_qualidade(id);

ALTER TABLE public.ocorrencias_qualidade
  ADD CONSTRAINT ocorrencias_qualidade_quantidade_afetada_check CHECK (quantidade_afetada > 0);

ALTER TABLE public.ocorrencias_qualidade
  ADD CONSTRAINT ocorrencias_qualidade_status_check CHECK (status = ANY (ARRAY['em_analise'::text, 'liberado'::text, 'reprovado'::text]));

GRANT ALL ON public.ocorrencias_qualidade TO anon;

GRANT ALL ON public.ocorrencias_qualidade TO authenticated;

GRANT ALL ON public.ocorrencias_qualidade TO service_role;

CREATE TABLE public.ordens_producao (
  id                uuid                     DEFAULT gen_random_uuid() NOT NULL,
  numero_op         text                     NOT NULL,
  ficha_tecnica_id  uuid                     NOT NULL,
  quantidade_pedida integer                  NOT NULL,
  data_pedido       date                     NOT NULL,
  status            text                     DEFAULT 'aberta'::text NOT NULL,
  created_at        timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.ordens_producao
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.ordens_producao
  ADD CONSTRAINT ordens_producao_data_pedido_check CHECK (data_pedido <= CURRENT_DATE);

ALTER TABLE public.ordens_producao
  ADD CONSTRAINT ordens_producao_ficha_tecnica_id_fkey FOREIGN KEY (ficha_tecnica_id) REFERENCES public.fichas_tecnicas(id);

ALTER TABLE public.ordens_producao
  ADD CONSTRAINT ordens_producao_numero_op_key UNIQUE (numero_op);

ALTER TABLE public.ordens_producao
  ADD CONSTRAINT ordens_producao_pkey PRIMARY KEY (id);

ALTER TABLE public.ordens_producao
  ADD CONSTRAINT ordens_producao_quantidade_pedida_check CHECK (quantidade_pedida > 0);

ALTER TABLE public.ordens_producao
  ADD CONSTRAINT ordens_producao_status_check CHECK (status = ANY (ARRAY['aberta'::text, 'concluida'::text]));

GRANT ALL ON public.ordens_producao TO anon;

GRANT ALL ON public.ordens_producao TO authenticated;

GRANT ALL ON public.ordens_producao TO service_role;

CREATE POLICY "leitura geral ordens_producao" ON public.ordens_producao
  FOR SELECT
  USING (true);

CREATE TABLE public.paletes (
  id                   uuid                     DEFAULT gen_random_uuid() NOT NULL,
  ordem_producao_id    uuid                     NOT NULL,
  numero_sequencial    integer                  NOT NULL,
  altura_medida_mm     numeric                  NOT NULL,
  quantidade_calculada integer                  NOT NULL,
  tipo_chapa           text                     DEFAULT 'semi_elaborado'::text NOT NULL,
  setor_origem         text                     NOT NULL,
  codigo_barras        text,
  responsavel_id       uuid                     NOT NULL,
  data_hora            timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.paletes
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.paletes
  ADD CONSTRAINT paletes_altura_medida_mm_check CHECK (altura_medida_mm > 0::numeric);

ALTER TABLE public.paletes
  ADD CONSTRAINT paletes_codigo_barras_key UNIQUE (codigo_barras);

ALTER TABLE public.paletes
  ADD CONSTRAINT paletes_ordem_producao_id_fkey FOREIGN KEY (ordem_producao_id) REFERENCES public.ordens_producao(id);

ALTER TABLE public.paletes
  ADD CONSTRAINT paletes_ordem_producao_id_numero_sequencial_key UNIQUE (ordem_producao_id, numero_sequencial);

ALTER TABLE public.paletes
  ADD CONSTRAINT paletes_pkey PRIMARY KEY (id);

ALTER TABLE public.ocorrencias_qualidade
  ADD CONSTRAINT ocorrencias_qualidade_palete_id_fkey FOREIGN KEY (palete_id) REFERENCES public.paletes(id);

ALTER TABLE public.paletes
  ADD CONSTRAINT paletes_setor_origem_check CHECK (setor_origem = ANY (ARRAY['onduladeira'::text, 'conversao'::text]));

ALTER TABLE public.paletes
  ADD CONSTRAINT paletes_tipo_chapa_check CHECK (tipo_chapa = ANY (ARRAY['semi_elaborado'::text, 'elaborado'::text]));

GRANT ALL ON public.paletes TO anon;

GRANT ALL ON public.paletes TO authenticated;

GRANT ALL ON public.paletes TO service_role;

CREATE POLICY "leitura geral" ON public.paletes
  FOR SELECT
  USING (true);

CREATE TABLE public.profiles (
  id         uuid                     NOT NULL,
  nome       text                     NOT NULL,
  perfil     text                     NOT NULL,
  ativo      boolean                  DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  login      text
);

CREATE POLICY "admin escreve clientes" ON public.clientes
  FOR INSERT
  WITH CHECK ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.perfil = 'admin'::text)))));

CREATE POLICY "admin escreve composicoes" ON public.composicoes
  FOR INSERT
  WITH CHECK ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.perfil = 'admin'::text)))));

CREATE POLICY "admin escreve fichas_tecnicas" ON public.fichas_tecnicas
  FOR INSERT
  WITH CHECK ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.perfil = 'admin'::text)))));

CREATE POLICY "admin escreve ordens_producao" ON public.ordens_producao
  FOR INSERT
  WITH CHECK ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.perfil = 'admin'::text)))));

CREATE POLICY "conversao insere seus paletes" ON public.paletes
  FOR INSERT
  WITH CHECK (((setor_origem = 'conversao'::text) AND (EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.perfil = 'conversao'::text))))));

CREATE POLICY "onduladeira insere seus paletes" ON public.paletes
  FOR INSERT
  WITH CHECK (((setor_origem = 'onduladeira'::text) AND (EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.perfil = 'onduladeira'::text))))));

ALTER TABLE public.profiles
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_login_key UNIQUE (LOGIN);

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_perfil_check CHECK (perfil = ANY (ARRAY['onduladeira'::text, 'conversao'::text, 'qualidade'::text, 'admin'::text]));

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);

ALTER TABLE public.historico_ocorrencia
  ADD CONSTRAINT historico_ocorrencia_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.profiles(id);

ALTER TABLE public.ocorrencias_qualidade
  ADD CONSTRAINT ocorrencias_qualidade_aberto_por_fkey FOREIGN KEY (aberto_por) REFERENCES public.profiles(id);

ALTER TABLE public.paletes
  ADD CONSTRAINT paletes_responsavel_id_fkey FOREIGN KEY (responsavel_id) REFERENCES public.profiles(id);

GRANT ALL ON public.profiles TO anon;

GRANT ALL ON public.profiles TO authenticated;

GRANT ALL ON public.profiles TO service_role;

CREATE POLICY "admin atualiza perfis" ON public.profiles
  FOR UPDATE
  USING ((EXISTS ( SELECT 1
   FROM public.profiles profiles_1
  WHERE ((profiles_1.id = auth.uid()) AND (profiles_1.perfil = 'admin'::text)))))
  WITH CHECK ((EXISTS ( SELECT 1
   FROM public.profiles profiles_1
  WHERE ((profiles_1.id = auth.uid()) AND (profiles_1.perfil = 'admin'::text)))));

CREATE POLICY "admin le todos perfis" ON public.profiles
  FOR SELECT
  USING ((EXISTS ( SELECT 1
   FROM public.profiles profiles_1
  WHERE ((profiles_1.id = auth.uid()) AND (profiles_1.perfil = 'admin'::text)))));

CREATE POLICY "leitura do proprio perfil" ON public.profiles
  FOR SELECT
  USING ((auth.uid() = id));

CREATE TABLE public.refugos (
  id                uuid                     DEFAULT gen_random_uuid() NOT NULL,
  ordem_producao_id uuid                     NOT NULL,
  responsavel_id    uuid                     NOT NULL,
  quantidade        integer                  NOT NULL,
  motivo            text                     NOT NULL,
  data_hora         timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE public.refugos
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.refugos
  ADD CONSTRAINT refugos_ordem_producao_id_fkey FOREIGN KEY (ordem_producao_id) REFERENCES public.ordens_producao(id);

ALTER TABLE public.refugos
  ADD CONSTRAINT refugos_pkey PRIMARY KEY (id);

ALTER TABLE public.refugos
  ADD CONSTRAINT refugos_quantidade_check CHECK (quantidade > 0);

ALTER TABLE public.refugos
  ADD CONSTRAINT refugos_responsavel_id_fkey FOREIGN KEY (responsavel_id) REFERENCES public.profiles(id);

GRANT ALL ON public.refugos TO anon;

GRANT ALL ON public.refugos TO authenticated;

GRANT ALL ON public.refugos TO service_role;
