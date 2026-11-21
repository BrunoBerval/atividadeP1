import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import 'principal_screen.dart';
import 'veiculo_form_screen.dart';

/// Decide qual tela mostrar:
///  - carregando  -> indicador de progresso
///  - sem veículo -> formulário de cadastro
///  - com veículo -> tela principal (abastecimentos e dashboard)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    if (app.carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (app.veiculo == null) return const VeiculoFormScreen();
    return const PrincipalScreen();
  }
}
