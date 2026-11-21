import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/marca.dart';

class FipeException implements Exception {
  final String mensagem;
  const FipeException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Consulta marcas e modelos de carros na BrasilAPI (dados da FIPE).
class FipeService {
  static const _base = 'https://brasilapi.com.br/api/fipe';

  final http.Client _client;
  FipeService({http.Client? client}) : _client = client ?? http.Client();

  /// GET /fipe/marcas/v1/carros
  Future<List<Marca>> buscarMarcas() async {
    final dados = await _get('$_base/marcas/v1/carros');
    if (dados is! List) {
      throw const FipeException('Resposta inesperada da API de marcas.');
    }
    final marcas = dados
        .whereType<Map<String, dynamic>>()
        .map(Marca.fromJson)
        .toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return marcas;
  }

  /// GET /fipe/veiculos/v1/carros/{codigoMarca}
  /// Retorna os nomes dos modelos (sem repetição, em ordem alfabética).
  Future<List<String>> buscarModelos(String codigoMarca) async {
    final dados = await _get('$_base/veiculos/v1/carros/$codigoMarca');
    if (dados is! List) {
      throw const FipeException('Resposta inesperada da API de modelos.');
    }
    final nomes = <String>{};
    for (final item in dados) {
      if (item is Map<String, dynamic>) {
        final nome = (item['modelo'] ?? item['nome'])?.toString().trim();
        if (nome != null && nome.isNotEmpty) nomes.add(nome);
      }
    }
    return nomes.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Future<dynamic> _get(String url) async {
    try {
      final resposta =
          await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (resposta.statusCode != 200) {
        throw FipeException('A API respondeu com erro ${resposta.statusCode}.');
      }
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FipeException {
      rethrow;
    } on TimeoutException {
      throw const FipeException('A consulta demorou demais. Tente novamente.');
    } catch (_) {
      throw const FipeException(
          'Não foi possível consultar a API. Verifique sua conexão.');
    }
  }
}
