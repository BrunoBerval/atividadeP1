import 'package:flutter/foundation.dart';

import '../models/abastecimento.dart';
import '../models/veiculo.dart';
import '../services/database_helper.dart';
import '../utils/calculos.dart';
import '../utils/formatadores.dart';

class AppProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  Veiculo? veiculo;

  /// Em ordem cronológica (mais antigo primeiro).
  List<Abastecimento> abastecimentos = [];

  /// Indicadores calculados para cada abastecimento (mesma ordem da lista).
  List<Indicador> indicadores = [];

  bool carregando = true;

  double get gastoTotal =>
      abastecimentos.fold(0.0, (soma, a) => soma + a.valorTotal);

  // ---------------- Carregamento ----------------

  /// Lê veículo e abastecimentos do banco ao abrir o app.
  Future<void> carregar() async {
    carregando = true;
    notifyListeners();
    veiculo = await _db.buscarVeiculo();
    await _carregarAbastecimentos();
    carregando = false;
    notifyListeners();
  }

  Future<void> _carregarAbastecimentos() async {
    final id = veiculo?.id;
    abastecimentos = id == null ? [] : await _db.listarAbastecimentos(id);
    indicadores = calcularIndicadores(abastecimentos);
  }

  // ---------------- Veículo ----------------

  Future<void> salvarVeiculo(Veiculo novo) async {
    await _db.inserirVeiculo(novo);
    veiculo = await _db.buscarVeiculo();
    await _carregarAbastecimentos();
    notifyListeners();
  }

  /// Será usado na etapa 6 (exclusão com confirmação).
  Future<void> excluirVeiculo() async {
    final atual = veiculo;
    if (atual?.id == null) return;
    await _db.excluirVeiculo(atual!.id!); // CASCADE apaga os abastecimentos
    veiculo = null;
    abastecimentos = [];
    indicadores = [];
    notifyListeners();
  }

  // ---------------- Abastecimentos ----------------

  Future<void> adicionarAbastecimento(Abastecimento abastecimento) async {
    await _db.inserirAbastecimento(abastecimento);
    await _carregarAbastecimentos();
    notifyListeners();
  }

  Future<void> excluirAbastecimento(int id) async {
    await _db.excluirAbastecimento(id);
    await _carregarAbastecimentos();
    notifyListeners();
  }

  /// A quilometragem deve crescer junto com a data: precisa ser maior que a
  /// do abastecimento anterior e menor que a do posterior (se existirem).
  /// Retorna a mensagem de erro, ou null se estiver válida.
  String? validarQuilometragem(DateTime data, double km) {
    Abastecimento? anterior;
    Abastecimento? posterior;
    for (final a in abastecimentos) {
      if (a.dataHora.isBefore(data)) {
        if (anterior == null || a.dataHora.isAfter(anterior.dataHora)) {
          anterior = a;
        }
      } else {
        if (posterior == null || a.dataHora.isBefore(posterior.dataHora)) {
          posterior = a;
        }
      }
    }
    if (anterior != null && km <= anterior.quilometragem) {
      return 'Deve ser maior que ${formatarKm(anterior.quilometragem)} '
          '(abastecimento anterior)';
    }
    if (posterior != null && km >= posterior.quilometragem) {
      return 'Deve ser menor que ${formatarKm(posterior.quilometragem)} '
          '(abastecimento posterior)';
    }
    return null;
  }
}
