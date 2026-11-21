import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/marca.dart';
import '../models/veiculo.dart';
import '../providers/app_provider.dart';
import '../services/fipe_service.dart';

class VeiculoFormScreen extends StatefulWidget {
  const VeiculoFormScreen({super.key});

  @override
  State<VeiculoFormScreen> createState() => _VeiculoFormScreenState();
}

class _VeiculoFormScreenState extends State<VeiculoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fipe = FipeService();
  final _anoCtrl = TextEditingController();
  final _cilindradaCtrl = TextEditingController();

  List<Marca> _marcas = [];
  List<String> _modelos = [];
  Marca? _marca;
  String? _modelo;

  bool _carregandoMarcas = true;
  bool _carregandoModelos = false;
  bool _salvando = false;
  String? _erroMarcas;
  String? _erroModelos;

  // Evita que uma resposta antiga sobrescreva a lista da marca atual.
  int _tokenModelos = 0;

  @override
  void initState() {
    super.initState();
    _carregarMarcas();
  }

  @override
  void dispose() {
    _anoCtrl.dispose();
    _cilindradaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarMarcas() async {
    setState(() {
      _carregandoMarcas = true;
      _erroMarcas = null;
    });
    try {
      final marcas = await _fipe.buscarMarcas();
      if (!mounted) return;
      setState(() => _marcas = marcas);
    } on FipeException catch (e) {
      if (!mounted) return;
      setState(() => _erroMarcas = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregandoMarcas = false);
    }
  }

  void _selecionarMarca(Marca? marca) {
    setState(() {
      _marca = marca;
      _modelo = null; // modelos dependem da marca
      _modelos = [];
      _erroModelos = null;
    });
    if (marca != null) _carregarModelos(marca);
  }

  Future<void> _carregarModelos(Marca marca) async {
    final token = ++_tokenModelos;
    setState(() {
      _carregandoModelos = true;
      _erroModelos = null;
    });
    try {
      final modelos = await _fipe.buscarModelos(marca.codigo);
      if (!mounted || token != _tokenModelos) return;
      setState(() => _modelos = modelos);
    } on FipeException catch (e) {
      if (!mounted || token != _tokenModelos) return;
      setState(() => _erroModelos = e.mensagem);
    } finally {
      if (mounted && token == _tokenModelos) {
        setState(() => _carregandoModelos = false);
      }
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final cilindrada =
        double.parse(_cilindradaCtrl.text.trim().replaceAll(',', '.'));
    final veiculo = Veiculo(
      marca: _marca!.nome,
      modelo: _modelo!,
      ano: int.parse(_anoCtrl.text.trim()),
      cilindrada: cilindrada.toStringAsFixed(1),
    );

    final provider = context.read<AppProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _salvando = true);
    try {
      // Ao salvar, o AppProvider notifica e a HomeScreen troca de tela.
      await provider.salvarVeiculo(veiculo);
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Erro ao salvar o veículo.')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String? _validarAno(String? texto) {
    final ano = int.tryParse((texto ?? '').trim());
    final limite = DateTime.now().year + 1;
    if (ano == null) return 'Informe o ano';
    if (ano < 1950 || ano > limite) return 'Ano entre 1950 e $limite';
    return null;
  }

  String? _validarCilindrada(String? texto) {
    final valor = double.tryParse((texto ?? '').trim().replaceAll(',', '.'));
    if (valor == null) return 'Informe a cilindrada (ex.: 1.6)';
    if (valor < 0.5 || valor > 9.9) return 'Valor entre 0,5 e 9,9';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar veículo')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Cadastre seu veículo para começar a registrar abastecimentos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // ---------- Marca ----------
              if (_carregandoMarcas)
                const _Carregando(texto: 'Carregando marcas...')
              else if (_erroMarcas != null)
                _ErroComRetry(mensagem: _erroMarcas!, onTentar: _carregarMarcas)
              else
                DropdownButtonFormField<Marca>(
                  // ignore: deprecated_member_use
                  value: _marca,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(),
                  ),
                  items: _marcas
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.nome, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: _selecionarMarca,
                  validator: (v) => v == null ? 'Selecione a marca' : null,
                ),
              const SizedBox(height: 16),

              // ---------- Modelo ----------
              if (_carregandoModelos)
                const _Carregando(texto: 'Carregando modelos...')
              else if (_erroModelos != null)
                _ErroComRetry(
                  mensagem: _erroModelos!,
                  onTentar: () => _carregarModelos(_marca!),
                )
              else
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _modelo,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Modelo',
                    helperText:
                        _marca == null ? 'Escolha a marca primeiro' : null,
                    border: const OutlineInputBorder(),
                  ),
                  items: _modelos
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: _marca == null
                      ? null
                      : (v) => setState(() => _modelo = v),
                  validator: (v) => v == null ? 'Selecione o modelo' : null,
                ),
              const SizedBox(height: 16),

              // ---------- Ano ----------
              TextFormField(
                controller: _anoCtrl,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: _validarAno,
              ),
              const SizedBox(height: 16),

              // ---------- Cilindrada ----------
              TextFormField(
                controller: _cilindradaCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cilindrada do motor (L)',
                  hintText: 'Ex.: 1.0, 1.6, 2.0',
                  border: OutlineInputBorder(),
                ),
                validator: _validarCilindrada,
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
                label: const Text('Salvar veículo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Carregando extends StatelessWidget {
  final String texto;
  const _Carregando({required this.texto});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(texto),
          ],
        ),
      );
}

class _ErroComRetry extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentar;
  const _ErroComRetry({required this.mensagem, required this.onTentar});

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Text(mensagem)),
              TextButton(
                  onPressed: onTentar, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
}
