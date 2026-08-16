import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Cache local das OPs em aberto — sempre atualizada por cima (upsert) a
/// partir do que a última consulta online trouxe, nunca cresce sem limite.
/// Serve tanto a Onduladeira (tudo aberto) quanto a Conversão (que filtra
/// esse mesmo cache localmente por prefixo 802 — ver plano técnico, modo
/// offline).
class LocalOrdens extends Table {
  TextColumn get id => text()();
  TextColumn get numeroOp => text()();
  IntColumn get quantidadePedida => integer()();
  DateTimeColumn get dataPedido => dateTime()();
  TextColumn get status => text()();
  TextColumn get codigoFt => text()();
  IntColumn get qpPadrao => integer()();
  TextColumn get clienteNome => text()();
  RealColumn get composicaoEspessuraMm => real()();
  IntColumn get pacotesPorCamada => integer().nullable()();
  IntColumn get pecasPorPacote => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Paletes em cache: `sincronizado = true` espelha o que já está no
/// servidor; `sincronizado = false` é um apontamento feito offline,
/// aguardando envio (o `id` nesse caso é um uuid gerado no aparelho, nunca
/// um número sequencial definitivo — esse só é atribuído pelo servidor no
/// momento da sincronização, pra evitar dois aparelhos offline calcularem
/// o mesmo número).
class LocalPaletes extends Table {
  TextColumn get id => text()();
  TextColumn get ordemProducaoId => text()();
  IntColumn get numeroSequencial => integer().nullable()();
  RealColumn get alturaMedidaMm => real().nullable()();
  IntColumn get camadas => integer().nullable()();
  IntColumn get quantidadeCalculada => integer()();
  TextColumn get tipoChapa => text()();
  TextColumn get setorOrigem => text()();
  TextColumn get responsavelId => text()();
  DateTimeColumn get dataHora => dateTime()();
  IntColumn get quantidadeReprovada =>
      integer().withDefault(const Constant(0))();
  IntColumn get saldoDisponivel => integer()();
  TextColumn get revisorNome => text().nullable()();
  BoolColumn get sincronizado => boolean().withDefault(const Constant(true))();
  TextColumn get erroSincronizacao => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Fila genérica (Fase 2 do modo offline) pra escritas que não precisam de
/// leitura fresca do servidor pra serem seguras offline: lançar refugo,
/// pedir revisão de qualidade, e os cadastros base do Admin. `payload` é
/// json com os mesmos campos que o repositório mandaria pro Supabase.
/// Ações que dependem do saldo *atual* de um palete (segregar, resolver,
/// corrigir, excluir) ficam de fora — arriscariam debitar em cima de dado
/// desatualizado (ver plano técnico, 9.12).
class PendingOperations extends Table {
  TextColumn get id => text()();
  TextColumn get tipo => text()();
  TextColumn get payload => text()();
  DateTimeColumn get criadoEm => dateTime()();
  TextColumn get erro => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalOrdens, LocalPaletes, PendingOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_abrirConexao());
  AppDatabase.paraTeste(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(pendingOperations);
      }
    },
  );

  /// Grava/atualiza as OPs recebidas. Se `podarAusentes`, remove do cache
  /// qualquer OP que não veio nesse lote (ela deixou de estar aberta) —
  /// só quem busca a lista completa (Onduladeira) faz isso; a busca
  /// filtrada da Conversão só complementa, nunca poda.
  Future<void> upsertOrdens(
    List<LocalOrdensCompanion> linhas, {
    bool podarAusentes = false,
  }) async {
    await transaction(() async {
      if (podarAusentes) {
        final idsAtuais = linhas.map((l) => l.id.value).toSet();
        await (delete(localOrdens)..where(
              (t) => idsAtuais.isEmpty
                  ? const Constant(true)
                  : t.id.isNotIn(idsAtuais),
            ))
            .go();
      }
      for (final linha in linhas) {
        await into(localOrdens).insertOnConflictUpdate(linha);
      }
    });
  }

  Future<List<LocalOrden>> listarOrdensCache() => select(localOrdens).get();

  Future<void> upsertPaletesSincronizados(
    String ordemId,
    List<LocalPaletesCompanion> linhas,
  ) async {
    await transaction(() async {
      await (delete(localPaletes)..where(
            (t) =>
                t.ordemProducaoId.equals(ordemId) & t.sincronizado.equals(true),
          ))
          .go();
      for (final linha in linhas) {
        await into(localPaletes).insertOnConflictUpdate(linha);
      }
    });
  }

  Future<List<LocalPalete>> listarPaletesCache(String ordemId) {
    return (select(
      localPaletes,
    )..where((t) => t.ordemProducaoId.equals(ordemId))).get();
  }

  Future<void> inserirPendente(LocalPaletesCompanion linha) {
    return into(localPaletes).insert(linha);
  }

  Future<List<LocalPalete>> listarPendentes() {
    return (select(
      localPaletes,
    )..where((t) => t.sincronizado.equals(false))).get();
  }

  Future<void> removerPalete(String id) {
    return (delete(localPaletes)..where((t) => t.id.equals(id))).go();
  }

  Future<void> marcarErroSincronizacao(String id, String? erro) {
    return (update(localPaletes)..where((t) => t.id.equals(id))).write(
      LocalPaletesCompanion(erroSincronizacao: Value(erro)),
    );
  }

  Future<void> inserirOperacaoPendente({
    required String id,
    required String tipo,
    required String payload,
  }) {
    return into(pendingOperations).insert(
      PendingOperationsCompanion.insert(
        id: id,
        tipo: tipo,
        payload: payload,
        criadoEm: DateTime.now(),
      ),
    );
  }

  /// Conveniência: json-encoda o mapa antes de gravar, pra quem está
  /// chamando não precisar importar dart:convert só por isso.
  Future<void> inserirOperacaoPendenteMap({
    required String id,
    required String tipo,
    required Map<String, dynamic> dados,
  }) {
    return inserirOperacaoPendente(
      id: id,
      tipo: tipo,
      payload: jsonEncode(dados),
    );
  }

  Future<List<PendingOperation>> listarOperacoesPendentes() =>
      select(pendingOperations).get();

  /// Consulta reativa — a tela de Pendências atualiza sozinha conforme a
  /// sincronização vai processando a fila, sem precisar de refresh manual.
  Stream<List<PendingOperation>> observarOperacoesPendentes() =>
      select(pendingOperations).watch();

  Stream<List<LocalPalete>> observarPaletesPendentes() => (select(
    localPaletes,
  )..where((t) => t.sincronizado.equals(false))).watch();

  Future<void> removerOperacaoPendente(String id) {
    return (delete(pendingOperations)..where((t) => t.id.equals(id))).go();
  }

  Future<void> marcarErroOperacao(String id, String? erro) {
    return (update(pendingOperations)..where((t) => t.id.equals(id))).write(
      PendingOperationsCompanion(erro: Value(erro)),
    );
  }
}

QueryExecutor _abrirConexao() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final arquivo = File(p.join(dir.path, 'controle_paletes.sqlite'));
    return NativeDatabase.createInBackground(arquivo);
  });
}

/// Uma instância só, viva enquanto o app roda — mantém a conexão SQLite
/// aberta em vez de reabrir a cada rebuild.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
