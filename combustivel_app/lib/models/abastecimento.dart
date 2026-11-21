enum TipoCombustivel {
  etanol,
  gasolina,
  diesel;

  String get rotulo => switch (this) {
        TipoCombustivel.etanol => 'Etanol',
        TipoCombustivel.gasolina => 'Gasolina',
        TipoCombustivel.diesel => 'Diesel',
      };

  static TipoCombustivel fromName(String nome) =>
      TipoCombustivel.values.firstWhere((e) => e.name == nome);
}

class Abastecimento {
  final int? id;
  final int veiculoId;
  final TipoCombustivel tipo;
  final double precoPorLitro; // R$
  final double quilometragem; // km no momento do abastecimento
  final double litros;
  final DateTime dataHora;

  const Abastecimento({
    this.id,
    required this.veiculoId,
    required this.tipo,
    required this.precoPorLitro,
    required this.quilometragem,
    required this.litros,
    required this.dataHora,
  });

  /// Valor total = preço por litro x litros (não é salvo no banco).
  double get valorTotal => precoPorLitro * litros;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'veiculo_id': veiculoId,
        'tipo_combustivel': tipo.name,
        'preco_litro': precoPorLitro,
        'quilometragem': quilometragem,
        'litros': litros,
        'data_hora': dataHora.toIso8601String(),
      };

  factory Abastecimento.fromMap(Map<String, Object?> map) => Abastecimento(
        id: map['id'] as int,
        veiculoId: map['veiculo_id'] as int,
        tipo: TipoCombustivel.fromName(map['tipo_combustivel'] as String),
        precoPorLitro: (map['preco_litro'] as num).toDouble(),
        quilometragem: (map['quilometragem'] as num).toDouble(),
        litros: (map['litros'] as num).toDouble(),
        dataHora: DateTime.parse(map['data_hora'] as String),
      );
}
