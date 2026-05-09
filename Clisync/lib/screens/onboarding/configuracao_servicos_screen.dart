import 'package:flutter/material.dart';
import 'package:clisync/models/usuario.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/theme/app_theme.dart';

class ConfiguracaoServicosScreen extends StatefulWidget {
  final Usuario usuario;

  const ConfiguracaoServicosScreen({super.key, required this.usuario});

  @override
  State<ConfiguracaoServicosScreen> createState() => _ConfiguracaoServicosScreenState();
}

class _ServicoItem {
  final TextEditingController nomeController;
  final TextEditingController valorController;
  final GlobalKey<FormState> formKey;

  _ServicoItem({
    required this.nomeController,
    required this.valorController,
    required this.formKey,
  });
}

class _ConfiguracaoServicosScreenState extends State<ConfiguracaoServicosScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_ServicoItem> _servicosUnicos = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializar serviços únicos existentes
    try {
      if (widget.usuario.servicosUnicos.isNotEmpty) {
        widget.usuario.servicosUnicos.forEach((nome, valor) {
          _adicionarServicoUnico(nome: nome, valor: valor.toString());
        });
      } else {
        // Se não houver, adiciona um campo vazio inicial
        _adicionarServicoUnico();
      }
    } catch (e) {
      // Se houver erro, adiciona um campo vazio
      _adicionarServicoUnico();
    }
  }
  
  void _adicionarServicoUnico({String? nome, String? valor}) {
    setState(() {
      _servicosUnicos.add(_ServicoItem(
        nomeController: TextEditingController(text: nome ?? ''),
        valorController: TextEditingController(text: valor ?? ''),
        formKey: GlobalKey<FormState>(),
      ));
    });
  }
  
  void _removerServicoUnico(int index) {
    setState(() {
      _servicosUnicos[index].nomeController.dispose();
      _servicosUnicos[index].valorController.dispose();
      _servicosUnicos.removeAt(index);
      if (_servicosUnicos.isEmpty) {
        _adicionarServicoUnico();
      }
    });
  }
  
  @override
  void dispose() {
    for (var servico in _servicosUnicos) {
      servico.nomeController.dispose();
      servico.valorController.dispose();
    }
    super.dispose();
  }

  Future<void> _salvarServicos() async {
    if (_isSaving) return;

    // Coletar serviços únicos
    final Map<String, double> servicosUnicos = {};
    bool temServicoUnicoValido = false;
    for (var servico in _servicosUnicos) {
      final nome = servico.nomeController.text.trim();
      final valorStr = servico.valorController.text.trim();
      if (nome.isNotEmpty && valorStr.isNotEmpty) {
        final valor = double.tryParse(valorStr.replaceAll(',', '.'));
        if (valor != null && valor > 0) {
          servicosUnicos[nome] = valor;
          temServicoUnicoValido = true;
        }
      }
    }
    
    // Validar se há pelo menos 1 serviço preenchido
    if (!temServicoUnicoValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('É necessário cadastrar pelo menos 1 serviço'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final usuarioAtualizado = widget.usuario.copyWith(
      servicosUnicos: servicosUnicos,
      servicosRecorrentes: {}, // Limpa serviços recorrentes
    );

    try {
      await DatabaseService().updateUser(usuarioAtualizado);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar serviços: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _validaValor(String? value, String? nome) {
    final nomePreenchido = nome != null && nome.trim().isNotEmpty;
    final valorStr = value?.trim() ?? '';
    final valorPreenchido = valorStr.isNotEmpty;
    
    // Se o nome está preenchido, o valor é obrigatório
    if (nomePreenchido && !valorPreenchido) {
      return 'Obrigatório';
    }
    
    // Se o valor está preenchido, valida o formato
    if (valorPreenchido) {
      final valor = double.tryParse(valorStr.replaceAll(',', '.'));
      if (valor == null) {
        return 'Digite um valor válido';
      }
      if (valor <= 0) {
        return 'Valor deve ser maior que zero';
      }
    }
    
    return null;
  }
  
  String? _validaNomeServico(String? value, String? valor) {
    final nomePreenchido = value != null && value.trim().isNotEmpty;
    final valorPreenchido = valor != null && valor.trim().isNotEmpty;
    
    // Se o valor está preenchido, o nome é obrigatório
    if (valorPreenchido && !nomePreenchido) {
      return 'Nome é obrigatório';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Serviços'),
        centerTitle: true,
      ),
      body: _servicosUnicos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.room_service,
                    size: 80,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum serviço cadastrado',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Toque no botão + para adicionar um novo serviço',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
                      itemCount: _servicosUnicos.length + 1,
                      itemBuilder: (context, index) {
                        // Primeiro item: texto explicativo
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Defina os serviços que você oferece aos seus clientes. Essas informações serão usadas no formulário de agendamento.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                                height: 1.5,
                              ),
                            ),
                          );
                        }
                        
                        final servico = _servicosUnicos[index - 1];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12, right: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: servico.nomeController,
                                        decoration: const InputDecoration(
                                          labelText: 'Nome do Serviço',
                                          isDense: true,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        validator: (value) => _validaNomeServico(
                                          value,
                                          servico.valorController.text,
                                        ),
                                        onChanged: (_) {
                                          _formKey.currentState?.validate();
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: _servicosUnicos.length > 1
                                          ? () => _removerServicoUnico(index - 1)
                                          : null,
                                      tooltip: 'Remover serviço',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [

                                    Expanded(
                                      child: TextFormField(
                                        controller: servico.valorController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(
                                          labelText: 'Valor',
                                          isDense: true,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        validator: (value) => _validaValor(
                                          value,
                                          servico.nomeController.text,
                                        ),
                                        onChanged: (_) {
                                          _formKey.currentState?.validate();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  _salvarServicos();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                            : Padding(padding: const EdgeInsets.fromLTRB(5, 0, 5, 0), child: const Text(
                                'Salvar Serviços',
                                style: TextStyle(fontSize: 16),
                              )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _adicionarServicoUnico(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

