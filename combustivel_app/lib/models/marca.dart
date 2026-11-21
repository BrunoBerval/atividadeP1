class Marca {
  final String codigo;
  final String nome;

  const Marca({required this.codigo, required this.nome});

  /// A BrasilAPI retorna {"nome": "...", "valor": "..."} para cada marca.
  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
        codigo: json['valor'].toString(),
        nome: json['nome'].toString().trim(),
      );
}
