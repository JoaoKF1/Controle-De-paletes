// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalOrdensTable extends LocalOrdens
    with TableInfo<$LocalOrdensTable, LocalOrden> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOrdensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroOpMeta = const VerificationMeta(
    'numeroOp',
  );
  @override
  late final GeneratedColumn<String> numeroOp = GeneratedColumn<String>(
    'numero_op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantidadePedidaMeta = const VerificationMeta(
    'quantidadePedida',
  );
  @override
  late final GeneratedColumn<int> quantidadePedida = GeneratedColumn<int>(
    'quantidade_pedida',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataPedidoMeta = const VerificationMeta(
    'dataPedido',
  );
  @override
  late final GeneratedColumn<DateTime> dataPedido = GeneratedColumn<DateTime>(
    'data_pedido',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoFtMeta = const VerificationMeta(
    'codigoFt',
  );
  @override
  late final GeneratedColumn<String> codigoFt = GeneratedColumn<String>(
    'codigo_ft',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qpPadraoMeta = const VerificationMeta(
    'qpPadrao',
  );
  @override
  late final GeneratedColumn<int> qpPadrao = GeneratedColumn<int>(
    'qp_padrao',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clienteNomeMeta = const VerificationMeta(
    'clienteNome',
  );
  @override
  late final GeneratedColumn<String> clienteNome = GeneratedColumn<String>(
    'cliente_nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _composicaoEspessuraMmMeta =
      const VerificationMeta('composicaoEspessuraMm');
  @override
  late final GeneratedColumn<double> composicaoEspessuraMm =
      GeneratedColumn<double>(
        'composicao_espessura_mm',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pacotesPorCamadaMeta = const VerificationMeta(
    'pacotesPorCamada',
  );
  @override
  late final GeneratedColumn<int> pacotesPorCamada = GeneratedColumn<int>(
    'pacotes_por_camada',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pecasPorPacoteMeta = const VerificationMeta(
    'pecasPorPacote',
  );
  @override
  late final GeneratedColumn<int> pecasPorPacote = GeneratedColumn<int>(
    'pecas_por_pacote',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    numeroOp,
    quantidadePedida,
    dataPedido,
    status,
    codigoFt,
    qpPadrao,
    clienteNome,
    composicaoEspessuraMm,
    pacotesPorCamada,
    pecasPorPacote,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_ordens';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOrden> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('numero_op')) {
      context.handle(
        _numeroOpMeta,
        numeroOp.isAcceptableOrUnknown(data['numero_op']!, _numeroOpMeta),
      );
    } else if (isInserting) {
      context.missing(_numeroOpMeta);
    }
    if (data.containsKey('quantidade_pedida')) {
      context.handle(
        _quantidadePedidaMeta,
        quantidadePedida.isAcceptableOrUnknown(
          data['quantidade_pedida']!,
          _quantidadePedidaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantidadePedidaMeta);
    }
    if (data.containsKey('data_pedido')) {
      context.handle(
        _dataPedidoMeta,
        dataPedido.isAcceptableOrUnknown(data['data_pedido']!, _dataPedidoMeta),
      );
    } else if (isInserting) {
      context.missing(_dataPedidoMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('codigo_ft')) {
      context.handle(
        _codigoFtMeta,
        codigoFt.isAcceptableOrUnknown(data['codigo_ft']!, _codigoFtMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoFtMeta);
    }
    if (data.containsKey('qp_padrao')) {
      context.handle(
        _qpPadraoMeta,
        qpPadrao.isAcceptableOrUnknown(data['qp_padrao']!, _qpPadraoMeta),
      );
    } else if (isInserting) {
      context.missing(_qpPadraoMeta);
    }
    if (data.containsKey('cliente_nome')) {
      context.handle(
        _clienteNomeMeta,
        clienteNome.isAcceptableOrUnknown(
          data['cliente_nome']!,
          _clienteNomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clienteNomeMeta);
    }
    if (data.containsKey('composicao_espessura_mm')) {
      context.handle(
        _composicaoEspessuraMmMeta,
        composicaoEspessuraMm.isAcceptableOrUnknown(
          data['composicao_espessura_mm']!,
          _composicaoEspessuraMmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_composicaoEspessuraMmMeta);
    }
    if (data.containsKey('pacotes_por_camada')) {
      context.handle(
        _pacotesPorCamadaMeta,
        pacotesPorCamada.isAcceptableOrUnknown(
          data['pacotes_por_camada']!,
          _pacotesPorCamadaMeta,
        ),
      );
    }
    if (data.containsKey('pecas_por_pacote')) {
      context.handle(
        _pecasPorPacoteMeta,
        pecasPorPacote.isAcceptableOrUnknown(
          data['pecas_por_pacote']!,
          _pecasPorPacoteMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalOrden map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOrden(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      numeroOp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero_op'],
      )!,
      quantidadePedida: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantidade_pedida'],
      )!,
      dataPedido: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_pedido'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      codigoFt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_ft'],
      )!,
      qpPadrao: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qp_padrao'],
      )!,
      clienteNome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cliente_nome'],
      )!,
      composicaoEspessuraMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}composicao_espessura_mm'],
      )!,
      pacotesPorCamada: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pacotes_por_camada'],
      ),
      pecasPorPacote: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pecas_por_pacote'],
      ),
    );
  }

  @override
  $LocalOrdensTable createAlias(String alias) {
    return $LocalOrdensTable(attachedDatabase, alias);
  }
}

class LocalOrden extends DataClass implements Insertable<LocalOrden> {
  final String id;
  final String numeroOp;
  final int quantidadePedida;
  final DateTime dataPedido;
  final String status;
  final String codigoFt;
  final int qpPadrao;
  final String clienteNome;
  final double composicaoEspessuraMm;
  final int? pacotesPorCamada;
  final int? pecasPorPacote;
  const LocalOrden({
    required this.id,
    required this.numeroOp,
    required this.quantidadePedida,
    required this.dataPedido,
    required this.status,
    required this.codigoFt,
    required this.qpPadrao,
    required this.clienteNome,
    required this.composicaoEspessuraMm,
    this.pacotesPorCamada,
    this.pecasPorPacote,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['numero_op'] = Variable<String>(numeroOp);
    map['quantidade_pedida'] = Variable<int>(quantidadePedida);
    map['data_pedido'] = Variable<DateTime>(dataPedido);
    map['status'] = Variable<String>(status);
    map['codigo_ft'] = Variable<String>(codigoFt);
    map['qp_padrao'] = Variable<int>(qpPadrao);
    map['cliente_nome'] = Variable<String>(clienteNome);
    map['composicao_espessura_mm'] = Variable<double>(composicaoEspessuraMm);
    if (!nullToAbsent || pacotesPorCamada != null) {
      map['pacotes_por_camada'] = Variable<int>(pacotesPorCamada);
    }
    if (!nullToAbsent || pecasPorPacote != null) {
      map['pecas_por_pacote'] = Variable<int>(pecasPorPacote);
    }
    return map;
  }

  LocalOrdensCompanion toCompanion(bool nullToAbsent) {
    return LocalOrdensCompanion(
      id: Value(id),
      numeroOp: Value(numeroOp),
      quantidadePedida: Value(quantidadePedida),
      dataPedido: Value(dataPedido),
      status: Value(status),
      codigoFt: Value(codigoFt),
      qpPadrao: Value(qpPadrao),
      clienteNome: Value(clienteNome),
      composicaoEspessuraMm: Value(composicaoEspessuraMm),
      pacotesPorCamada: pacotesPorCamada == null && nullToAbsent
          ? const Value.absent()
          : Value(pacotesPorCamada),
      pecasPorPacote: pecasPorPacote == null && nullToAbsent
          ? const Value.absent()
          : Value(pecasPorPacote),
    );
  }

  factory LocalOrden.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOrden(
      id: serializer.fromJson<String>(json['id']),
      numeroOp: serializer.fromJson<String>(json['numeroOp']),
      quantidadePedida: serializer.fromJson<int>(json['quantidadePedida']),
      dataPedido: serializer.fromJson<DateTime>(json['dataPedido']),
      status: serializer.fromJson<String>(json['status']),
      codigoFt: serializer.fromJson<String>(json['codigoFt']),
      qpPadrao: serializer.fromJson<int>(json['qpPadrao']),
      clienteNome: serializer.fromJson<String>(json['clienteNome']),
      composicaoEspessuraMm: serializer.fromJson<double>(
        json['composicaoEspessuraMm'],
      ),
      pacotesPorCamada: serializer.fromJson<int?>(json['pacotesPorCamada']),
      pecasPorPacote: serializer.fromJson<int?>(json['pecasPorPacote']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'numeroOp': serializer.toJson<String>(numeroOp),
      'quantidadePedida': serializer.toJson<int>(quantidadePedida),
      'dataPedido': serializer.toJson<DateTime>(dataPedido),
      'status': serializer.toJson<String>(status),
      'codigoFt': serializer.toJson<String>(codigoFt),
      'qpPadrao': serializer.toJson<int>(qpPadrao),
      'clienteNome': serializer.toJson<String>(clienteNome),
      'composicaoEspessuraMm': serializer.toJson<double>(composicaoEspessuraMm),
      'pacotesPorCamada': serializer.toJson<int?>(pacotesPorCamada),
      'pecasPorPacote': serializer.toJson<int?>(pecasPorPacote),
    };
  }

  LocalOrden copyWith({
    String? id,
    String? numeroOp,
    int? quantidadePedida,
    DateTime? dataPedido,
    String? status,
    String? codigoFt,
    int? qpPadrao,
    String? clienteNome,
    double? composicaoEspessuraMm,
    Value<int?> pacotesPorCamada = const Value.absent(),
    Value<int?> pecasPorPacote = const Value.absent(),
  }) => LocalOrden(
    id: id ?? this.id,
    numeroOp: numeroOp ?? this.numeroOp,
    quantidadePedida: quantidadePedida ?? this.quantidadePedida,
    dataPedido: dataPedido ?? this.dataPedido,
    status: status ?? this.status,
    codigoFt: codigoFt ?? this.codigoFt,
    qpPadrao: qpPadrao ?? this.qpPadrao,
    clienteNome: clienteNome ?? this.clienteNome,
    composicaoEspessuraMm: composicaoEspessuraMm ?? this.composicaoEspessuraMm,
    pacotesPorCamada: pacotesPorCamada.present
        ? pacotesPorCamada.value
        : this.pacotesPorCamada,
    pecasPorPacote: pecasPorPacote.present
        ? pecasPorPacote.value
        : this.pecasPorPacote,
  );
  LocalOrden copyWithCompanion(LocalOrdensCompanion data) {
    return LocalOrden(
      id: data.id.present ? data.id.value : this.id,
      numeroOp: data.numeroOp.present ? data.numeroOp.value : this.numeroOp,
      quantidadePedida: data.quantidadePedida.present
          ? data.quantidadePedida.value
          : this.quantidadePedida,
      dataPedido: data.dataPedido.present
          ? data.dataPedido.value
          : this.dataPedido,
      status: data.status.present ? data.status.value : this.status,
      codigoFt: data.codigoFt.present ? data.codigoFt.value : this.codigoFt,
      qpPadrao: data.qpPadrao.present ? data.qpPadrao.value : this.qpPadrao,
      clienteNome: data.clienteNome.present
          ? data.clienteNome.value
          : this.clienteNome,
      composicaoEspessuraMm: data.composicaoEspessuraMm.present
          ? data.composicaoEspessuraMm.value
          : this.composicaoEspessuraMm,
      pacotesPorCamada: data.pacotesPorCamada.present
          ? data.pacotesPorCamada.value
          : this.pacotesPorCamada,
      pecasPorPacote: data.pecasPorPacote.present
          ? data.pecasPorPacote.value
          : this.pecasPorPacote,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrden(')
          ..write('id: $id, ')
          ..write('numeroOp: $numeroOp, ')
          ..write('quantidadePedida: $quantidadePedida, ')
          ..write('dataPedido: $dataPedido, ')
          ..write('status: $status, ')
          ..write('codigoFt: $codigoFt, ')
          ..write('qpPadrao: $qpPadrao, ')
          ..write('clienteNome: $clienteNome, ')
          ..write('composicaoEspessuraMm: $composicaoEspessuraMm, ')
          ..write('pacotesPorCamada: $pacotesPorCamada, ')
          ..write('pecasPorPacote: $pecasPorPacote')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    numeroOp,
    quantidadePedida,
    dataPedido,
    status,
    codigoFt,
    qpPadrao,
    clienteNome,
    composicaoEspessuraMm,
    pacotesPorCamada,
    pecasPorPacote,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrden &&
          other.id == this.id &&
          other.numeroOp == this.numeroOp &&
          other.quantidadePedida == this.quantidadePedida &&
          other.dataPedido == this.dataPedido &&
          other.status == this.status &&
          other.codigoFt == this.codigoFt &&
          other.qpPadrao == this.qpPadrao &&
          other.clienteNome == this.clienteNome &&
          other.composicaoEspessuraMm == this.composicaoEspessuraMm &&
          other.pacotesPorCamada == this.pacotesPorCamada &&
          other.pecasPorPacote == this.pecasPorPacote);
}

class LocalOrdensCompanion extends UpdateCompanion<LocalOrden> {
  final Value<String> id;
  final Value<String> numeroOp;
  final Value<int> quantidadePedida;
  final Value<DateTime> dataPedido;
  final Value<String> status;
  final Value<String> codigoFt;
  final Value<int> qpPadrao;
  final Value<String> clienteNome;
  final Value<double> composicaoEspessuraMm;
  final Value<int?> pacotesPorCamada;
  final Value<int?> pecasPorPacote;
  final Value<int> rowid;
  const LocalOrdensCompanion({
    this.id = const Value.absent(),
    this.numeroOp = const Value.absent(),
    this.quantidadePedida = const Value.absent(),
    this.dataPedido = const Value.absent(),
    this.status = const Value.absent(),
    this.codigoFt = const Value.absent(),
    this.qpPadrao = const Value.absent(),
    this.clienteNome = const Value.absent(),
    this.composicaoEspessuraMm = const Value.absent(),
    this.pacotesPorCamada = const Value.absent(),
    this.pecasPorPacote = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOrdensCompanion.insert({
    required String id,
    required String numeroOp,
    required int quantidadePedida,
    required DateTime dataPedido,
    required String status,
    required String codigoFt,
    required int qpPadrao,
    required String clienteNome,
    required double composicaoEspessuraMm,
    this.pacotesPorCamada = const Value.absent(),
    this.pecasPorPacote = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       numeroOp = Value(numeroOp),
       quantidadePedida = Value(quantidadePedida),
       dataPedido = Value(dataPedido),
       status = Value(status),
       codigoFt = Value(codigoFt),
       qpPadrao = Value(qpPadrao),
       clienteNome = Value(clienteNome),
       composicaoEspessuraMm = Value(composicaoEspessuraMm);
  static Insertable<LocalOrden> custom({
    Expression<String>? id,
    Expression<String>? numeroOp,
    Expression<int>? quantidadePedida,
    Expression<DateTime>? dataPedido,
    Expression<String>? status,
    Expression<String>? codigoFt,
    Expression<int>? qpPadrao,
    Expression<String>? clienteNome,
    Expression<double>? composicaoEspessuraMm,
    Expression<int>? pacotesPorCamada,
    Expression<int>? pecasPorPacote,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (numeroOp != null) 'numero_op': numeroOp,
      if (quantidadePedida != null) 'quantidade_pedida': quantidadePedida,
      if (dataPedido != null) 'data_pedido': dataPedido,
      if (status != null) 'status': status,
      if (codigoFt != null) 'codigo_ft': codigoFt,
      if (qpPadrao != null) 'qp_padrao': qpPadrao,
      if (clienteNome != null) 'cliente_nome': clienteNome,
      if (composicaoEspessuraMm != null)
        'composicao_espessura_mm': composicaoEspessuraMm,
      if (pacotesPorCamada != null) 'pacotes_por_camada': pacotesPorCamada,
      if (pecasPorPacote != null) 'pecas_por_pacote': pecasPorPacote,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOrdensCompanion copyWith({
    Value<String>? id,
    Value<String>? numeroOp,
    Value<int>? quantidadePedida,
    Value<DateTime>? dataPedido,
    Value<String>? status,
    Value<String>? codigoFt,
    Value<int>? qpPadrao,
    Value<String>? clienteNome,
    Value<double>? composicaoEspessuraMm,
    Value<int?>? pacotesPorCamada,
    Value<int?>? pecasPorPacote,
    Value<int>? rowid,
  }) {
    return LocalOrdensCompanion(
      id: id ?? this.id,
      numeroOp: numeroOp ?? this.numeroOp,
      quantidadePedida: quantidadePedida ?? this.quantidadePedida,
      dataPedido: dataPedido ?? this.dataPedido,
      status: status ?? this.status,
      codigoFt: codigoFt ?? this.codigoFt,
      qpPadrao: qpPadrao ?? this.qpPadrao,
      clienteNome: clienteNome ?? this.clienteNome,
      composicaoEspessuraMm:
          composicaoEspessuraMm ?? this.composicaoEspessuraMm,
      pacotesPorCamada: pacotesPorCamada ?? this.pacotesPorCamada,
      pecasPorPacote: pecasPorPacote ?? this.pecasPorPacote,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (numeroOp.present) {
      map['numero_op'] = Variable<String>(numeroOp.value);
    }
    if (quantidadePedida.present) {
      map['quantidade_pedida'] = Variable<int>(quantidadePedida.value);
    }
    if (dataPedido.present) {
      map['data_pedido'] = Variable<DateTime>(dataPedido.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (codigoFt.present) {
      map['codigo_ft'] = Variable<String>(codigoFt.value);
    }
    if (qpPadrao.present) {
      map['qp_padrao'] = Variable<int>(qpPadrao.value);
    }
    if (clienteNome.present) {
      map['cliente_nome'] = Variable<String>(clienteNome.value);
    }
    if (composicaoEspessuraMm.present) {
      map['composicao_espessura_mm'] = Variable<double>(
        composicaoEspessuraMm.value,
      );
    }
    if (pacotesPorCamada.present) {
      map['pacotes_por_camada'] = Variable<int>(pacotesPorCamada.value);
    }
    if (pecasPorPacote.present) {
      map['pecas_por_pacote'] = Variable<int>(pecasPorPacote.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrdensCompanion(')
          ..write('id: $id, ')
          ..write('numeroOp: $numeroOp, ')
          ..write('quantidadePedida: $quantidadePedida, ')
          ..write('dataPedido: $dataPedido, ')
          ..write('status: $status, ')
          ..write('codigoFt: $codigoFt, ')
          ..write('qpPadrao: $qpPadrao, ')
          ..write('clienteNome: $clienteNome, ')
          ..write('composicaoEspessuraMm: $composicaoEspessuraMm, ')
          ..write('pacotesPorCamada: $pacotesPorCamada, ')
          ..write('pecasPorPacote: $pecasPorPacote, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPaletesTable extends LocalPaletes
    with TableInfo<$LocalPaletesTable, LocalPalete> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPaletesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordemProducaoIdMeta = const VerificationMeta(
    'ordemProducaoId',
  );
  @override
  late final GeneratedColumn<String> ordemProducaoId = GeneratedColumn<String>(
    'ordem_producao_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroSequencialMeta = const VerificationMeta(
    'numeroSequencial',
  );
  @override
  late final GeneratedColumn<int> numeroSequencial = GeneratedColumn<int>(
    'numero_sequencial',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alturaMedidaMmMeta = const VerificationMeta(
    'alturaMedidaMm',
  );
  @override
  late final GeneratedColumn<double> alturaMedidaMm = GeneratedColumn<double>(
    'altura_medida_mm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _camadasMeta = const VerificationMeta(
    'camadas',
  );
  @override
  late final GeneratedColumn<int> camadas = GeneratedColumn<int>(
    'camadas',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantidadeCalculadaMeta =
      const VerificationMeta('quantidadeCalculada');
  @override
  late final GeneratedColumn<int> quantidadeCalculada = GeneratedColumn<int>(
    'quantidade_calculada',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoChapaMeta = const VerificationMeta(
    'tipoChapa',
  );
  @override
  late final GeneratedColumn<String> tipoChapa = GeneratedColumn<String>(
    'tipo_chapa',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setorOrigemMeta = const VerificationMeta(
    'setorOrigem',
  );
  @override
  late final GeneratedColumn<String> setorOrigem = GeneratedColumn<String>(
    'setor_origem',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responsavelIdMeta = const VerificationMeta(
    'responsavelId',
  );
  @override
  late final GeneratedColumn<String> responsavelId = GeneratedColumn<String>(
    'responsavel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataHoraMeta = const VerificationMeta(
    'dataHora',
  );
  @override
  late final GeneratedColumn<DateTime> dataHora = GeneratedColumn<DateTime>(
    'data_hora',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantidadeReprovadaMeta =
      const VerificationMeta('quantidadeReprovada');
  @override
  late final GeneratedColumn<int> quantidadeReprovada = GeneratedColumn<int>(
    'quantidade_reprovada',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _saldoDisponivelMeta = const VerificationMeta(
    'saldoDisponivel',
  );
  @override
  late final GeneratedColumn<int> saldoDisponivel = GeneratedColumn<int>(
    'saldo_disponivel',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisorNomeMeta = const VerificationMeta(
    'revisorNome',
  );
  @override
  late final GeneratedColumn<String> revisorNome = GeneratedColumn<String>(
    'revisor_nome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sincronizadoMeta = const VerificationMeta(
    'sincronizado',
  );
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
    'sincronizado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sincronizado" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _erroSincronizacaoMeta = const VerificationMeta(
    'erroSincronizacao',
  );
  @override
  late final GeneratedColumn<String> erroSincronizacao =
      GeneratedColumn<String>(
        'erro_sincronizacao',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ordemProducaoId,
    numeroSequencial,
    alturaMedidaMm,
    camadas,
    quantidadeCalculada,
    tipoChapa,
    setorOrigem,
    responsavelId,
    dataHora,
    quantidadeReprovada,
    saldoDisponivel,
    revisorNome,
    sincronizado,
    erroSincronizacao,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_paletes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPalete> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ordem_producao_id')) {
      context.handle(
        _ordemProducaoIdMeta,
        ordemProducaoId.isAcceptableOrUnknown(
          data['ordem_producao_id']!,
          _ordemProducaoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ordemProducaoIdMeta);
    }
    if (data.containsKey('numero_sequencial')) {
      context.handle(
        _numeroSequencialMeta,
        numeroSequencial.isAcceptableOrUnknown(
          data['numero_sequencial']!,
          _numeroSequencialMeta,
        ),
      );
    }
    if (data.containsKey('altura_medida_mm')) {
      context.handle(
        _alturaMedidaMmMeta,
        alturaMedidaMm.isAcceptableOrUnknown(
          data['altura_medida_mm']!,
          _alturaMedidaMmMeta,
        ),
      );
    }
    if (data.containsKey('camadas')) {
      context.handle(
        _camadasMeta,
        camadas.isAcceptableOrUnknown(data['camadas']!, _camadasMeta),
      );
    }
    if (data.containsKey('quantidade_calculada')) {
      context.handle(
        _quantidadeCalculadaMeta,
        quantidadeCalculada.isAcceptableOrUnknown(
          data['quantidade_calculada']!,
          _quantidadeCalculadaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantidadeCalculadaMeta);
    }
    if (data.containsKey('tipo_chapa')) {
      context.handle(
        _tipoChapaMeta,
        tipoChapa.isAcceptableOrUnknown(data['tipo_chapa']!, _tipoChapaMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoChapaMeta);
    }
    if (data.containsKey('setor_origem')) {
      context.handle(
        _setorOrigemMeta,
        setorOrigem.isAcceptableOrUnknown(
          data['setor_origem']!,
          _setorOrigemMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_setorOrigemMeta);
    }
    if (data.containsKey('responsavel_id')) {
      context.handle(
        _responsavelIdMeta,
        responsavelId.isAcceptableOrUnknown(
          data['responsavel_id']!,
          _responsavelIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responsavelIdMeta);
    }
    if (data.containsKey('data_hora')) {
      context.handle(
        _dataHoraMeta,
        dataHora.isAcceptableOrUnknown(data['data_hora']!, _dataHoraMeta),
      );
    } else if (isInserting) {
      context.missing(_dataHoraMeta);
    }
    if (data.containsKey('quantidade_reprovada')) {
      context.handle(
        _quantidadeReprovadaMeta,
        quantidadeReprovada.isAcceptableOrUnknown(
          data['quantidade_reprovada']!,
          _quantidadeReprovadaMeta,
        ),
      );
    }
    if (data.containsKey('saldo_disponivel')) {
      context.handle(
        _saldoDisponivelMeta,
        saldoDisponivel.isAcceptableOrUnknown(
          data['saldo_disponivel']!,
          _saldoDisponivelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_saldoDisponivelMeta);
    }
    if (data.containsKey('revisor_nome')) {
      context.handle(
        _revisorNomeMeta,
        revisorNome.isAcceptableOrUnknown(
          data['revisor_nome']!,
          _revisorNomeMeta,
        ),
      );
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
        _sincronizadoMeta,
        sincronizado.isAcceptableOrUnknown(
          data['sincronizado']!,
          _sincronizadoMeta,
        ),
      );
    }
    if (data.containsKey('erro_sincronizacao')) {
      context.handle(
        _erroSincronizacaoMeta,
        erroSincronizacao.isAcceptableOrUnknown(
          data['erro_sincronizacao']!,
          _erroSincronizacaoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPalete map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPalete(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ordemProducaoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ordem_producao_id'],
      )!,
      numeroSequencial: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}numero_sequencial'],
      ),
      alturaMedidaMm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altura_medida_mm'],
      ),
      camadas: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}camadas'],
      ),
      quantidadeCalculada: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantidade_calculada'],
      )!,
      tipoChapa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_chapa'],
      )!,
      setorOrigem: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setor_origem'],
      )!,
      responsavelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}responsavel_id'],
      )!,
      dataHora: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_hora'],
      )!,
      quantidadeReprovada: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantidade_reprovada'],
      )!,
      saldoDisponivel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saldo_disponivel'],
      )!,
      revisorNome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revisor_nome'],
      ),
      sincronizado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sincronizado'],
      )!,
      erroSincronizacao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}erro_sincronizacao'],
      ),
    );
  }

  @override
  $LocalPaletesTable createAlias(String alias) {
    return $LocalPaletesTable(attachedDatabase, alias);
  }
}

class LocalPalete extends DataClass implements Insertable<LocalPalete> {
  final String id;
  final String ordemProducaoId;
  final int? numeroSequencial;
  final double? alturaMedidaMm;
  final int? camadas;
  final int quantidadeCalculada;
  final String tipoChapa;
  final String setorOrigem;
  final String responsavelId;
  final DateTime dataHora;
  final int quantidadeReprovada;
  final int saldoDisponivel;
  final String? revisorNome;
  final bool sincronizado;
  final String? erroSincronizacao;
  const LocalPalete({
    required this.id,
    required this.ordemProducaoId,
    this.numeroSequencial,
    this.alturaMedidaMm,
    this.camadas,
    required this.quantidadeCalculada,
    required this.tipoChapa,
    required this.setorOrigem,
    required this.responsavelId,
    required this.dataHora,
    required this.quantidadeReprovada,
    required this.saldoDisponivel,
    this.revisorNome,
    required this.sincronizado,
    this.erroSincronizacao,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ordem_producao_id'] = Variable<String>(ordemProducaoId);
    if (!nullToAbsent || numeroSequencial != null) {
      map['numero_sequencial'] = Variable<int>(numeroSequencial);
    }
    if (!nullToAbsent || alturaMedidaMm != null) {
      map['altura_medida_mm'] = Variable<double>(alturaMedidaMm);
    }
    if (!nullToAbsent || camadas != null) {
      map['camadas'] = Variable<int>(camadas);
    }
    map['quantidade_calculada'] = Variable<int>(quantidadeCalculada);
    map['tipo_chapa'] = Variable<String>(tipoChapa);
    map['setor_origem'] = Variable<String>(setorOrigem);
    map['responsavel_id'] = Variable<String>(responsavelId);
    map['data_hora'] = Variable<DateTime>(dataHora);
    map['quantidade_reprovada'] = Variable<int>(quantidadeReprovada);
    map['saldo_disponivel'] = Variable<int>(saldoDisponivel);
    if (!nullToAbsent || revisorNome != null) {
      map['revisor_nome'] = Variable<String>(revisorNome);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    if (!nullToAbsent || erroSincronizacao != null) {
      map['erro_sincronizacao'] = Variable<String>(erroSincronizacao);
    }
    return map;
  }

  LocalPaletesCompanion toCompanion(bool nullToAbsent) {
    return LocalPaletesCompanion(
      id: Value(id),
      ordemProducaoId: Value(ordemProducaoId),
      numeroSequencial: numeroSequencial == null && nullToAbsent
          ? const Value.absent()
          : Value(numeroSequencial),
      alturaMedidaMm: alturaMedidaMm == null && nullToAbsent
          ? const Value.absent()
          : Value(alturaMedidaMm),
      camadas: camadas == null && nullToAbsent
          ? const Value.absent()
          : Value(camadas),
      quantidadeCalculada: Value(quantidadeCalculada),
      tipoChapa: Value(tipoChapa),
      setorOrigem: Value(setorOrigem),
      responsavelId: Value(responsavelId),
      dataHora: Value(dataHora),
      quantidadeReprovada: Value(quantidadeReprovada),
      saldoDisponivel: Value(saldoDisponivel),
      revisorNome: revisorNome == null && nullToAbsent
          ? const Value.absent()
          : Value(revisorNome),
      sincronizado: Value(sincronizado),
      erroSincronizacao: erroSincronizacao == null && nullToAbsent
          ? const Value.absent()
          : Value(erroSincronizacao),
    );
  }

  factory LocalPalete.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPalete(
      id: serializer.fromJson<String>(json['id']),
      ordemProducaoId: serializer.fromJson<String>(json['ordemProducaoId']),
      numeroSequencial: serializer.fromJson<int?>(json['numeroSequencial']),
      alturaMedidaMm: serializer.fromJson<double?>(json['alturaMedidaMm']),
      camadas: serializer.fromJson<int?>(json['camadas']),
      quantidadeCalculada: serializer.fromJson<int>(
        json['quantidadeCalculada'],
      ),
      tipoChapa: serializer.fromJson<String>(json['tipoChapa']),
      setorOrigem: serializer.fromJson<String>(json['setorOrigem']),
      responsavelId: serializer.fromJson<String>(json['responsavelId']),
      dataHora: serializer.fromJson<DateTime>(json['dataHora']),
      quantidadeReprovada: serializer.fromJson<int>(
        json['quantidadeReprovada'],
      ),
      saldoDisponivel: serializer.fromJson<int>(json['saldoDisponivel']),
      revisorNome: serializer.fromJson<String?>(json['revisorNome']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
      erroSincronizacao: serializer.fromJson<String?>(
        json['erroSincronizacao'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ordemProducaoId': serializer.toJson<String>(ordemProducaoId),
      'numeroSequencial': serializer.toJson<int?>(numeroSequencial),
      'alturaMedidaMm': serializer.toJson<double?>(alturaMedidaMm),
      'camadas': serializer.toJson<int?>(camadas),
      'quantidadeCalculada': serializer.toJson<int>(quantidadeCalculada),
      'tipoChapa': serializer.toJson<String>(tipoChapa),
      'setorOrigem': serializer.toJson<String>(setorOrigem),
      'responsavelId': serializer.toJson<String>(responsavelId),
      'dataHora': serializer.toJson<DateTime>(dataHora),
      'quantidadeReprovada': serializer.toJson<int>(quantidadeReprovada),
      'saldoDisponivel': serializer.toJson<int>(saldoDisponivel),
      'revisorNome': serializer.toJson<String?>(revisorNome),
      'sincronizado': serializer.toJson<bool>(sincronizado),
      'erroSincronizacao': serializer.toJson<String?>(erroSincronizacao),
    };
  }

  LocalPalete copyWith({
    String? id,
    String? ordemProducaoId,
    Value<int?> numeroSequencial = const Value.absent(),
    Value<double?> alturaMedidaMm = const Value.absent(),
    Value<int?> camadas = const Value.absent(),
    int? quantidadeCalculada,
    String? tipoChapa,
    String? setorOrigem,
    String? responsavelId,
    DateTime? dataHora,
    int? quantidadeReprovada,
    int? saldoDisponivel,
    Value<String?> revisorNome = const Value.absent(),
    bool? sincronizado,
    Value<String?> erroSincronizacao = const Value.absent(),
  }) => LocalPalete(
    id: id ?? this.id,
    ordemProducaoId: ordemProducaoId ?? this.ordemProducaoId,
    numeroSequencial: numeroSequencial.present
        ? numeroSequencial.value
        : this.numeroSequencial,
    alturaMedidaMm: alturaMedidaMm.present
        ? alturaMedidaMm.value
        : this.alturaMedidaMm,
    camadas: camadas.present ? camadas.value : this.camadas,
    quantidadeCalculada: quantidadeCalculada ?? this.quantidadeCalculada,
    tipoChapa: tipoChapa ?? this.tipoChapa,
    setorOrigem: setorOrigem ?? this.setorOrigem,
    responsavelId: responsavelId ?? this.responsavelId,
    dataHora: dataHora ?? this.dataHora,
    quantidadeReprovada: quantidadeReprovada ?? this.quantidadeReprovada,
    saldoDisponivel: saldoDisponivel ?? this.saldoDisponivel,
    revisorNome: revisorNome.present ? revisorNome.value : this.revisorNome,
    sincronizado: sincronizado ?? this.sincronizado,
    erroSincronizacao: erroSincronizacao.present
        ? erroSincronizacao.value
        : this.erroSincronizacao,
  );
  LocalPalete copyWithCompanion(LocalPaletesCompanion data) {
    return LocalPalete(
      id: data.id.present ? data.id.value : this.id,
      ordemProducaoId: data.ordemProducaoId.present
          ? data.ordemProducaoId.value
          : this.ordemProducaoId,
      numeroSequencial: data.numeroSequencial.present
          ? data.numeroSequencial.value
          : this.numeroSequencial,
      alturaMedidaMm: data.alturaMedidaMm.present
          ? data.alturaMedidaMm.value
          : this.alturaMedidaMm,
      camadas: data.camadas.present ? data.camadas.value : this.camadas,
      quantidadeCalculada: data.quantidadeCalculada.present
          ? data.quantidadeCalculada.value
          : this.quantidadeCalculada,
      tipoChapa: data.tipoChapa.present ? data.tipoChapa.value : this.tipoChapa,
      setorOrigem: data.setorOrigem.present
          ? data.setorOrigem.value
          : this.setorOrigem,
      responsavelId: data.responsavelId.present
          ? data.responsavelId.value
          : this.responsavelId,
      dataHora: data.dataHora.present ? data.dataHora.value : this.dataHora,
      quantidadeReprovada: data.quantidadeReprovada.present
          ? data.quantidadeReprovada.value
          : this.quantidadeReprovada,
      saldoDisponivel: data.saldoDisponivel.present
          ? data.saldoDisponivel.value
          : this.saldoDisponivel,
      revisorNome: data.revisorNome.present
          ? data.revisorNome.value
          : this.revisorNome,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      erroSincronizacao: data.erroSincronizacao.present
          ? data.erroSincronizacao.value
          : this.erroSincronizacao,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPalete(')
          ..write('id: $id, ')
          ..write('ordemProducaoId: $ordemProducaoId, ')
          ..write('numeroSequencial: $numeroSequencial, ')
          ..write('alturaMedidaMm: $alturaMedidaMm, ')
          ..write('camadas: $camadas, ')
          ..write('quantidadeCalculada: $quantidadeCalculada, ')
          ..write('tipoChapa: $tipoChapa, ')
          ..write('setorOrigem: $setorOrigem, ')
          ..write('responsavelId: $responsavelId, ')
          ..write('dataHora: $dataHora, ')
          ..write('quantidadeReprovada: $quantidadeReprovada, ')
          ..write('saldoDisponivel: $saldoDisponivel, ')
          ..write('revisorNome: $revisorNome, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('erroSincronizacao: $erroSincronizacao')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ordemProducaoId,
    numeroSequencial,
    alturaMedidaMm,
    camadas,
    quantidadeCalculada,
    tipoChapa,
    setorOrigem,
    responsavelId,
    dataHora,
    quantidadeReprovada,
    saldoDisponivel,
    revisorNome,
    sincronizado,
    erroSincronizacao,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPalete &&
          other.id == this.id &&
          other.ordemProducaoId == this.ordemProducaoId &&
          other.numeroSequencial == this.numeroSequencial &&
          other.alturaMedidaMm == this.alturaMedidaMm &&
          other.camadas == this.camadas &&
          other.quantidadeCalculada == this.quantidadeCalculada &&
          other.tipoChapa == this.tipoChapa &&
          other.setorOrigem == this.setorOrigem &&
          other.responsavelId == this.responsavelId &&
          other.dataHora == this.dataHora &&
          other.quantidadeReprovada == this.quantidadeReprovada &&
          other.saldoDisponivel == this.saldoDisponivel &&
          other.revisorNome == this.revisorNome &&
          other.sincronizado == this.sincronizado &&
          other.erroSincronizacao == this.erroSincronizacao);
}

class LocalPaletesCompanion extends UpdateCompanion<LocalPalete> {
  final Value<String> id;
  final Value<String> ordemProducaoId;
  final Value<int?> numeroSequencial;
  final Value<double?> alturaMedidaMm;
  final Value<int?> camadas;
  final Value<int> quantidadeCalculada;
  final Value<String> tipoChapa;
  final Value<String> setorOrigem;
  final Value<String> responsavelId;
  final Value<DateTime> dataHora;
  final Value<int> quantidadeReprovada;
  final Value<int> saldoDisponivel;
  final Value<String?> revisorNome;
  final Value<bool> sincronizado;
  final Value<String?> erroSincronizacao;
  final Value<int> rowid;
  const LocalPaletesCompanion({
    this.id = const Value.absent(),
    this.ordemProducaoId = const Value.absent(),
    this.numeroSequencial = const Value.absent(),
    this.alturaMedidaMm = const Value.absent(),
    this.camadas = const Value.absent(),
    this.quantidadeCalculada = const Value.absent(),
    this.tipoChapa = const Value.absent(),
    this.setorOrigem = const Value.absent(),
    this.responsavelId = const Value.absent(),
    this.dataHora = const Value.absent(),
    this.quantidadeReprovada = const Value.absent(),
    this.saldoDisponivel = const Value.absent(),
    this.revisorNome = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.erroSincronizacao = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPaletesCompanion.insert({
    required String id,
    required String ordemProducaoId,
    this.numeroSequencial = const Value.absent(),
    this.alturaMedidaMm = const Value.absent(),
    this.camadas = const Value.absent(),
    required int quantidadeCalculada,
    required String tipoChapa,
    required String setorOrigem,
    required String responsavelId,
    required DateTime dataHora,
    this.quantidadeReprovada = const Value.absent(),
    required int saldoDisponivel,
    this.revisorNome = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.erroSincronizacao = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ordemProducaoId = Value(ordemProducaoId),
       quantidadeCalculada = Value(quantidadeCalculada),
       tipoChapa = Value(tipoChapa),
       setorOrigem = Value(setorOrigem),
       responsavelId = Value(responsavelId),
       dataHora = Value(dataHora),
       saldoDisponivel = Value(saldoDisponivel);
  static Insertable<LocalPalete> custom({
    Expression<String>? id,
    Expression<String>? ordemProducaoId,
    Expression<int>? numeroSequencial,
    Expression<double>? alturaMedidaMm,
    Expression<int>? camadas,
    Expression<int>? quantidadeCalculada,
    Expression<String>? tipoChapa,
    Expression<String>? setorOrigem,
    Expression<String>? responsavelId,
    Expression<DateTime>? dataHora,
    Expression<int>? quantidadeReprovada,
    Expression<int>? saldoDisponivel,
    Expression<String>? revisorNome,
    Expression<bool>? sincronizado,
    Expression<String>? erroSincronizacao,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ordemProducaoId != null) 'ordem_producao_id': ordemProducaoId,
      if (numeroSequencial != null) 'numero_sequencial': numeroSequencial,
      if (alturaMedidaMm != null) 'altura_medida_mm': alturaMedidaMm,
      if (camadas != null) 'camadas': camadas,
      if (quantidadeCalculada != null)
        'quantidade_calculada': quantidadeCalculada,
      if (tipoChapa != null) 'tipo_chapa': tipoChapa,
      if (setorOrigem != null) 'setor_origem': setorOrigem,
      if (responsavelId != null) 'responsavel_id': responsavelId,
      if (dataHora != null) 'data_hora': dataHora,
      if (quantidadeReprovada != null)
        'quantidade_reprovada': quantidadeReprovada,
      if (saldoDisponivel != null) 'saldo_disponivel': saldoDisponivel,
      if (revisorNome != null) 'revisor_nome': revisorNome,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (erroSincronizacao != null) 'erro_sincronizacao': erroSincronizacao,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPaletesCompanion copyWith({
    Value<String>? id,
    Value<String>? ordemProducaoId,
    Value<int?>? numeroSequencial,
    Value<double?>? alturaMedidaMm,
    Value<int?>? camadas,
    Value<int>? quantidadeCalculada,
    Value<String>? tipoChapa,
    Value<String>? setorOrigem,
    Value<String>? responsavelId,
    Value<DateTime>? dataHora,
    Value<int>? quantidadeReprovada,
    Value<int>? saldoDisponivel,
    Value<String?>? revisorNome,
    Value<bool>? sincronizado,
    Value<String?>? erroSincronizacao,
    Value<int>? rowid,
  }) {
    return LocalPaletesCompanion(
      id: id ?? this.id,
      ordemProducaoId: ordemProducaoId ?? this.ordemProducaoId,
      numeroSequencial: numeroSequencial ?? this.numeroSequencial,
      alturaMedidaMm: alturaMedidaMm ?? this.alturaMedidaMm,
      camadas: camadas ?? this.camadas,
      quantidadeCalculada: quantidadeCalculada ?? this.quantidadeCalculada,
      tipoChapa: tipoChapa ?? this.tipoChapa,
      setorOrigem: setorOrigem ?? this.setorOrigem,
      responsavelId: responsavelId ?? this.responsavelId,
      dataHora: dataHora ?? this.dataHora,
      quantidadeReprovada: quantidadeReprovada ?? this.quantidadeReprovada,
      saldoDisponivel: saldoDisponivel ?? this.saldoDisponivel,
      revisorNome: revisorNome ?? this.revisorNome,
      sincronizado: sincronizado ?? this.sincronizado,
      erroSincronizacao: erroSincronizacao ?? this.erroSincronizacao,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ordemProducaoId.present) {
      map['ordem_producao_id'] = Variable<String>(ordemProducaoId.value);
    }
    if (numeroSequencial.present) {
      map['numero_sequencial'] = Variable<int>(numeroSequencial.value);
    }
    if (alturaMedidaMm.present) {
      map['altura_medida_mm'] = Variable<double>(alturaMedidaMm.value);
    }
    if (camadas.present) {
      map['camadas'] = Variable<int>(camadas.value);
    }
    if (quantidadeCalculada.present) {
      map['quantidade_calculada'] = Variable<int>(quantidadeCalculada.value);
    }
    if (tipoChapa.present) {
      map['tipo_chapa'] = Variable<String>(tipoChapa.value);
    }
    if (setorOrigem.present) {
      map['setor_origem'] = Variable<String>(setorOrigem.value);
    }
    if (responsavelId.present) {
      map['responsavel_id'] = Variable<String>(responsavelId.value);
    }
    if (dataHora.present) {
      map['data_hora'] = Variable<DateTime>(dataHora.value);
    }
    if (quantidadeReprovada.present) {
      map['quantidade_reprovada'] = Variable<int>(quantidadeReprovada.value);
    }
    if (saldoDisponivel.present) {
      map['saldo_disponivel'] = Variable<int>(saldoDisponivel.value);
    }
    if (revisorNome.present) {
      map['revisor_nome'] = Variable<String>(revisorNome.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
    }
    if (erroSincronizacao.present) {
      map['erro_sincronizacao'] = Variable<String>(erroSincronizacao.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPaletesCompanion(')
          ..write('id: $id, ')
          ..write('ordemProducaoId: $ordemProducaoId, ')
          ..write('numeroSequencial: $numeroSequencial, ')
          ..write('alturaMedidaMm: $alturaMedidaMm, ')
          ..write('camadas: $camadas, ')
          ..write('quantidadeCalculada: $quantidadeCalculada, ')
          ..write('tipoChapa: $tipoChapa, ')
          ..write('setorOrigem: $setorOrigem, ')
          ..write('responsavelId: $responsavelId, ')
          ..write('dataHora: $dataHora, ')
          ..write('quantidadeReprovada: $quantidadeReprovada, ')
          ..write('saldoDisponivel: $saldoDisponivel, ')
          ..write('revisorNome: $revisorNome, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('erroSincronizacao: $erroSincronizacao, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingOperationsTable extends PendingOperations
    with TableInfo<$PendingOperationsTable, PendingOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _criadoEmMeta = const VerificationMeta(
    'criadoEm',
  );
  @override
  late final GeneratedColumn<DateTime> criadoEm = GeneratedColumn<DateTime>(
    'criado_em',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _erroMeta = const VerificationMeta('erro');
  @override
  late final GeneratedColumn<String> erro = GeneratedColumn<String>(
    'erro',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, tipo, payload, criadoEm, erro];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('criado_em')) {
      context.handle(
        _criadoEmMeta,
        criadoEm.isAcceptableOrUnknown(data['criado_em']!, _criadoEmMeta),
      );
    } else if (isInserting) {
      context.missing(_criadoEmMeta);
    }
    if (data.containsKey('erro')) {
      context.handle(
        _erroMeta,
        erro.isAcceptableOrUnknown(data['erro']!, _erroMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      criadoEm: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}criado_em'],
      )!,
      erro: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}erro'],
      ),
    );
  }

  @override
  $PendingOperationsTable createAlias(String alias) {
    return $PendingOperationsTable(attachedDatabase, alias);
  }
}

class PendingOperation extends DataClass
    implements Insertable<PendingOperation> {
  final String id;
  final String tipo;
  final String payload;
  final DateTime criadoEm;
  final String? erro;
  const PendingOperation({
    required this.id,
    required this.tipo,
    required this.payload,
    required this.criadoEm,
    this.erro,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tipo'] = Variable<String>(tipo);
    map['payload'] = Variable<String>(payload);
    map['criado_em'] = Variable<DateTime>(criadoEm);
    if (!nullToAbsent || erro != null) {
      map['erro'] = Variable<String>(erro);
    }
    return map;
  }

  PendingOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingOperationsCompanion(
      id: Value(id),
      tipo: Value(tipo),
      payload: Value(payload),
      criadoEm: Value(criadoEm),
      erro: erro == null && nullToAbsent ? const Value.absent() : Value(erro),
    );
  }

  factory PendingOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOperation(
      id: serializer.fromJson<String>(json['id']),
      tipo: serializer.fromJson<String>(json['tipo']),
      payload: serializer.fromJson<String>(json['payload']),
      criadoEm: serializer.fromJson<DateTime>(json['criadoEm']),
      erro: serializer.fromJson<String?>(json['erro']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tipo': serializer.toJson<String>(tipo),
      'payload': serializer.toJson<String>(payload),
      'criadoEm': serializer.toJson<DateTime>(criadoEm),
      'erro': serializer.toJson<String?>(erro),
    };
  }

  PendingOperation copyWith({
    String? id,
    String? tipo,
    String? payload,
    DateTime? criadoEm,
    Value<String?> erro = const Value.absent(),
  }) => PendingOperation(
    id: id ?? this.id,
    tipo: tipo ?? this.tipo,
    payload: payload ?? this.payload,
    criadoEm: criadoEm ?? this.criadoEm,
    erro: erro.present ? erro.value : this.erro,
  );
  PendingOperation copyWithCompanion(PendingOperationsCompanion data) {
    return PendingOperation(
      id: data.id.present ? data.id.value : this.id,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      payload: data.payload.present ? data.payload.value : this.payload,
      criadoEm: data.criadoEm.present ? data.criadoEm.value : this.criadoEm,
      erro: data.erro.present ? data.erro.value : this.erro,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperation(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('payload: $payload, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('erro: $erro')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tipo, payload, criadoEm, erro);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOperation &&
          other.id == this.id &&
          other.tipo == this.tipo &&
          other.payload == this.payload &&
          other.criadoEm == this.criadoEm &&
          other.erro == this.erro);
}

class PendingOperationsCompanion extends UpdateCompanion<PendingOperation> {
  final Value<String> id;
  final Value<String> tipo;
  final Value<String> payload;
  final Value<DateTime> criadoEm;
  final Value<String?> erro;
  final Value<int> rowid;
  const PendingOperationsCompanion({
    this.id = const Value.absent(),
    this.tipo = const Value.absent(),
    this.payload = const Value.absent(),
    this.criadoEm = const Value.absent(),
    this.erro = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingOperationsCompanion.insert({
    required String id,
    required String tipo,
    required String payload,
    required DateTime criadoEm,
    this.erro = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tipo = Value(tipo),
       payload = Value(payload),
       criadoEm = Value(criadoEm);
  static Insertable<PendingOperation> custom({
    Expression<String>? id,
    Expression<String>? tipo,
    Expression<String>? payload,
    Expression<DateTime>? criadoEm,
    Expression<String>? erro,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tipo != null) 'tipo': tipo,
      if (payload != null) 'payload': payload,
      if (criadoEm != null) 'criado_em': criadoEm,
      if (erro != null) 'erro': erro,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingOperationsCompanion copyWith({
    Value<String>? id,
    Value<String>? tipo,
    Value<String>? payload,
    Value<DateTime>? criadoEm,
    Value<String?>? erro,
    Value<int>? rowid,
  }) {
    return PendingOperationsCompanion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      payload: payload ?? this.payload,
      criadoEm: criadoEm ?? this.criadoEm,
      erro: erro ?? this.erro,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (criadoEm.present) {
      map['criado_em'] = Variable<DateTime>(criadoEm.value);
    }
    if (erro.present) {
      map['erro'] = Variable<String>(erro.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsCompanion(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('payload: $payload, ')
          ..write('criadoEm: $criadoEm, ')
          ..write('erro: $erro, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalOrdensTable localOrdens = $LocalOrdensTable(this);
  late final $LocalPaletesTable localPaletes = $LocalPaletesTable(this);
  late final $PendingOperationsTable pendingOperations =
      $PendingOperationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localOrdens,
    localPaletes,
    pendingOperations,
  ];
}

typedef $$LocalOrdensTableCreateCompanionBuilder =
    LocalOrdensCompanion Function({
      required String id,
      required String numeroOp,
      required int quantidadePedida,
      required DateTime dataPedido,
      required String status,
      required String codigoFt,
      required int qpPadrao,
      required String clienteNome,
      required double composicaoEspessuraMm,
      Value<int?> pacotesPorCamada,
      Value<int?> pecasPorPacote,
      Value<int> rowid,
    });
typedef $$LocalOrdensTableUpdateCompanionBuilder =
    LocalOrdensCompanion Function({
      Value<String> id,
      Value<String> numeroOp,
      Value<int> quantidadePedida,
      Value<DateTime> dataPedido,
      Value<String> status,
      Value<String> codigoFt,
      Value<int> qpPadrao,
      Value<String> clienteNome,
      Value<double> composicaoEspessuraMm,
      Value<int?> pacotesPorCamada,
      Value<int?> pecasPorPacote,
      Value<int> rowid,
    });

class $$LocalOrdensTableFilterComposer
    extends Composer<_$AppDatabase, $LocalOrdensTable> {
  $$LocalOrdensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numeroOp => $composableBuilder(
    column: $table.numeroOp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantidadePedida => $composableBuilder(
    column: $table.quantidadePedida,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataPedido => $composableBuilder(
    column: $table.dataPedido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoFt => $composableBuilder(
    column: $table.codigoFt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qpPadrao => $composableBuilder(
    column: $table.qpPadrao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clienteNome => $composableBuilder(
    column: $table.clienteNome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get composicaoEspessuraMm => $composableBuilder(
    column: $table.composicaoEspessuraMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pacotesPorCamada => $composableBuilder(
    column: $table.pacotesPorCamada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pecasPorPacote => $composableBuilder(
    column: $table.pecasPorPacote,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalOrdensTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalOrdensTable> {
  $$LocalOrdensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numeroOp => $composableBuilder(
    column: $table.numeroOp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantidadePedida => $composableBuilder(
    column: $table.quantidadePedida,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataPedido => $composableBuilder(
    column: $table.dataPedido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoFt => $composableBuilder(
    column: $table.codigoFt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qpPadrao => $composableBuilder(
    column: $table.qpPadrao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clienteNome => $composableBuilder(
    column: $table.clienteNome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get composicaoEspessuraMm => $composableBuilder(
    column: $table.composicaoEspessuraMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pacotesPorCamada => $composableBuilder(
    column: $table.pacotesPorCamada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pecasPorPacote => $composableBuilder(
    column: $table.pecasPorPacote,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalOrdensTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalOrdensTable> {
  $$LocalOrdensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get numeroOp =>
      $composableBuilder(column: $table.numeroOp, builder: (column) => column);

  GeneratedColumn<int> get quantidadePedida => $composableBuilder(
    column: $table.quantidadePedida,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dataPedido => $composableBuilder(
    column: $table.dataPedido,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get codigoFt =>
      $composableBuilder(column: $table.codigoFt, builder: (column) => column);

  GeneratedColumn<int> get qpPadrao =>
      $composableBuilder(column: $table.qpPadrao, builder: (column) => column);

  GeneratedColumn<String> get clienteNome => $composableBuilder(
    column: $table.clienteNome,
    builder: (column) => column,
  );

  GeneratedColumn<double> get composicaoEspessuraMm => $composableBuilder(
    column: $table.composicaoEspessuraMm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pacotesPorCamada => $composableBuilder(
    column: $table.pacotesPorCamada,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pecasPorPacote => $composableBuilder(
    column: $table.pecasPorPacote,
    builder: (column) => column,
  );
}

class $$LocalOrdensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalOrdensTable,
          LocalOrden,
          $$LocalOrdensTableFilterComposer,
          $$LocalOrdensTableOrderingComposer,
          $$LocalOrdensTableAnnotationComposer,
          $$LocalOrdensTableCreateCompanionBuilder,
          $$LocalOrdensTableUpdateCompanionBuilder,
          (
            LocalOrden,
            BaseReferences<_$AppDatabase, $LocalOrdensTable, LocalOrden>,
          ),
          LocalOrden,
          PrefetchHooks Function()
        > {
  $$LocalOrdensTableTableManager(_$AppDatabase db, $LocalOrdensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOrdensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOrdensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOrdensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> numeroOp = const Value.absent(),
                Value<int> quantidadePedida = const Value.absent(),
                Value<DateTime> dataPedido = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> codigoFt = const Value.absent(),
                Value<int> qpPadrao = const Value.absent(),
                Value<String> clienteNome = const Value.absent(),
                Value<double> composicaoEspessuraMm = const Value.absent(),
                Value<int?> pacotesPorCamada = const Value.absent(),
                Value<int?> pecasPorPacote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdensCompanion(
                id: id,
                numeroOp: numeroOp,
                quantidadePedida: quantidadePedida,
                dataPedido: dataPedido,
                status: status,
                codigoFt: codigoFt,
                qpPadrao: qpPadrao,
                clienteNome: clienteNome,
                composicaoEspessuraMm: composicaoEspessuraMm,
                pacotesPorCamada: pacotesPorCamada,
                pecasPorPacote: pecasPorPacote,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String numeroOp,
                required int quantidadePedida,
                required DateTime dataPedido,
                required String status,
                required String codigoFt,
                required int qpPadrao,
                required String clienteNome,
                required double composicaoEspessuraMm,
                Value<int?> pacotesPorCamada = const Value.absent(),
                Value<int?> pecasPorPacote = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdensCompanion.insert(
                id: id,
                numeroOp: numeroOp,
                quantidadePedida: quantidadePedida,
                dataPedido: dataPedido,
                status: status,
                codigoFt: codigoFt,
                qpPadrao: qpPadrao,
                clienteNome: clienteNome,
                composicaoEspessuraMm: composicaoEspessuraMm,
                pacotesPorCamada: pacotesPorCamada,
                pecasPorPacote: pecasPorPacote,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalOrdensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalOrdensTable,
      LocalOrden,
      $$LocalOrdensTableFilterComposer,
      $$LocalOrdensTableOrderingComposer,
      $$LocalOrdensTableAnnotationComposer,
      $$LocalOrdensTableCreateCompanionBuilder,
      $$LocalOrdensTableUpdateCompanionBuilder,
      (
        LocalOrden,
        BaseReferences<_$AppDatabase, $LocalOrdensTable, LocalOrden>,
      ),
      LocalOrden,
      PrefetchHooks Function()
    >;
typedef $$LocalPaletesTableCreateCompanionBuilder =
    LocalPaletesCompanion Function({
      required String id,
      required String ordemProducaoId,
      Value<int?> numeroSequencial,
      Value<double?> alturaMedidaMm,
      Value<int?> camadas,
      required int quantidadeCalculada,
      required String tipoChapa,
      required String setorOrigem,
      required String responsavelId,
      required DateTime dataHora,
      Value<int> quantidadeReprovada,
      required int saldoDisponivel,
      Value<String?> revisorNome,
      Value<bool> sincronizado,
      Value<String?> erroSincronizacao,
      Value<int> rowid,
    });
typedef $$LocalPaletesTableUpdateCompanionBuilder =
    LocalPaletesCompanion Function({
      Value<String> id,
      Value<String> ordemProducaoId,
      Value<int?> numeroSequencial,
      Value<double?> alturaMedidaMm,
      Value<int?> camadas,
      Value<int> quantidadeCalculada,
      Value<String> tipoChapa,
      Value<String> setorOrigem,
      Value<String> responsavelId,
      Value<DateTime> dataHora,
      Value<int> quantidadeReprovada,
      Value<int> saldoDisponivel,
      Value<String?> revisorNome,
      Value<bool> sincronizado,
      Value<String?> erroSincronizacao,
      Value<int> rowid,
    });

class $$LocalPaletesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPaletesTable> {
  $$LocalPaletesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ordemProducaoId => $composableBuilder(
    column: $table.ordemProducaoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numeroSequencial => $composableBuilder(
    column: $table.numeroSequencial,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alturaMedidaMm => $composableBuilder(
    column: $table.alturaMedidaMm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get camadas => $composableBuilder(
    column: $table.camadas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantidadeCalculada => $composableBuilder(
    column: $table.quantidadeCalculada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoChapa => $composableBuilder(
    column: $table.tipoChapa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setorOrigem => $composableBuilder(
    column: $table.setorOrigem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responsavelId => $composableBuilder(
    column: $table.responsavelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataHora => $composableBuilder(
    column: $table.dataHora,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantidadeReprovada => $composableBuilder(
    column: $table.quantidadeReprovada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get saldoDisponivel => $composableBuilder(
    column: $table.saldoDisponivel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisorNome => $composableBuilder(
    column: $table.revisorNome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get erroSincronizacao => $composableBuilder(
    column: $table.erroSincronizacao,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPaletesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPaletesTable> {
  $$LocalPaletesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ordemProducaoId => $composableBuilder(
    column: $table.ordemProducaoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numeroSequencial => $composableBuilder(
    column: $table.numeroSequencial,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alturaMedidaMm => $composableBuilder(
    column: $table.alturaMedidaMm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get camadas => $composableBuilder(
    column: $table.camadas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantidadeCalculada => $composableBuilder(
    column: $table.quantidadeCalculada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoChapa => $composableBuilder(
    column: $table.tipoChapa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setorOrigem => $composableBuilder(
    column: $table.setorOrigem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responsavelId => $composableBuilder(
    column: $table.responsavelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataHora => $composableBuilder(
    column: $table.dataHora,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantidadeReprovada => $composableBuilder(
    column: $table.quantidadeReprovada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get saldoDisponivel => $composableBuilder(
    column: $table.saldoDisponivel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisorNome => $composableBuilder(
    column: $table.revisorNome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get erroSincronizacao => $composableBuilder(
    column: $table.erroSincronizacao,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPaletesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPaletesTable> {
  $$LocalPaletesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ordemProducaoId => $composableBuilder(
    column: $table.ordemProducaoId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get numeroSequencial => $composableBuilder(
    column: $table.numeroSequencial,
    builder: (column) => column,
  );

  GeneratedColumn<double> get alturaMedidaMm => $composableBuilder(
    column: $table.alturaMedidaMm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get camadas =>
      $composableBuilder(column: $table.camadas, builder: (column) => column);

  GeneratedColumn<int> get quantidadeCalculada => $composableBuilder(
    column: $table.quantidadeCalculada,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipoChapa =>
      $composableBuilder(column: $table.tipoChapa, builder: (column) => column);

  GeneratedColumn<String> get setorOrigem => $composableBuilder(
    column: $table.setorOrigem,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responsavelId => $composableBuilder(
    column: $table.responsavelId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dataHora =>
      $composableBuilder(column: $table.dataHora, builder: (column) => column);

  GeneratedColumn<int> get quantidadeReprovada => $composableBuilder(
    column: $table.quantidadeReprovada,
    builder: (column) => column,
  );

  GeneratedColumn<int> get saldoDisponivel => $composableBuilder(
    column: $table.saldoDisponivel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get revisorNome => $composableBuilder(
    column: $table.revisorNome,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => column,
  );

  GeneratedColumn<String> get erroSincronizacao => $composableBuilder(
    column: $table.erroSincronizacao,
    builder: (column) => column,
  );
}

class $$LocalPaletesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPaletesTable,
          LocalPalete,
          $$LocalPaletesTableFilterComposer,
          $$LocalPaletesTableOrderingComposer,
          $$LocalPaletesTableAnnotationComposer,
          $$LocalPaletesTableCreateCompanionBuilder,
          $$LocalPaletesTableUpdateCompanionBuilder,
          (
            LocalPalete,
            BaseReferences<_$AppDatabase, $LocalPaletesTable, LocalPalete>,
          ),
          LocalPalete,
          PrefetchHooks Function()
        > {
  $$LocalPaletesTableTableManager(_$AppDatabase db, $LocalPaletesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPaletesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPaletesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPaletesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ordemProducaoId = const Value.absent(),
                Value<int?> numeroSequencial = const Value.absent(),
                Value<double?> alturaMedidaMm = const Value.absent(),
                Value<int?> camadas = const Value.absent(),
                Value<int> quantidadeCalculada = const Value.absent(),
                Value<String> tipoChapa = const Value.absent(),
                Value<String> setorOrigem = const Value.absent(),
                Value<String> responsavelId = const Value.absent(),
                Value<DateTime> dataHora = const Value.absent(),
                Value<int> quantidadeReprovada = const Value.absent(),
                Value<int> saldoDisponivel = const Value.absent(),
                Value<String?> revisorNome = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<String?> erroSincronizacao = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPaletesCompanion(
                id: id,
                ordemProducaoId: ordemProducaoId,
                numeroSequencial: numeroSequencial,
                alturaMedidaMm: alturaMedidaMm,
                camadas: camadas,
                quantidadeCalculada: quantidadeCalculada,
                tipoChapa: tipoChapa,
                setorOrigem: setorOrigem,
                responsavelId: responsavelId,
                dataHora: dataHora,
                quantidadeReprovada: quantidadeReprovada,
                saldoDisponivel: saldoDisponivel,
                revisorNome: revisorNome,
                sincronizado: sincronizado,
                erroSincronizacao: erroSincronizacao,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ordemProducaoId,
                Value<int?> numeroSequencial = const Value.absent(),
                Value<double?> alturaMedidaMm = const Value.absent(),
                Value<int?> camadas = const Value.absent(),
                required int quantidadeCalculada,
                required String tipoChapa,
                required String setorOrigem,
                required String responsavelId,
                required DateTime dataHora,
                Value<int> quantidadeReprovada = const Value.absent(),
                required int saldoDisponivel,
                Value<String?> revisorNome = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<String?> erroSincronizacao = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPaletesCompanion.insert(
                id: id,
                ordemProducaoId: ordemProducaoId,
                numeroSequencial: numeroSequencial,
                alturaMedidaMm: alturaMedidaMm,
                camadas: camadas,
                quantidadeCalculada: quantidadeCalculada,
                tipoChapa: tipoChapa,
                setorOrigem: setorOrigem,
                responsavelId: responsavelId,
                dataHora: dataHora,
                quantidadeReprovada: quantidadeReprovada,
                saldoDisponivel: saldoDisponivel,
                revisorNome: revisorNome,
                sincronizado: sincronizado,
                erroSincronizacao: erroSincronizacao,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPaletesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPaletesTable,
      LocalPalete,
      $$LocalPaletesTableFilterComposer,
      $$LocalPaletesTableOrderingComposer,
      $$LocalPaletesTableAnnotationComposer,
      $$LocalPaletesTableCreateCompanionBuilder,
      $$LocalPaletesTableUpdateCompanionBuilder,
      (
        LocalPalete,
        BaseReferences<_$AppDatabase, $LocalPaletesTable, LocalPalete>,
      ),
      LocalPalete,
      PrefetchHooks Function()
    >;
typedef $$PendingOperationsTableCreateCompanionBuilder =
    PendingOperationsCompanion Function({
      required String id,
      required String tipo,
      required String payload,
      required DateTime criadoEm,
      Value<String?> erro,
      Value<int> rowid,
    });
typedef $$PendingOperationsTableUpdateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<String> id,
      Value<String> tipo,
      Value<String> payload,
      Value<DateTime> criadoEm,
      Value<String?> erro,
      Value<int> rowid,
    });

class $$PendingOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get erro => $composableBuilder(
    column: $table.erro,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get criadoEm => $composableBuilder(
    column: $table.criadoEm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get erro => $composableBuilder(
    column: $table.erro,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get criadoEm =>
      $composableBuilder(column: $table.criadoEm, builder: (column) => column);

  GeneratedColumn<String> get erro =>
      $composableBuilder(column: $table.erro, builder: (column) => column);
}

class $$PendingOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation,
          $$PendingOperationsTableFilterComposer,
          $$PendingOperationsTableOrderingComposer,
          $$PendingOperationsTableAnnotationComposer,
          $$PendingOperationsTableCreateCompanionBuilder,
          $$PendingOperationsTableUpdateCompanionBuilder,
          (
            PendingOperation,
            BaseReferences<
              _$AppDatabase,
              $PendingOperationsTable,
              PendingOperation
            >,
          ),
          PendingOperation,
          PrefetchHooks Function()
        > {
  $$PendingOperationsTableTableManager(
    _$AppDatabase db,
    $PendingOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> criadoEm = const Value.absent(),
                Value<String?> erro = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingOperationsCompanion(
                id: id,
                tipo: tipo,
                payload: payload,
                criadoEm: criadoEm,
                erro: erro,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tipo,
                required String payload,
                required DateTime criadoEm,
                Value<String?> erro = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingOperationsCompanion.insert(
                id: id,
                tipo: tipo,
                payload: payload,
                criadoEm: criadoEm,
                erro: erro,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOperationsTable,
      PendingOperation,
      $$PendingOperationsTableFilterComposer,
      $$PendingOperationsTableOrderingComposer,
      $$PendingOperationsTableAnnotationComposer,
      $$PendingOperationsTableCreateCompanionBuilder,
      $$PendingOperationsTableUpdateCompanionBuilder,
      (
        PendingOperation,
        BaseReferences<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation
        >,
      ),
      PendingOperation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalOrdensTableTableManager get localOrdens =>
      $$LocalOrdensTableTableManager(_db, _db.localOrdens);
  $$LocalPaletesTableTableManager get localPaletes =>
      $$LocalPaletesTableTableManager(_db, _db.localPaletes);
  $$PendingOperationsTableTableManager get pendingOperations =>
      $$PendingOperationsTableTableManager(_db, _db.pendingOperations);
}
