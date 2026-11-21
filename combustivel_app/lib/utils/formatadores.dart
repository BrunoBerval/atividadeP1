import 'package:intl/intl.dart';

final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _decimal2 = NumberFormat('#,##0.00', 'pt_BR');
final _decimal1 = NumberFormat('#,##0.#', 'pt_BR');
final _dataHora = DateFormat('dd/MM/yyyy HH:mm');

/// Ex.: 200.0 -> "R$ 200,00"
String formatarMoeda(double valor) => _moeda.format(valor);

/// Ex.: 10.0 -> "10,00"
String formatarDecimal(double valor) => _decimal2.format(valor);

/// Ex.: 1400.0 -> "1.400"
String formatarKm(double valor) => '${_decimal1.format(valor)} km';

/// Ex.: 2026-01-10 14:30 -> "10/01/2026 14:30"
String formatarDataHora(DateTime data) => _dataHora.format(data);

/// Converte "5,59" ou "5.59" em double. Retorna null se inválido.
double? parseDecimal(String? texto) {
  if (texto == null) return null;
  return double.tryParse(texto.trim().replaceAll(',', '.'));
}
