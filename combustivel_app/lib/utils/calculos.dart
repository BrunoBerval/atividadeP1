import '../models/abastecimento.dart';

/// Resultado calculado para um abastecimento.
/// Os campos opcionais são null no 1º abastecimento (referência inicial)
/// ou quando a distância é inválida (<= 0).
class Indicador {
  final Abastecimento abastecimento;
  final double? distancia; // km
  final double? kmPorLitro; // km/L
  final double? custoPorKm; // R$/km

  const Indicador({
    required this.abastecimento,
    this.distancia,
    this.kmPorLitro,
    this.custoPorKm,
  });

  double get valorTotal => abastecimento.valorTotal;
  bool get ehReferencia => distancia == null;
}

/// Calcula os indicadores de cada abastecimento.
///
/// Regras (todos os abastecimentos completam o tanque):
///   distância = km atual - km anterior
///   km/L      = distância / litros do abastecimento atual
///   R$/km     = valor total do abastecimento atual / distância
List<Indicador> calcularIndicadores(List<Abastecimento> abastecimentos) {
  final ordenados = [...abastecimentos]..sort((a, b) {
      final porData = a.dataHora.compareTo(b.dataHora);
      return porData != 0 ? porData : a.quilometragem.compareTo(b.quilometragem);
    });

  final resultado = <Indicador>[];
  for (var i = 0; i < ordenados.length; i++) {
    final atual = ordenados[i];

    if (i == 0) {
      resultado.add(Indicador(abastecimento: atual));
      continue;
    }

    final distancia = atual.quilometragem - ordenados[i - 1].quilometragem;
    if (distancia <= 0 || atual.litros <= 0) {
      resultado.add(Indicador(abastecimento: atual));
      continue;
    }

    resultado.add(Indicador(
      abastecimento: atual,
      distancia: distancia,
      kmPorLitro: distancia / atual.litros,
      custoPorKm: atual.valorTotal / distancia,
    ));
  }
  return resultado;
}
