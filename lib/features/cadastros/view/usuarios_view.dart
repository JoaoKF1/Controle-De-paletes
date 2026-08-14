import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/usuarios_repository.dart';
import '../../../domain/entities/usuario.dart';

const _perfis = ['admin', 'onduladeira', 'conversao', 'qualidade'];

final _usuariosProvider = FutureProvider.autoDispose<List<Usuario>>((ref) {
  return ref.watch(usuariosRepositoryProvider).listarUsuarios();
});

class UsuariosView extends ConsumerWidget {
  const UsuariosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(_usuariosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Usuários')),
      body: usuariosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (erro, _) => Center(child: Text('Erro ao carregar: $erro')),
        data: (usuarios) {
          if (usuarios.isEmpty) {
            return const Center(
              child: Text('Nenhum usuário cadastrado ainda.'),
            );
          }
          return ListView.separated(
            itemCount: usuarios.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = usuarios[i];
              return ListTile(
                title: Text(
                  u.nome,
                  style: u.ativo
                      ? null
                      : const TextStyle(decoration: TextDecoration.lineThrough),
                ),
                subtitle: Text(
                  '${u.login} · ${u.perfil}${u.ativo ? '' : ' · inativo'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrirAcoes(context, ref, u),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormularioCriar(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _abrirAcoes(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar nome/perfil'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _abrirFormularioEditar(context, ref, usuario);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Trocar senha'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _abrirFormularioSenha(context, ref, usuario);
              },
            ),
            ListTile(
              leading: Icon(usuario.ativo ? Icons.block : Icons.check_circle),
              title: Text(usuario.ativo ? 'Desativar' : 'Reativar'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await ref
                    .read(usuariosRepositoryProvider)
                    .definirAtivo(userId: usuario.id, ativo: !usuario.ativo);
                ref.invalidate(_usuariosProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFormularioCriar(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final formKey = GlobalKey<FormState>();
    final loginController = TextEditingController();
    final senhaController = TextEditingController();
    final nomeController = TextEditingController();
    var perfilSelecionado = _perfis.first;
    String? erro;
    var salvando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Novo usuário'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
                TextFormField(
                  controller: loginController,
                  decoration: const InputDecoration(
                    labelText: 'Usuário (login)',
                    helperText: 'Sem espaços, ex: joaoaguiar',
                  ),
                  validator: (v) {
                    final valor = v?.trim() ?? '';
                    if (valor.isEmpty) return 'Obrigatório';
                    if (valor.contains(' ')) return 'Sem espaços';
                    return null;
                  },
                ),
                TextFormField(
                  controller: senhaController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: perfilSelecionado,
                  decoration: const InputDecoration(labelText: 'Perfil'),
                  items: _perfis
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => perfilSelecionado = v!),
                ),
                if (erro != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    erro!,
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => salvando = true);
                      try {
                        await ref
                            .read(usuariosRepositoryProvider)
                            .criarUsuario(
                              login: loginController.text.trim(),
                              senha: senhaController.text,
                              nome: nomeController.text.trim(),
                              perfil: perfilSelecionado,
                            );
                        ref.invalidate(_usuariosProvider);
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setState(() {
                            salvando = false;
                            erro = e.toString();
                          });
                        }
                      }
                    },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFormularioEditar(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: usuario.nome);
    var perfilSelecionado = usuario.perfil;
    var salvando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Editar usuário'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: perfilSelecionado,
                  decoration: const InputDecoration(labelText: 'Perfil'),
                  items: _perfis
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => perfilSelecionado = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => salvando = true);
                      await ref
                          .read(usuariosRepositoryProvider)
                          .atualizarPerfil(
                            userId: usuario.id,
                            nome: nomeController.text.trim(),
                            perfil: perfilSelecionado,
                          );
                      ref.invalidate(_usuariosProvider);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirFormularioSenha(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario,
  ) async {
    final formKey = GlobalKey<FormState>();
    final senhaController = TextEditingController();
    String? erro;
    var salvando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('Trocar senha de ${usuario.nome}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: senhaController,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),
                if (erro != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    erro!,
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => salvando = true);
                      try {
                        await ref
                            .read(usuariosRepositoryProvider)
                            .trocarSenha(
                              userId: usuario.id,
                              novaSenha: senhaController.text,
                            );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop();
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setState(() {
                            salvando = false;
                            erro = e.toString();
                          });
                        }
                      }
                    },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
