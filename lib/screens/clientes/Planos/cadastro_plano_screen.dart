import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:clisync/models/plano.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/theme/app_theme.dart';
import 'package:clisync/screens/clientes/Planos/editor_texto_descricao_screen.dart';

class CadastroPlanoScreen extends StatefulWidget {
  final Plano? plano;

  const CadastroPlanoScreen({super.key, this.plano});

  @override
  State<CadastroPlanoScreen> createState() => _CadastroPlanoScreenState();
}

class _CadastroPlanoScreenState extends State<CadastroPlanoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final AuthService _authService = AuthService();
  
  String _frequenciaSelecionada = 'mensal';
  bool _isSaving = false;

  final List<String> _frequencias = [
    'mensal',
    'semanal',
    'quinzenal',
    'trimestral',
    'semestral',
    'anual',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.plano != null) {
      _nomeController.text = widget.plano!.nome;
      _valorController.text = widget.plano!.valor.toStringAsFixed(2);
      _descricaoController.text = widget.plano!.descricao;
      _frequenciaSelecionada = widget.plano!.frequencia;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _salvarPlano() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final user = _authService.currentUser;
        if (user == null) {
          throw Exception('Usuário não autenticado');
        }

        final plano = Plano(
          id: widget.plano?.id,
          nome: _nomeController.text.trim(),
          valor: double.parse(_valorController.text.replaceAll(',', '.')),
          frequencia: _frequenciaSelecionada,
          descricao: _descricaoController.text.trim(),
          status: widget.plano?.status ?? 'ativo', // Preserva o status ao editar
        );

        final planosRef = _database
            .child('usuarios')
            .child(user.uid)
            .child('planos');

        if (plano.id != null) {
          // Atualizar plano existente
          await planosRef.child(plano.id!).update(plano.toMap());
        } else {
          // Criar novo plano
          await planosRef.push().set(plano.toMap());
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.plano != null
                  ? 'Plano atualizado com sucesso!'
                  : 'Plano criado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar plano: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plano != null ? 'Editar Plano' : 'Novo Plano'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nome do Plano
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Plano *',
                  hintText: 'Ex: Plano Básico',
                  prefixIcon: Icon(Icons.card_giftcard),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O nome do plano é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Valor
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$) *',
                  hintText: 'Ex: 30.00',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O valor é obrigatório';
                  }
                  final valor = double.tryParse(value.replaceAll(',', '.'));
                  if (valor == null || valor <= 0) {
                    return 'Digite um valor válido maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Frequência
              DropdownButtonFormField<String>(
                value: _frequenciaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Frequência *',
                  prefixIcon: Icon(Icons.repeat),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
                dropdownColor: AppTheme.surfaceColor,
                items: _frequencias.map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text(
                      freq[0].toUpperCase() + freq.substring(1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _frequenciaSelecionada = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione uma frequência';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              Card(
                color: AppTheme.surfaceColor,
                child: InkWell(
                  onTap: () async {
                    final resultado = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditorTextoDescricaoScreen(
                          textoInicial: _descricaoController.text,
                        ),
                      ),
                    );
                    if (resultado != null) {
                      setState(() {
                        _descricaoController.text = resultado;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.description,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Descrição',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: AppTheme.accentColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_descricaoController.text.isEmpty)
                          Text(
                            'Toque para adicionar uma descrição detalhada do plano...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            ),
                          )
                        else
                          Text(
                            _descricaoController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (_descricaoController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${_descricaoController.text.split('\n').length} linhas • ${_descricaoController.text.length} caracteres',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão Salvar
              ElevatedButton(
                onPressed: _isSaving ? null : _salvarPlano,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.plano != null ? 'Atualizar Plano' : 'Salvar Plano',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

