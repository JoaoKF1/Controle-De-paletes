// Edge Function: notifica por push (Firebase Cloud Messaging) os operadores
// da Onduladeira que estão no turno atual, quando um teste de qualidade é
// registrado. Ver plano técnico, 9.6/12. Roda com a service_role key
// (nunca exposta ao app) e só executa depois de confirmar que quem chamou
// tem permissão de registrar teste (qualidade ou admin — mesma regra do
// insert em `testes_qualidade`, ver 9.11).
import { createClient } from 'jsr:@supabase/supabase-js@2';
import admin from 'npm:firebase-admin@12';

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return jsonResponse({ erro: 'Método não permitido' }, 405);
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  const jwt = authHeader.replace('Bearer ', '');
  if (!jwt) {
    return jsonResponse({ erro: 'Não autenticado' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const db = createClient(supabaseUrl, serviceRoleKey);

  const { data: userData, error: userError } = await db.auth.getUser(jwt);
  if (userError || !userData.user) {
    return jsonResponse({ erro: 'Sessão inválida' }, 401);
  }

  const { data: perfilCaller } = await db
    .from('profiles')
    .select('perfil')
    .eq('id', userData.user.id)
    .single();
  if (!perfilCaller || !['qualidade', 'admin'].includes(perfilCaller.perfil)) {
    return jsonResponse({ erro: 'Sem permissão' }, 403);
  }

  const body = await req.json();
  const ordemProducaoId = body.ordem_producao_id as string | undefined;
  if (!ordemProducaoId) {
    return jsonResponse({ erro: 'ordem_producao_id obrigatório' }, 400);
  }

  const { data: ordem } = await db
    .from('ordens_producao')
    .select('numero_op')
    .eq('id', ordemProducaoId)
    .single();
  const numeroOp = ordem?.numero_op ?? '?';

  // Só operador da Onduladeira recebe (quem registra o teste é a
  // Qualidade, não precisa se avisar) e só quem está no turno que está
  // rolando agora — 1º 07:00–16:48, 2º o resto do dia (ver plano técnico).
  const turnoAtual = calcularTurnoAtual();
  const { data: usuarios, error: usuariosError } = await db
    .from('profiles')
    .select('id')
    .eq('perfil', 'onduladeira')
    .eq('turno', turnoAtual)
    .eq('ativo', true);
  if (usuariosError) {
    return jsonResponse({ erro: usuariosError.message }, 500);
  }
  if (!usuarios || usuarios.length === 0) {
    return jsonResponse({ ok: true, enviados: 0 }, 200);
  }

  const { data: tokensData, error: tokensError } = await db
    .from('device_tokens')
    .select('token')
    .in(
      'usuario_id',
      usuarios.map((u: { id: string }) => u.id),
    );
  if (tokensError) {
    return jsonResponse({ erro: tokensError.message }, 500);
  }
  const tokens = (tokensData ?? []).map((t: { token: string }) => t.token as string);
  if (tokens.length === 0) {
    return jsonResponse({ ok: true, enviados: 0 }, 200);
  }

  if (!admin.apps.length) {
    const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  }

  const resposta = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title: 'Novo teste de qualidade',
      body: `Teste registrado na OP ${numeroOp}`,
    },
  });

  // Token de aparelho que desinstalou o app ou nunca mais vai responder —
  // limpa pra não acumular lixo nem tentar de novo à toa da próxima vez.
  const tokensInvalidos: string[] = [];
  resposta.responses.forEach((r, i) => {
    if (!r.success && r.error?.code === 'messaging/registration-token-not-registered') {
      tokensInvalidos.push(tokens[i]);
    }
  });
  if (tokensInvalidos.length > 0) {
    await db.from('device_tokens').delete().in('token', tokensInvalidos);
  }

  return jsonResponse(
    { ok: true, enviados: resposta.successCount, falhas: resposta.failureCount },
    200,
  );
});

/// 1º turno: 07:00–16:48. 2º turno: o resto (16:48–01:48 na prática, mas
/// classificado como "tudo que não é 1º" pra cobrir as 24h sem buraco —
/// ver plano técnico, 9.6).
function calcularTurnoAtual(): 'primeiro' | 'segundo' {
  const agora = new Date();
  const brasil = new Date(agora.getTime() - 3 * 60 * 60 * 1000);
  const minutosDoDia = brasil.getUTCHours() * 60 + brasil.getUTCMinutes();
  const inicioPrimeiro = 7 * 60;
  const fimPrimeiro = 16 * 60 + 48;
  return minutosDoDia >= inicioPrimeiro && minutosDoDia < fimPrimeiro
    ? 'primeiro'
    : 'segundo';
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
