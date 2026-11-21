import 'package:combustivel_app/models/abastecimento.dart';
import 'package:combustivel_app/utils/calculos.dart';
import 'package:flutter_test/flutter_test.dart';

Abastecimento _a(double preco, double km, double litros, DateTime data) =>
    Abastecimento(
      veiculoId: 1,
      tipo: TipoCombustivel.gasolina,
      precoPorLitro: preco,
      quilometragem: km,
      litros: litros,
      dataHora: data,
    );

void main() {
  final lista = [
    _a(5.00, 1000, 40, DateTime(2026, 1, 1)),
    _a(5.50, 1400, 40, DateTime(2026, 1, 10)),
    _a(6.00, 1750, 35, DateTime(2026, 1, 20)),
  ];

  test('valor total = preço x litros', () {
    expect(lista[0].valorTotal, 200.0);
    expect(lista[1].valorTotal, 220.0);
  });

  test('1º abastecimento não tem km/L nem R\$/km', () {
    final r = calcularIndicadores(lista);
    expect(r[0].kmPorLitro, isNull);
    expect(r[0].custoPorKm, isNull);
  });

  test('2º abastecimento: 400 km, 10 km/L, R\$ 0,55/km', () {
    final r = calcularIndicadores(lista);
    expect(r[1].distancia, 400);
    expect(r[1].kmPorLitro, closeTo(10.0, 0.001));
    expect(r[1].custoPorKm, closeTo(0.55, 0.001));
  });

  test('3º abastecimento: 350 km, 10 km/L, R\$ 0,60/km', () {
    final r = calcularIndicadores(lista);
    expect(r[2].distancia, 350);
    expect(r[2].kmPorLitro, closeTo(10.0, 0.001));
    expect(r[2].custoPorKm, closeTo(0.60, 0.001));
  });

  test('ordena por data mesmo com lista embaralhada', () {
    final r = calcularIndicadores([lista[2], lista[0], lista[1]]);
    expect(r[1].kmPorLitro, closeTo(10.0, 0.001));
  });

  test('distância <= 0 não gera indicadores', () {
    final r = calcularIndicadores([
      _a(5, 1000, 40, DateTime(2026, 1, 1)),
      _a(5, 1000, 40, DateTime(2026, 1, 2)),
    ]);
    expect(r[1].kmPorLitro, isNull);
  });
}
