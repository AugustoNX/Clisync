import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:clisync/models/cliente.dart';
import 'package:clisync/models/plano.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/screens/configuracao/configuracao_campos_screen.dart';
import 'package:clisync/services/config_service.dart';
import 'package:clisync/theme/app_theme.dart';

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
  final _frequenciaController = TextEditingController();
  final _horarioServicoController = TextEditingController();
  final _dataServicoController = TextEditingController();
  final _prioridadeController = TextEditingController();
  final _dataVencimentoController = TextEditingController();
  
  // Controladores para campos personalizados
  final Map<String, TextEditingController> _camposPersonalizadosControllers = {};
  
  // Máscara para telefone: 44 999999999
  final _telefoneMaskFormatter = MaskTextInputFormatter(
    mask: '## #########',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  
  
  String? _tipoServicoSelecionado;
  List<String> _tiposServico = [];
  
  // Variáveis para datas e horários
  DateTime? _dataServicoSelecionada;
  DateTime? _dataVencimentoSelecionada;
  TimeOfDay? _horarioServicoSelecionado;
  
  // Variáveis para planos
  List<Plano> _planos = [];
  String? _planoSelecionadoId;
  bool _isLoadingPlanos = true;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isLoadingConfig = true;
  
  // Configuração de campos ativos
  List<String> _camposAtivos = [];
  Map<String, bool> _camposPersonalizados = {};
  
  // Estados para autocomplete
  List<Cliente> _sugestoesClientes = [];
  String? _nomeDuplicado;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _carregarPlanos();
    _carregarConfiguracao();

    if (widget.cliente != null) {
      _preencherCampos();
    }
    
    // Listener para garantir que "Rua " esteja presente apenas quando houver conteúdo
    _ruaController.addListener(_garantirRuaNoInicio);
    // Listener para formatar valor com decimais
    _valorController.addListener(_formatarValor);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarrega a configuração e planos quando a tela volta do foco (ex: da tela de configuração)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _carregarConfiguracao(isReload: true);
        _carregarPlanos();
      }
    });
  }

  Future<void> _carregarConfiguracao({bool isReload = false}) async {
    try {
      final camposAtivos = await ConfigService.obterCamposAtivos();
      final tiposServico = await ConfigService.obterTiposServico();
      final config = await ConfigService.carregarConfiguracaoCampos();
      
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
        _tiposServico = ConfigService.tiposServicoPadrao;
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

  void _atualizarRuaController(String novoTexto) {
    _ruaController.removeListener(_garantirRuaNoInicio);
    _ruaController.text = novoTexto;
    _ruaController.selection = TextSelection.fromPosition(
      TextPosition(offset: _ruaController.text.length),
    );
    _ruaController.addListener(_garantirRuaNoInicio);
  }

  void _garantirRuaNoInicio() {
    final textoAtual = _ruaController.text;
    final textoTrim = textoAtual.trim();

    // Permite que o campo fique vazio sem prefixo
    if (textoTrim.isEmpty) {
      if (textoAtual.isNotEmpty) {
        _atualizarRuaController('');
      }
      return;
    }

    final semPrefixo = textoAtual.replaceFirst(RegExp(r'^[Rr]ua\s*'), '').trimLeft();

    if (semPrefixo.isEmpty) {
      _atualizarRuaController('');
      return;
    }

    final novoTexto = 'Rua $semPrefixo';
    if (novoTexto != textoAtual) {
      _atualizarRuaController(novoTexto);
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

  Future<void> _carregarPlanos() async {
    setState(() {
      _isLoadingPlanos = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final snapshot = await _database
            .child('usuarios')
            .child(user.uid)
            .child('planos')
            .get();

        if (snapshot.exists) {
          final Map<dynamic, dynamic> planosMap =
              Map<dynamic, dynamic>.from(snapshot.value as Map);
          final planosCarregados = planosMap.entries
              .map((entry) => Plano.fromMap(
                  entry.key as String,
                  Map<String, dynamic>.from(entry.value)))
              .toList();
          
          // Filtra apenas planos ativos
          final planosAtivos = planosCarregados.where((p) => p.status == 'ativo').toList();
          
          setState(() {
            _planos = planosAtivos;
            
            // Verifica se o plano selecionado ainda existe na lista
            // Se não existir, define como null para permitir seleção de outro plano
            if (_planoSelecionadoId != null) {
              final planoExiste = _planos.any((p) => p.id == _planoSelecionadoId);
              if (!planoExiste) {
                _planoSelecionadoId = null;
              }
            }
          });
        } else {
          setState(() {
            _planos = [];
            _planoSelecionadoId = null; // Limpa seleção se não houver planos
          });
        }
      }
    } catch (e) {
      // Erro ao carregar planos - continua mesmo assim
      setState(() {
        _planos = [];
        _planoSelecionadoId = null;
      });
    } finally {
      setState(() {
        _isLoadingPlanos = false;
      });
    }
  }

  void _preencherCampos() {
    final cliente = widget.cliente!;
    _nomeController.text = cliente.nome;
    
    // Formata o telefone para o padrão "44 999999999" (remove +55 se existir)
    String telefoneNumerico = cliente.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (telefoneNumerico.startsWith('55')) {
      telefoneNumerico = telefoneNumerico.substring(2);
    }
    if (telefoneNumerico.length > 11) {
      telefoneNumerico = telefoneNumerico.substring(telefoneNumerico.length - 11);
    }
    _telefoneController.text = _telefoneMaskFormatter.formatEditUpdate(
      const TextEditingValue(),
      TextEditingValue(text: telefoneNumerico),
    ).text;
    
    _cidadeController.text = cliente.cidade;
    
    final ruaOriginal = cliente.rua.trim();
    if (ruaOriginal.isEmpty) {
      _ruaController.clear();
    } else {
      final semPrefixo = ruaOriginal.replaceFirst(RegExp(r'^[Rr]ua\s*'), '').trimLeft();
      if (semPrefixo.isEmpty) {
        _ruaController.clear();
      } else {
        final ruaNormalizada = 'Rua $semPrefixo';
        _ruaController.text = ruaNormalizada;
        _ruaController.selection = TextSelection.fromPosition(
          TextPosition(offset: _ruaController.text.length),
        );
      }
    }
    
    _bairroController.text = cliente.bairro;
    _numeroController.text = cliente.numero;
    final valorFormatado = _formatarValorBrasileiro(cliente.valor);
    _valorController.text = valorFormatado;
    _lastValidValor = valorFormatado; // Salva o valor inicial como válido
    // Preenche o plano selecionado
    _planoSelecionadoId = cliente.planoId;
    // Preenche os novos campos dinâmicos
    _tipoServicoSelecionado = cliente.tipoServico;
    _frequenciaController.text = cliente.frequencia ?? '';
    
    // Preenche horário do serviço
    if (cliente.horarioServico != null && cliente.horarioServico!.isNotEmpty) {
      _horarioServicoController.text = cliente.horarioServico!;
      // Tenta converter o horário para TimeOfDay
      try {
        final partes = cliente.horarioServico!.split(':');
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
    if (cliente.dataServico != null && cliente.dataServico!.isNotEmpty) {
      _dataServicoController.text = cliente.dataServico!;
      // Tenta converter a data para DateTime
      try {
        _dataServicoSelecionada = DateFormat('dd/MM/yyyy').parse(cliente.dataServico!);
      } catch (e) {
        // Se não conseguir converter, mantém como texto
      }
    }
    
    _prioridadeController.text = cliente.prioridade ?? '';
    
    // Preenche data de vencimento
    if (cliente.dataVencimento != null && cliente.dataVencimento!.isNotEmpty) {
      _dataVencimentoController.text = cliente.dataVencimento!;
      // Tenta converter a data para DateTime
      try {
        _dataVencimentoSelecionada = DateFormat('dd/MM/yyyy').parse(cliente.dataVencimento!);
      } catch (e) {
        // Se não conseguir converter, mantém como texto
      }
    }
    
    // Preenche campos personalizados
    for (final entry in cliente.camposPersonalizados.entries) {
      final campo = entry.key;
      final valor = entry.value;
      if (_camposPersonalizadosControllers.containsKey(campo)) {
        _camposPersonalizadosControllers[campo]!.text = valor;
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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

  Future<void> _salvarCliente() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Verifica duplicata antes de salvar
        final user = _authService.currentUser;
        if (user != null) {
          final nome = _nomeController.text.trim();
          final existe = await _databaseService.existeClientePorNome(
            user.uid, 
            nome,
            excluirId: widget.cliente?.id,
          );
          
          if (existe) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Este cliente já está cadastrado!'),
                  backgroundColor: Colors.orange,
                ),
              );
              setState(() {
                _isLoading = false;
              });
            }
            return;
          }
        }
        
        // Obtém valor e informações do plano selecionado
        double valorDouble = 0.0;
        String? planoNome;
        
        if (_planoSelecionadoId != null) {
          final planoSelecionado = _planos.firstWhere(
            (p) => p.id == _planoSelecionadoId,
            orElse: () => _planos.first,
          );
          valorDouble = planoSelecionado.valor;
          planoNome = planoSelecionado.nome;
        } else {
          // Se não houver plano selecionado, tenta usar o valor do campo (compatibilidade)
          String valorTexto = _valorController.text;
          valorTexto = valorTexto.replaceAll('.', ''); // Remove pontos dos milhares
          valorTexto = valorTexto.replaceAll(',', '.'); // Troca vírgula por ponto
          valorDouble = double.tryParse(valorTexto) ?? 0.0;
        }
        
        // Normaliza telefone para salvar apenas dígitos (sem espaços/mascara)
        final telefoneSomenteDigitos = _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
        
        // Coleta dados dos campos personalizados
        final camposPersonalizados = <String, String>{};
        for (final entry in _camposPersonalizadosControllers.entries) {
          final campo = entry.key;
          final controller = entry.value;
          if (controller.text.isNotEmpty) {
            camposPersonalizados[campo] = controller.text.trim();
          }
        }
        
        final cliente = Cliente(
          id: widget.cliente?.id ?? '',
          nome: _nomeController.text.trim(),
          telefone: telefoneSomenteDigitos,
          cidade: _cidadeController.text.trim(),
          rua: _ruaController.text.trim(),
          bairro: _bairroController.text.trim(),
          numero: _numeroController.text.trim(),
          valor: valorDouble,
          statusPagamento: widget.cliente?.statusPagamento ?? {},
          dataCadastro: widget.cliente?.dataCadastro, // Preserva a data de cadastro original
          status: widget.cliente?.status ?? 'ativo', // Preserva o status do cliente
          tipoServico: _tipoServicoSelecionado,
          frequencia: _frequenciaController.text.trim().isNotEmpty ? _frequenciaController.text.trim() : null,
          horarioServico: _horarioServicoController.text.trim().isNotEmpty ? _horarioServicoController.text.trim() : null,
          dataServico: _dataServicoController.text.trim().isNotEmpty ? _dataServicoController.text.trim() : null,
          prioridade: _prioridadeController.text.trim().isNotEmpty ? _prioridadeController.text.trim() : null,
          dataVencimento: _dataVencimentoController.text.trim().isNotEmpty ? _dataVencimentoController.text.trim() : null,
          camposPersonalizados: camposPersonalizados,
          planoId: _planoSelecionadoId,
          planoNome: planoNome,
        );

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
            
            // Se for edição, retorna o cliente editado
            if (widget.cliente != null) {
              Navigator.pop(context, cliente);
            } else {
              Navigator.pop(context);
            }
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

  List<Widget> _construirCamposDinamicos() {
    final campos = <Widget>[];
    bool planoAdicionado = false;
    
    for (int i = 0; i < _camposAtivos.length; i++) {
      final campo = _camposAtivos[i];
      
      switch (campo) {
        case 'Nome':
          campos.add(_construirCampoNome());
          break;
        case 'Telefone':
          campos.add(_construirCampoTelefone());
          // Adiciona o campo de plano logo após o telefone
          if (!planoAdicionado) {
            campos.add(const SizedBox(height: 16));
            campos.add(_construirCampoPlano());
            planoAdicionado = true;
          }
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
      if (i < _camposAtivos.length - 1) {
        campos.add(const SizedBox(height: 16));
      }
    }
    
    // Se o telefone não está na lista, adiciona o plano após o nome
    if (!planoAdicionado && _camposAtivos.isNotEmpty) {
      campos.insert(1, const SizedBox(height: 16));
      campos.insert(2, _construirCampoPlano());
    }
    
    return campos;
  }

  Future<void> _buscarSugestoes(String query) async {
    if (query.isEmpty) {
      setState(() {
        _sugestoesClientes = [];
      });
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final sugestoes = await _databaseService.buscarClientesPorNome(user.uid, query);
        setState(() {
          _sugestoesClientes = sugestoes;
        });
      }
    } catch (e) {
      // Ignora erros de busca
    }
  }

  Future<void> _verificarDuplicata(String nome) async {
    final user = _authService.currentUser;
    if (user != null && nome.isNotEmpty && nome.length >= 3) {
      try {
        final existe = await _databaseService.existeClientePorNome(
          user.uid, 
          nome,
          excluirId: widget.cliente?.id,
        );
        
        setState(() {
          _nomeDuplicado = existe ? nome : null;
        });
        
        // Mostra aviso imediato para o usuário se existir duplicata
        if (existe && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Este cliente já está cadastrado! Não é possível cadastrar novamente.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        // Ignora erros
      }
    } else if (nome.isEmpty) {
      setState(() {
        _nomeDuplicado = null;
      });
    }
  }

  Widget _construirCampoNome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nomeController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nome completo',
            prefixIcon: const Icon(Icons.person, color: Colors.white70),
            suffixIcon: _nomeDuplicado != null
                ? const Icon(Icons.warning, color: Colors.orange)
                : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Digite o nome do cliente';
            }
            
            // Verifica duplicata ao validar
            if (_nomeDuplicado != null && _nomeDuplicado == value) {
              return 'Este cliente já está cadastrado!';
            }
            
            return null;
          },
          onChanged: (value) {
            // Cancela o timer anterior se existir
            _debounceTimer?.cancel();
            
            if (value.isEmpty) {
              setState(() {
                _sugestoesClientes = [];
                _nomeDuplicado = null;
              });
            } else {
              // Inicia um novo timer para debounce (aguarda 500ms após parar de digitar)
              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                _verificarDuplicata(value);
                _buscarSugestoes(value);
              });
            }
          },
        ),
        if (_sugestoesClientes.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _sugestoesClientes.length > 5 ? 5 : _sugestoesClientes.length,
              itemBuilder: (context, index) {
                final cliente = _sugestoesClientes[index];
                return InkWell(
                  onTap: () {
                    _nomeController.text = cliente.nome;
                    setState(() {
                      _sugestoesClientes = [];
                      _nomeDuplicado = null;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, color: Colors.white70, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cliente.nome,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (_nomeDuplicado != null && _nomeDuplicado == _nomeController.text.trim())
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este cliente já está cadastrado! Não é possível cadastrar novamente.',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _construirCampoTelefone() {
    return TextFormField(
      controller: _telefoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [_telefoneMaskFormatter],
      decoration: const InputDecoration(
        labelText: 'Telefone',
        hintText: '44 999999999',
        prefixIcon: Icon(Icons.phone, color: Colors.white70),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Digite o telefone do cliente';
        }
        final telefoneNumeros = value.replaceAll(RegExp(r'[^0-9]'), '');
        if (telefoneNumeros.length != 11) {
          return 'Telefone deve ter 11 dígitos (DD + número)';
        }
        return null;
      },
    );
  }

  Widget _construirCampoPlano() {
    if (_isLoadingPlanos) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_planos.isEmpty) {
      return Card(
        color: Colors.orange.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nenhum plano cadastrado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cadastre um plano na tela de configuração para poder selecioná-lo aqui.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _planoSelecionadoId,
      decoration: const InputDecoration(
        labelText: 'Plano *',
        hintText: 'Selecione o plano do cliente',
        prefixIcon: Icon(Icons.card_giftcard, color: Colors.white70),
        border: OutlineInputBorder(),
      ),
      dropdownColor: AppTheme.surfaceColor,
      items: _planos.map((plano) {
        return DropdownMenuItem(
          value: plano.id,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${plano.nome} - ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'R\$ ${plano.valor.toStringAsFixed(2)} / ${plano.frequencia}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _planoSelecionadoId = value;
          if (value != null) {
            final planoSelecionado = _planos.firstWhere((p) => p.id == value);
            final valorFormatado = _formatarValorBrasileiro(planoSelecionado.valor);
            _valorController.text = valorFormatado;
            _lastValidValor = valorFormatado;
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecione um plano';
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
          title: Text(widget.cliente != null 
              ? 'Editar Cliente' 
              : 'Cadastre um novo cliente'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConfiguracaoCamposScreen(),
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
        title: Text(widget.cliente != null 
            ? 'Editar Cliente' 
            : 'Cadastre um novo cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfiguracaoCamposScreen(),
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
