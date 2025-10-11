import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:vigilancia_app/models/cliente.dart';
import 'package:vigilancia_app/services/auth_service.dart';
import 'package:vigilancia_app/services/database_service.dart';

class CadastroClienteScreen extends StatefulWidget {
  final Cliente? cliente;
  
  const CadastroClienteScreen({super.key, this.cliente});

  @override
  State<CadastroClienteScreen> createState() => _CadastroClienteScreenState();
}

class _CadastroClienteScreenState extends State<CadastroClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _valorController = TextEditingController();
  
  // Máscara para telefone: +55 44999999999
  final _telefoneMaskFormatter = MaskTextInputFormatter(
    mask: '+55 ###########',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  
  String _modalidadeSelecionada = 'Residencial';
  final List<String> _modalidades = [
    'Residencial',
    'Comercial',
    'Industrial',
  ];
  
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa o campo de rua com "Rua "
    _ruaController.text = 'Rua ';
    _ruaController.selection = TextSelection.fromPosition(
      TextPosition(offset: _ruaController.text.length),
    );
    
    if (widget.cliente != null) {
      _preencherCampos();
    }
    
    // Listener para garantir que "Rua " sempre esteja no início
    _ruaController.addListener(_garantirRuaNoInicio);
    // Listener para formatar valor com decimais
    _valorController.addListener(_formatarValor);
  }

  void _garantirRuaNoInicio() {
    final text = _ruaController.text;
    if (!text.startsWith('Rua ')) {
      // Extrai apenas o que vem depois de "Rua " se houver
      String novoTexto = text.replaceFirst(RegExp(r'^[Rr]ua\s*'), '');
      _ruaController.removeListener(_garantirRuaNoInicio);
      _ruaController.text = 'Rua $novoTexto';
      _ruaController.selection = TextSelection.fromPosition(
        TextPosition(offset: _ruaController.text.length),
      );
      _ruaController.addListener(_garantirRuaNoInicio);
    }
    
    // Não permite apagar "Rua "
    if (text.length < 4) {
      _ruaController.removeListener(_garantirRuaNoInicio);
      _ruaController.text = 'Rua ';
      _ruaController.selection = TextSelection.fromPosition(
        TextPosition(offset: 4),
      );
      _ruaController.addListener(_garantirRuaNoInicio);
    }
  }

  bool _isFormattingValor = false;
  String _lastValidValor = '';
  
  String _formatarValorBrasileiro(double valor) {
    // Formata no padrão brasileiro: 100.000,00
    final inteiro = valor.floor();
    final decimal = ((valor - inteiro) * 100).round();
    
    // Formata a parte inteira com pontos
    String inteiroFormatado = inteiro.toString();
    String resultado = '';
    int contador = 0;
    
    for (int i = inteiroFormatado.length - 1; i >= 0; i--) {
      if (contador == 3) {
        resultado = '.$resultado';
        contador = 0;
      }
      resultado = inteiroFormatado[i] + resultado;
      contador++;
    }
    
    // Adiciona a parte decimal com vírgula
    return '$resultado,${decimal.toString().padLeft(2, '0')}';
  }
  
  void _formatarValor() {
    if (_isFormattingValor) return;
    
    _isFormattingValor = true;
    
    String text = _valorController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) {
      _valorController.clear();
      _lastValidValor = '';
      _isFormattingValor = false;
      return;
    }
    
    // Limita a 1 milhão (100000000 centavos)
    int valor = int.tryParse(text) ?? 0;
    if (valor > 100000000) {
      // Se ultrapassar, mantém o último valor válido
      if (_lastValidValor.isNotEmpty) {
        _valorController.value = TextEditingValue(
          text: _lastValidValor,
          selection: TextSelection.collapsed(offset: _lastValidValor.length),
        );
      }
      _isFormattingValor = false;
      return;
    }
    
    // Formata com 2 casas decimais no padrão brasileiro
    double valorDecimal = valor / 100.0;
    String valorFormatado = _formatarValorBrasileiro(valorDecimal);
    
    final cursorPosition = _valorController.selection.baseOffset;
    final lengthBefore = _valorController.text.length;
    
    _valorController.value = TextEditingValue(
      text: valorFormatado,
      selection: TextSelection.collapsed(
        offset: (cursorPosition + (valorFormatado.length - lengthBefore)).clamp(0, valorFormatado.length),
      ),
    );
    
    // Salva como último valor válido
    _lastValidValor = valorFormatado;
    
    _isFormattingValor = false;
  }

  void _preencherCampos() {
    final cliente = widget.cliente!;
    _nomeController.text = cliente.nome;
    
    // Formata o telefone garantindo o padrão +55
    String telefoneFormatado = cliente.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!telefoneFormatado.startsWith('55')) {
      telefoneFormatado = '55$telefoneFormatado';
    }
    _telefoneController.text = _telefoneMaskFormatter.formatEditUpdate(
      const TextEditingValue(),
      TextEditingValue(text: telefoneFormatado),
    ).text;
    
    _cidadeController.text = cliente.cidade;
    
    // Garante que a rua tenha "Rua " no início
    String rua = cliente.rua;
    if (!rua.startsWith('Rua ')) {
      rua = rua.replaceFirst(RegExp(r'^[Rr]ua\s*'), '');
      rua = 'Rua $rua';
    }
    _ruaController.text = rua;
    
    _bairroController.text = cliente.bairro;
    _numeroController.text = cliente.numero;
    final valorFormatado = _formatarValorBrasileiro(cliente.valor);
    _valorController.text = valorFormatado;
    _lastValidValor = valorFormatado; // Salva o valor inicial como válido
    _modalidadeSelecionada = cliente.modalidade;
  }

  @override
  void dispose() {
    _ruaController.removeListener(_garantirRuaNoInicio);
    _valorController.removeListener(_formatarValor);
    _nomeController.dispose();
    _telefoneController.dispose();
    _cidadeController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _numeroController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvarCliente() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Converte o valor brasileiro (100.000,00) para double
        String valorTexto = _valorController.text;
        valorTexto = valorTexto.replaceAll('.', ''); // Remove pontos dos milhares
        valorTexto = valorTexto.replaceAll(',', '.'); // Troca vírgula por ponto
        final valorDouble = double.tryParse(valorTexto) ?? 0.0;
        
        final cliente = Cliente(
          id: widget.cliente?.id ?? '',
          nome: _nomeController.text.trim(),
          telefone: _telefoneController.text.trim(),
          cidade: _cidadeController.text.trim(),
          rua: _ruaController.text.trim(),
          bairro: _bairroController.text.trim(),
          numero: _numeroController.text.trim(),
          modalidade: _modalidadeSelecionada,
          valor: valorDouble,
          statusPagamento: widget.cliente?.statusPagamento ?? {},
          dataCadastro: widget.cliente?.dataCadastro, // Preserva a data de cadastro original
          status: widget.cliente?.status ?? 'ativo', // Preserva o status do cliente
        );

        final user = _authService.currentUser;
        if (user != null) {
          if (widget.cliente != null) {
            await _databaseService.updateCliente(user.uid, cliente.id, cliente);
          } else {
            await _databaseService.createCliente(user.uid, cliente);
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.cliente != null 
                    ? 'Cliente atualizado com sucesso!' 
                    : 'Cliente cadastrado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar cliente: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cliente != null 
            ? 'Editar Cliente' 
            : 'Cadastre um novo cliente'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person, color: Colors.white70),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o nome do cliente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_telefoneMaskFormatter],
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      hintText: '+55 44999999999',
                      prefixIcon: Icon(Icons.phone, color: Colors.white70),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o telefone do cliente';
                      }
                      // Remove espaços e valida se tem 13 dígitos (+55 + DDD + número)
                      final telefoneNumeros = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (telefoneNumeros.length < 12) {
                        return 'Telefone incompleto (mínimo 12 dígitos)';
                      }
                      if (telefoneNumeros.length > 13) {
                        return 'Telefone inválido (máximo 13 dígitos)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _cidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      prefixIcon: Icon(Icons.location_city, color: Colors.white70),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite a cidade';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _ruaController,
                    decoration: const InputDecoration(
                      labelText: 'Rua',
                      hintText: 'Rua das Flores',
                      prefixIcon: Icon(Icons.streetview, color: Colors.white70),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || value == 'Rua ') {
                        return 'Digite o nome da rua';
                      }
                      if (value.trim().length <= 4) {
                        return 'Digite o nome da rua';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _bairroController,
                    decoration: const InputDecoration(
                      labelText: 'Bairro',
                      prefixIcon: Icon(Icons.location_on, color: Colors.white70),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o bairro';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _numeroController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número',
                      prefixIcon: Icon(Icons.numbers, color: Colors.white70),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o número';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _modalidadeSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Modalidade',
                      prefixIcon: Icon(Icons.category, color: Colors.white70),
                    ),
                    items: _modalidades.map((String modalidade) {
                      return DropdownMenuItem<String>(
                        value: modalidade,
                        child: Text(modalidade),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _modalidadeSelecionada = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _valorController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Valor (R\$)',
                      hintText: '0,00',
                      prefixIcon: Icon(Icons.attach_money, color: Colors.white70),
                      helperMaxLines: 2,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o valor';
                      }
                      // Converte formato brasileiro para double
                      String valorTexto = value.replaceAll('.', '').replaceAll(',', '.');
                      final valorDouble = double.tryParse(valorTexto);
                      if (valorDouble == null) {
                        return 'Digite um valor válido';
                      }
                      if (valorDouble > 1000000) {
                        return 'Valor máximo: R\$ 1.000.000,00';
                      }
                      if (valorDouble <= 0) {
                        return 'Digite um valor maior que zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _salvarCliente,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.cliente != null ? 'Atualizar' : 'Cadastrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
