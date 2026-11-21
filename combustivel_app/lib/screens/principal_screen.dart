import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'abastecimento_form_screen.dart';
import 'abastecimentos_list_screen.dart';
import 'dashboard_screen.dart';

/// Tela principal com duas abas: Abastecimentos e Dashboard.
class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  int _indice = 0;

  void _novoAbastecimento() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AbastecimentoFormScreen()),
    );
  }

  /// Pede confirmação e exclui o veículo junto com seus abastecimentos.
  /// Depois da exclusão, a HomeScreen volta sozinha para o cadastro,
  /// pois o AppProvider passa a ter veiculo == null.
  Future<void> _confirmarExclusaoVeiculo() async {
    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final veiculo = provider.veiculo!;
    final quantidade = provider.abastecimentos.length;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Excluir veículo?'),
        content: Text(
          '${veiculo.marca} ${veiculo.modelo} (${veiculo.ano})\n\n'
          '${quantidade == 0 ? 'Nenhum abastecimento está registrado.' : '$quantidade abastecimento(s) registrado(s) também será(ão) excluído(s).'}\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou != true) return;

    try {
      await provider.excluirVeiculo();
      messenger.showSnackBar(const SnackBar(
        content: Text('Veículo e abastecimentos excluídos.'),
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Não foi possível excluir o veículo.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final veiculo = context.watch<AppProvider>().veiculo;
    // Durante a troca de tela após a exclusão, o veículo já pode ser null.
    if (veiculo == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${veiculo.marca} ${veiculo.modelo}',
                overflow: TextOverflow.ellipsis),
            Text(
              'Ano ${veiculo.ano} • Motor ${veiculo.cilindrada} L',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            onSelected: (opcao) {
              if (opcao == 'excluir') _confirmarExclusaoVeiculo();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'excluir',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Excluir veículo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _indice,
        children: const [
          AbastecimentosListScreen(),
          DashboardScreen(),
        ],
      ),
      floatingActionButton: _indice == 0
          ? FloatingActionButton.extended(
              onPressed: _novoAbastecimento,
              icon: const Icon(Icons.add),
              label: const Text('Abastecer'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.local_gas_station), label: 'Abastecimentos'),
          NavigationDestination(
              icon: Icon(Icons.show_chart), label: 'Dashboard'),
        ],
      ),
    );
  }
}
