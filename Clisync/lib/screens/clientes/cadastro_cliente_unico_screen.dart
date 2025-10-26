import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:clisync/models/cliente_unico.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/screens/clientes/configuracao_clientes_unicos_screen.dart';
import 'package:clisync/services/config_unique_service.dart';

class CadastroClienteUnicoScreen extends StatefulWidget {
  final ClienteUnico? clienteUnico;
  
  const CadastroClienteUnicoScreen({super.key, this.clienteUnico});

  @override
  State<CadastroClienteUnicoScreen> createState() => _CadastroClienteUnicoScreenState();
}

class _CadastroClienteUnicoScreenState extends State<CadastroClienteUnicoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _valorController = TextEditingController();
  final _frequenciaController = TextEditingController();
  final _horarioServicoController = TextEditingController();
  final _dataServicoController = TextEditingController();
  final _prioridadeController = TextEditingController();
  final _dataVencimentoController = TextEditingController();
  
  // Controladores para campos personalizados
  final Map<String, TextEditingController> _camposPersonalizadosControllers = {};
  
  // Máscara para telefone: +55 44999999999
  final _telefoneMaskFormatter = MaskTextInputFormatter(
    mask: '+55 ###########',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  
  
  String? _tipoServicoSelecionado;
  List<String> _tiposServico = [];
  
  // Variáveis para datas e horários
  DateTime? _dataServicoSelecionada;
  DateTime? _dataVencimentoSelecionada;
  TimeOfDay? _horarioServicoSelecionado;
  
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isLoadingConfig = true;
  
  // Configuração de campos ativos
  List<String> _camposAtivos = [];
  Map<String, bool> _camposPersonalizados = {};

  @override
  void initState() {
    super.initState();
    _carregarConfiguracao();
    
    // Inicializa o campo de rua com "Rua "
    _ruaController.text = 'Rua ';
    _ruaController.selection = TextSelection.fromPosition(
      TextPosition(offset: _ruaController.text.length),
    );
    
    if (widget.clienteUnico != null) {
      _preencherCampos();
    }
    
    // Listener para garantir que "Rua " sempre esteja no início
    _ruaController.addListener(_garantirRuaNoInicio);
    // Listener para formatar valor com decimais
    _valorController.addListener(_formatarValor);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarrega a configuração quando a tela volta do foco (ex: da tela de configuração)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _carregarConfiguracao(isReload: true);
      }
    });
  }

  Future<void> _carregarConfiguracao({bool isReload = false}) async {
    try {
      final camposAtivos = await ConfigUniqueService.obterCamposAtivos();
      final tiposServico = await ConfigUniqueService.obterTiposServico();
      final config = await ConfigUniqueService.carregarConfiguracaoCampos();
      
      setState(() {
        _camposAtivos = camposAtivos;
        _tiposServico = tiposServico;
        _camposPersonalizados = Map<String, bool>.from(config['camposPersonalizados']);
        if (!isReload) {
          _isLoadingConfig = false;
        }
      });
      
      // Inicializa controladores para campos personalizados
      for (final entry in _camposPersonalizados.entries) {
        final campo = entry.key;
        final ativo = entry.value;
        if (ativo && !_camposPersonalizadosControllers.containsKey(campo)) {
          _camposPersonalizadosControllers[campo] = TextEditingController();
        }
      }
      
    } catch (e) {
      // Em caso de erro, usa configuração padrão
      setState(() {
        _camposAtivos = ['Nome', 'Telefone', 'Valor'];
        _tiposServico = ConfigUniqueService.tiposServicoPadrao;
        if (!isReload) {
          _isLoadingConfig = false;
        }
      });
    }
  }

  // Método para selecionar data do serviço
  Future<void> _selecionarDataServico() async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataServicoSelecionada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (dataSelecionada != null) {
      setState(() {
        _dataServicoSelecionada = dataSelecionada;
        _dataServicoController.text = DateFormat('dd/MM/yyyy').format(dataSelecionada);
      });
    }
  }

  // Método para selecionar data de vencimento do pagamento
  Future<void> _selecionarDataVencimento() async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataVencimentoSelecionada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (dataSelecionada != null) {
      setState(() {
        _dataVencimentoSelecionada = dataSelecionada;
        _dataVencimentoController.text = DateFormat('dd/MM/yyyy').format(dataSelecionada);
      });
    }
  }

  // Método para selecionar horário do serviço
  Future<void> _selecionarHorarioServico() async {
    final TimeOfDay? horarioSelecionado = await showTimePicker(
      context: context,
      initialTime: _horarioServicoSelecionado ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (horarioSelecionado != null) {
      setState(() {
        _horarioServicoSelecionado = horarioSelecionado;
        _horarioServicoController.text = '${horarioSelecionado.hour.toString().padLeft(2, '0')}:${horarioSelecionado.minute.toString().padLeft(2, '0')}';
      });
    }
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
    final clienteUnico = widget.clienteUnico!;
    _nomeController.text = clienteUnico.nome;
    
    // Formata o telefone garantindo o padrão +55
    String telefoneFormatado = clienteUnico.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!telefoneFormatado.startsWith('55')) {
      telefoneFormatado = '55$telefoneFormatado';
    }
    _telefoneController.text = _telefoneMaskFormatter.formatEditUpdate(
      const TextEditingValue(),
      TextEditingValue(text: telefoneFormatado),
    ).text;
    
    _cidadeController.text = clienteUnico.cidade;
    
    // Garante que a rua tenha "Rua " no início
    String rua = clienteUnico.rua;
    if (!rua.startsWith('Rua ')) {
      rua = rua.replaceFirst(RegExp(r'^[Rr]ua\s*'), '');
      rua = 'Rua $rua';
    }
    _ruaController.text = rua;
    
    _bairroController.text = clienteUnico.bairro;
    _numeroController.text = clienteUnico.numero;
    final valorFormatado = _formatarValorBrasileiro(clienteUnico.valor);
    _valorController.text = valorFormatado;
    _lastValidValor = valorFormatado; // Salva o valor inicial como válido
    
    // Preenche os novos campos dinâmicos
    _tipoServicoSelecionado = clienteUnico.tipoServico;
    _frequenciaController.text = clienteUnico.frequencia ?? '';
    
    // Preenche horário do serviço
    if (clienteUnico.horarioServico != null && clienteUnico.horarioServico!.isNotEmpty) {
      _horarioServicoController.text = clienteUnico.horarioServico!;
      // Tenta converter o horário para TimeOfDay
      try {
        final partes = clienteUnico.horarioServico!.split(':');
        if (partes.length == 2) {
          _horarioServicoSelecionado = TimeOfDay(
            hour: int.parse(partes[0]),
            minute: int.parse(partes[1]),
          );
        }
      } catch (e) {
        // Se não conseguir converter, mantém como texto
      }
    }
    
    // Preenche data do serviço
    if (clienteUnico.dataServico != null && clienteUnico.dataServico!.isNotEmpty) {
      _dataServicoController.text = clienteUnico.dataServico!;
      // Tenta converter a data para DateTime
      try {
        _dataServicoSelecionada = DateFormat('dd/MM/yyyy').parse(clienteUnico.dataServico!);
      } catch (e) {
        // Se não conseguir converter, mantém como texto
      }
    }
    
    _prioridadeController.text = clienteUnico.prioridade ?? '';
    
    // Preenche data de vencimento
    if (clienteUnico.dataVencimento != null && clienteUnico.dataVencimento!.isNotEmpty) {
      _dataVencimentoController.text = clienteUnico.dataVencimento!;
      // Tenta converter a data para DateTime
      try {
        _dataVencimentoSelecionada = DateFormat('dd/MM/yyyy').parse(clienteUnico.dataVencimento!);
      } catch (e) {
        // Se não conseguir converter, mantém como texto
      }
    }
    
    // Preenche campos personalizados
    for (final entry in clienteUnico.camposPersonalizados.entries) {
      final campo = entry.key;
      final valor = entry.value;
      if (_camposPersonalizadosControllers.containsKey(campo)) {
        _camposPersonalizadosControllers[campo]!.text = valor;
      }
    }
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
    _frequenciaController.dispose();
    _horarioServicoController.dispose();
    _dataServicoController.dispose();
    _prioridadeController.dispose();
    _dataVencimentoController.dispose();
    
    // Dispose dos controladores personalizados
    for (final controller in _camposPersonalizadosControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _salvarClienteUnico() async {
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
        
        // Coleta dados dos campos personalizados
        final camposPersonalizados = <String, String>{};
        for (final entry in _camposPersonalizadosControllers.entries) {
          final campo = entry.key;
          final controller = entry.value;
          if (controller.text.isNotEmpty) {
            camposPersonalizados[campo] = controller.text.trim();
          }
        }
        
        final clienteUnico = ClienteUnico(
          id: widget.clienteUnico?.id ?? '',
          nome: _nomeController.text.trim(),
          telefone: _telefoneController.text.trim(),
          cidade: _cidadeController.text.trim(),
          rua: _ruaController.text.trim(),
          bairro: _bairroController.text.trim(),
          numero: _numeroController.text.trim(),
          modalidade: 'Residencial', // Valor padrão fixo
          valor: valorDouble,
          dataCadastro: widget.clienteUnico?.dataCadastro, // Preserva a data de cadastro original
          status: widget.clienteUnico?.status ?? 'ativo', // Preserva o status do cliente
          tipoServico: _tipoServicoSelecionado,
          frequencia: _frequenciaController.text.trim().isNotEmpty ? _frequenciaController.text.trim() : null,
          horarioServico: _horarioServicoController.text.trim().isNotEmpty ? _horarioServicoController.text.trim() : null,
          dataServico: _dataServicoController.text.trim().isNotEmpty ? _dataServicoController.text.trim() : null,
          prioridade: _prioridadeController.text.trim().isNotEmpty ? _prioridadeController.text.trim() : null,
          dataVencimento: _dataVencimentoController.text.trim().isNotEmpty ? _dataVencimentoController.text.trim() : null,
          camposPersonalizados: camposPersonalizados,
        );

        final user = _authService.currentUser;
        if (user != null) {
          if (widget.clienteUnico != null) {
            await _databaseService.updateClienteUnico(user.uid, clienteUnico.id, clienteUnico);
          } else {
            await _databaseService.createClienteUnico(user.uid, clienteUnico);
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.clienteUnico != null 
                    ? 'Cliente único atualizado com sucesso!' 
                    : 'Cliente único cadastrado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Se for edição, retorna o cliente editado
            if (widget.clienteUnico != null) {
              Navigator.pop(context, clienteUnico);
            } else {
              Navigator.pop(context);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar cliente único: $e'),
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

  List<Widget> _construirCamposDinamicos() {
    final campos = <Widget>[];
    
    for (final campo in _camposAtivos) {
      switch (campo) {
        case 'Nome':
          campos.add(_construirCampoNome());
          break;
        case 'Telefone':
          campos.add(_construirCampoTelefone());
          break;
        case 'Cidade':
          campos.add(_construirCampoCidade());
          break;
        case 'Bairro':
          campos.add(_construirCampoBairro());
          break;
        case 'Rua':
          campos.add(_construirCampoRua());
          break;
        case 'Número':
          campos.add(_construirCampoNumero());
          break;
        case 'Tipo do serviço':
          campos.add(_construirCampoTipoServico());
          break;
        case 'Data do serviço':
          campos.add(_construirCampoDataServico());
          break;
        case 'Horário do serviço':
          campos.add(_construirCampoHorarioServico());
          break;
        case 'Frequência':
          campos.add(_construirCampoFrequencia());
          break;
        case 'Valor':
          campos.add(_construirCampoValor());
          break;
        case 'Data de vencimento do pagamento':
          campos.add(_construirCampoDataVencimento());
          break;
        case 'Prioridade':
          campos.add(_construirCampoPrioridade());
          break;
        default:
          // Campo personalizado
          if (_camposPersonalizados.containsKey(campo) && _camposPersonalizados[campo] == true) {
            campos.add(_construirCampoPersonalizado(campo));
          }
          break;
      }
      
      // Adiciona espaçamento entre campos
      if (campo != _camposAtivos.last) {
        campos.add(const SizedBox(height: 16));
      }
    }
    
    return campos;
  }

  Widget _construirCampoNome() {
    return TextFormField(
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
    );
  }

  Widget _construirCampoTelefone() {
    return TextFormField(
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
        final telefoneNumeros = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (telefoneNumeros.length < 12) {
          return 'Telefone incompleto (mínimo 12 dígitos)';
        }
        if (telefoneNumeros.length > 13) {
          return 'Telefone inválido (máximo 13 dígitos)';
        }
        return null;
      },
    );
  }

  Widget _construirCampoValor() {
    return TextFormField(
      controller: _valorController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Valor do Serviço',
        hintText: 'Ex: 100,00',
        prefixIcon: Icon(Icons.attach_money, color: Colors.white70),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Digite o valor do serviço';
        }
        return null;
      },
    );
  }

  Widget _construirCampoCidade() {
    return TextFormField(
      controller: _cidadeController,
      decoration: const InputDecoration(
        labelText: 'Cidade',
        prefixIcon: Icon(Icons.location_city, color: Colors.white70),
      ),
    );
  }

  Widget _construirCampoRua() {
    return TextFormField(
      controller: _ruaController,
      decoration: const InputDecoration(
        labelText: 'Rua',
        prefixIcon: Icon(Icons.streetview, color: Colors.white70),
      ),
    );
  }

  Widget _construirCampoBairro() {
    return TextFormField(
      controller: _bairroController,
      decoration: const InputDecoration(
        labelText: 'Bairro',
        prefixIcon: Icon(Icons.location_on, color: Colors.white70),
      ),
    );
  }

  Widget _construirCampoNumero() {
    return TextFormField(
      controller: _numeroController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Número',
        prefixIcon: Icon(Icons.numbers, color: Colors.white70),
      ),
    );
  }

  Widget _construirCampoTipoServico() {
    return DropdownButtonFormField<String>(
      value: _tipoServicoSelecionado,
      decoration: const InputDecoration(
        labelText: 'Tipo do Serviço',
        prefixIcon: Icon(Icons.category, color: Colors.white70),
      ),
      items: _tiposServico.map((String tipo) {
        return DropdownMenuItem<String>(
          value: tipo,
          child: Text(tipo),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _tipoServicoSelecionado = newValue;
        });
      },
    );
  }

  Widget _construirCampoFrequencia() {
    return TextFormField(
      controller: _frequenciaController,
      decoration: const InputDecoration(
        labelText: 'Frequência',
        prefixIcon: Icon(Icons.schedule, color: Colors.white70),
      ),
    );
  }

  Widget _construirCampoHorarioServico() {
    return TextFormField(
      controller: _horarioServicoController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Horário do Serviço',
        prefixIcon: const Icon(Icons.access_time, color: Colors.white70),
        suffixIcon: IconButton(
          icon: const Icon(Icons.schedule, color: Colors.white70),
          onPressed: _selecionarHorarioServico,
        ),
        hintText: 'Selecione um horário',
      ),
      onTap: _selecionarHorarioServico,
    );
  }

  Widget _construirCampoDataServico() {
    return TextFormField(
      controller: _dataServicoController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Data do Serviço',
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month, color: Colors.white70),
          onPressed: _selecionarDataServico,
        ),
        hintText: 'Selecione uma data',
      ),
      onTap: _selecionarDataServico,
    );
  }

  Widget _construirCampoPrioridade() {
    return TextFormField(
      controller: _prioridadeController,
      decoration: const InputDecoration(
        labelText: 'Prioridade',
        prefixIcon: Icon(Icons.priority_high, color: Colors.white70),
      ),
    );
  }

  Widget _construirCampoDataVencimento() {
    return TextFormField(
      controller: _dataVencimentoController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Data de Vencimento do Pagamento',
        prefixIcon: const Icon(Icons.event, color: Colors.white70),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month, color: Colors.white70),
          onPressed: _selecionarDataVencimento,
        ),
        hintText: 'Selecione uma data',
      ),
      onTap: _selecionarDataVencimento,
    );
  }

  Widget _construirCampoPersonalizado(String nomeCampo) {
    final controller = _camposPersonalizadosControllers[nomeCampo]!;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: nomeCampo,
        prefixIcon: const Icon(Icons.edit, color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(widget.clienteUnico != null 
              ? 'Editar Cliente Único' 
              : 'Cadastre um novo cliente único'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConfiguracaoClientesUnicosScreen(),
                  ),
                );
              },
              tooltip: 'Configurar Campos',
            ),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.clienteUnico != null 
            ? 'Editar Cliente Único' 
            : 'Cadastre um novo cliente único'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfiguracaoClientesUnicosScreen(),
                ),
              );
            },
            tooltip: 'Configurar Campos',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._construirCamposDinamicos(),
                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _salvarClienteUnico,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(widget.clienteUnico != null ? 'Atualizar' : 'Cadastrar'),
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
