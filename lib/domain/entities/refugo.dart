/// Lista fechada de motivos — reflete o check constraint de `refugos.motivo`.
const motivosRefugo = [
  'Quebra na produção',
  'Erro de medida',
  'Amassado/rasgado',
  'Outro',
];

/// Chapa perdida/descartada, vinculada à OP (não a um palete específico).
class Refugo {
  final String id;
  final String ordemProducaoId;
  final String responsavelId;
  final int quantidade;
  final String motivo;
  final DateTime dataHora;

  const Refugo({
    required this.id,
    required this.ordemProducaoId,
    required this.responsavelId,
    required this.quantidade,
    required this.motivo,
    required this.dataHora,
  });

  factory Refugo.fromMap(Map<String, dynamic> map) => Refugo(
    id: map['id'] as String,
    ordemProducaoId: map['ordem_producao_id'] as String,
    responsavelId: map['responsavel_id'] as String,
    quantidade: map['quantidade'] as int,
    motivo: map['motivo'] as String,
    dataHora: DateTime.parse(map['data_hora'] as String),
  );
}
