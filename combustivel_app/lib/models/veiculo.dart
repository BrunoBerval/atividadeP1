class Veiculo {
  final int? id;
  final String marca;
  final String modelo;
  final int ano;
  final String cilindrada;

  const Veiculo({
    this.id,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.cilindrada,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'marca': marca,
        'modelo': modelo,
        'ano': ano,
        'cilindrada': cilindrada,
      };

  factory Veiculo.fromMap(Map<String, Object?> map) => Veiculo(
        id: map['id'] as int,
        marca: map['marca'] as String,
        modelo: map['modelo'] as String,
        ano: map['ano'] as int,
        cilindrada: map['cilindrada'] as String,
      );
}
