import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/abastecimento.dart';
import '../providers/app_provider.dart';
import '../utils/formatadores.dart';

class AbastecimentoFormScreen extends StatefulWidget {
  const AbastecimentoFormScreen({super.key});

  @override
  State<AbastecimentoFormScreen> createState() =>
      _AbastecimentoFormScreenState();
}

class _AbastecimentoFormScreenState extends State<AbastecimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _precoCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _litrosCtrl = TextEditingController();

  TipoCombustivel _tipo = TipoCombustivel.gasolina;
  DateTime _dataHora = DateTime.now();
  bool _salvando = false;

  static final _somenteNumeros =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

  @override
  void dispose() {
    _precoCtrl.dispose();
    _kmCtrl.dispose();
    _litrosCtrl.dispose();
    super.dispose();
  }

  /// Preço x litros, atualizado enquanto o usuário digita.
  double? get _valorTotal {
    final preco = parseDecimal(_precoCtrl.text);
    final litros = parseDecimal(_litrosCtrl.text);
    if (preco == null || litros == null) return null;
    return preco * litros;
  }

  Future<void> _escolherDataHora() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
    );
    if (hora == null || !mounted) return;

    setState(() {
      _dataHora =
          DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    });
  }

  Future<void> _salvar() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = context.read<AppProvider>();

    if (_dataHora.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      messenger.showSnackBar(const SnackBar(
          content: Text('A data e o horário não podem estar no futuro.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final abastecimento = Abastecimento(
      veiculoId: provider.veiculo!.id!,
      tipo: _tipo,
      precoPorLitro: parseDecimal(_precoCtrl.text)!,
      quilometragem: parseDecimal(_kmCtrl.text)!,
      litros: parseDecimal(_litrosCtrl.text)!,
      dataHora: _dataHora,
    );

    setState(() => _salvando = true);
    try {
      await provider.adicionarAbastecimento(abastecimento);
      navigator.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Abastecimento registrado.')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Erro ao salvar o abastecimento.')));
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _valorTotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo abastecimento')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Tipo de combustível',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<TipoCombustivel>(
                segments: TipoCombustivel.values
                    .map((t) => ButtonSegment(value: t, label: Text(t.rotulo)))
                    .toList(),
                selected: {_tipo},
                onSelectionChanged: (s) => setState(() => _tipo = s.first),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _precoCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_somenteNumeros],
                decoration: const InputDecoration(
                  labelText: 'Preço por litro (R\$)',
                  prefixText: r'R$ ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (texto) {
                  final v = parseDecimal(texto);
                  if (v == null) return 'Informe o preço por litro';
                  if (v <= 0 || v > 50) return 'Preço inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _kmCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_somenteNumeros],
                decoration: const InputDecoration(
                  labelText: 'Quilometragem atual',
                  suffixText: 'km',
                  border: OutlineInputBorder(),
                ),
                validator: (texto) {
                  final v = parseDecimal(texto);
                  if (v == null) return 'Informe a quilometragem';
                  if (v < 0) return 'Quilometragem inválida';
                  return context
                      .read<AppProvider>()
                      .validarQuilometragem(_dataHora, v);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _litrosCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_somenteNumeros],
                decoration: const InputDecoration(
                  labelText: 'Litros abastecidos',
                  suffixText: 'L',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (texto) {
                  final v = parseDecimal(texto);
                  if (v == null) return 'Informe a quantidade de litros';
                  if (v <= 0 || v > 500) return 'Quantidade inválida';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _escolherDataHora,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data e horário',
                    suffixIcon: Icon(Icons.calendar_month),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(formatarDataHora(_dataHora)),
                ),
              ),
              const SizedBox(height: 20),

              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Valor total'),
                      Text(
                        total == null ? '—' : formatarMoeda(total),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Salvar abastecimento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
