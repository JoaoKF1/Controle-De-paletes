// Edge Function: cria usuário e troca senha via Supabase Auth Admin API.
// Roda com a service_role key (segredo do projeto, nunca exposta ao app) e
// só executa a ação depois de confirmar que quem chamou é um admin.
import { createClient } from 'jsr:@supabase/supabase-js@2';

const DOMINIO_AUTH = 'controle-paletes.app';

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
  const admin = createClient(supabaseUrl, serviceRoleKey);

  const { data: userData, error: userError } = await admin.auth.getUser(jwt);
  if (userError || !userData.user) {
    return jsonResponse({ erro: 'Sessão inválida' }, 401);
  }

  const { data: perfilCaller, error: perfilError } = await admin
    .from('profiles')
    .select('perfil')
    .eq('id', userData.user.id)
    .single();
  if (perfilError || perfilCaller?.perfil !== 'admin') {
    return jsonResponse({ erro: 'Apenas admin pode gerenciar usuários' }, 403);
  }

  const body = await req.json();

  if (body.acao === 'criar') {
    const { login, senha, nome, perfil, turno } = body;
    if (!login || !senha || !nome || !perfil || !turno) {
      return jsonResponse({ erro: 'Campos obrigatórios faltando' }, 400);
    }
    const loginNormalizado = String(login).trim().toLowerCase();
    if (!/^[a-z0-9._-]+$/.test(loginNormalizado)) {
      return jsonResponse(
        { erro: 'Usuário deve ter só letras, números, ponto, hífen ou underline — sem espaço' },
        400,
      );
    }
    const email = `${loginNormalizado}@${DOMINIO_AUTH}`;

    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email,
      password: senha,
      email_confirm: true,
    });
    if (createError || !created.user) {
      return jsonResponse({ erro: createError?.message ?? 'Falha ao criar usuário' }, 400);
    }

    const { error: profileError } = await admin.from('profiles').insert({
      id: created.user.id,
      login: loginNormalizado,
      nome,
      perfil,
      turno,
      ativo: true,
    });
    if (profileError) {
      await admin.auth.admin.deleteUser(created.user.id);
      return jsonResponse({ erro: profileError.message }, 400);
    }

    return jsonResponse({ ok: true, user_id: created.user.id }, 200);
  }

  if (body.acao === 'trocar_senha') {
    const { user_id, senha } = body;
    if (!user_id || !senha) {
      return jsonResponse({ erro: 'Campos obrigatórios faltando' }, 400);
    }
    const { error } = await admin.auth.admin.updateUserById(user_id, { password: senha });
    if (error) {
      return jsonResponse({ erro: error.message }, 400);
    }
    return jsonResponse({ ok: true }, 200);
  }

  return jsonResponse({ erro: 'Ação desconhecida' }, 400);
});

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
