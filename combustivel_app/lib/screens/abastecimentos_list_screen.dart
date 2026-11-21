import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/calculos.dart';
import '../utils/formatadores.dart';

class AbastecimentosListScreen extends StatelessWidget {
  const AbastecimentosListScreen({super.key});

  Future<void> _confirmarExclusao(
      BuildContext context, Indicador item) async {
    final provider = context.read<AppProvider>();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir abastecimento?'),
        content: Text(
            'Abastecimento de ${formatarDataHora(item.abastecimento.dataHora)} '
            'será removido e os indicadores serão recalculados.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmou == true && item.abastecimento.id != null) {
      await provider.excluirAbastecimento(item.abastecimento.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final indicadores = app.indicadores;

    if (indicadores.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum abastecimento registrado.\n'
            'Toque em "Abastecer" para adicionar o primeiro.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Mais recente primeiro. O índice cronológico 0 é o abastecimento inicial.
    final exibicao = indicadores.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: exibicao.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              '${indicadores.length} abastecimento(s) • '
              'Total gasto: ${formatarMoeda(app.gastoTotal)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          );
        }
        final posicao = i - 1;
        final item = exibicao[posicao];
        final ehPrimeiro = posicao == exibicao.length - 1;
        return _AbastecimentoCard(
          item: item,
          ehPrimeiro: ehPrimeiro,
          onExcluir: () => _confirmarExclusao(context, item),
        );
      },
    );
  }
}

class _AbastecimentoCard extends StatelessWidget {
  final Indicador item;
  final bool ehPrimeiro;
  final VoidCallback onExcluir;

  const _AbastecimentoCard({
    required this.item,
    required this.ehPrimeiro,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final a = item.abastecimento;
    final tema = Theme.of(context);

    final String indicadores;
    if (ehPrimeiro) {
      indicadores = 'Referência inicial (sem km/L e R\$/km)';
    } else if (item.kmPorLitro == null) {
      indicadores = 'Indicadores indisponíveis (quilometragem inválida)';
    } else {
      indicadores = '${formatarDecimal(item.kmPorLitro!)} km/L  •  '
          '${formatarMoeda(item.custoPorKm!)}/km  •  '
          '${formatarKm(item.distancia!)} rodados';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(formatarDataHora(a.dataHora),
                      style: tema.textTheme.labelLarge),
                ),
                Chip(
                  label: Text(a.tipo.rotulo),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onExcluir,
                ),
              ],
            ),
            Text(formatarMoeda(a.valorTotal),
                style: tema.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('${formatarDecimal(a.litros)} L × '
                '${formatarMoeda(a.precoPorLitro)}/L  •  '
                '${formatarKm(a.quilometragem)}'),
            const SizedBox(height: 8),
            Text(indicadores,
                style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
