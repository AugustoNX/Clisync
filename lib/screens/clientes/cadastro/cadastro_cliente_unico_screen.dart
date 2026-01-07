import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:intl/intl.dart';
import 'package:clisync/models/cliente_unico.dart';
import 'package:clisync/models/usuario.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/screens/configuracao/configuracao_clientes_unicos_screen.dart';
import 'package:clisync/services/config_unique_service.dart';

class CadastroClienteUnicoScreen extends StatefulWidget {
  final ClienteUnico? clienteUnico;
  final bool modoEditarInfo; // Modo para editar apenas informações do cliente (sem valor/data/horario)
  final bool modoNovoServico; // Modo para adicionar novo serviço a um cliente existente
  
  const CadastroClienteUnicoScreen({super.key, this.clienteUnico, this.modoEditarInfo = false, this.modoNovoServico = false});

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
  
  // Estados para autocomplete
  List<ClienteUnico> _sugestoesClientes = [];
  Timer? _debounceTimer;
  
  String? _tipoServicoSelecionado;
  Map<String, double> _servicosUnicos = {};
  bool _isLoadingServicos = true;
  
  // Horários de atendimento do usuário
  TimeOfDay? _horarioInicioAtendimento;
  TimeOfDay? _horarioFimAtendimento;
  int? _tempoServico; // Tempo do serviço em minutos

  @override
  void initState() {
    super.initState();
    _carregarConfiguracao();
    _carregarServicosUnicos();
    
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
  }
  
  Future<void> _carregarServicosUnicos() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUser(user.uid);
        if (userData != null) {
          final usuario = Usuario.fromMap(user.uid, userData);
          
          // Carrega horários de atendimento
          TimeOfDay? horarioInicio;
          TimeOfDay? horarioFim;
          
          if (usuario.horarioInicio != null && usuario.horarioInicio!.isNotEmpty) {
            try {
              final partes = usuario.horarioInicio!.split(':');
              if (partes.length == 2) {
                final hour = int.tryParse(partes[0]);
                final minute = int.tryParse(partes[1]);
                if (hour != null && minute != null) {
                  horarioInicio = TimeOfDay(hour: hour, minute: minute);
                }
              }
            } catch (e) {
              // Ignora erro de parsing
            }
          }
          
          if (usuario.horarioFim != null && usuario.horarioFim!.isNotEmpty) {
            try {
              final partes = usuario.horarioFim!.split(':');
              if (partes.length == 2) {
                final hour = int.tryParse(partes[0]);
                final minute = int.tryParse(partes[1]);
                if (hour != null && minute != null) {
                  horarioFim = TimeOfDay(hour: hour, minute: minute);
                }
              }
            } catch (e) {
              // Ignora erro de parsing
            }
          }
          
          setState(() {
            _servicosUnicos = usuario.servicosUnicos;
            _horarioInicioAtendimento = horarioInicio;
            _horarioFimAtendimento = horarioFim;
            _tempoServico = usuario.tempoServico;
            _isLoadingServicos = false;
          });
        } else {
          setState(() {
            _isLoadingServicos = false;
          });
        }
      } else {
        setState(() {
          _isLoadingServicos = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingServicos = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarrega a configuração quando a tela volta do foco (ex: da tela de configuração)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        _carregarConfiguracao(isReload: true);
        _carregarServicosUnicos();
      }
    });
  }

  Future<void> _carregarConfiguracao({bool isReload = false}) async {
    try {
      final camposAtivos = await ConfigUniqueService.obterCamposAtivos();
      final config = await ConfigUniqueService.carregarConfiguracaoCampos();
      
      setState(() {
        _camposAtivos = camposAtivos;
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
      
      // Se estiver editando um cliente e os controladores já foram criados, preenche os campos
      if (widget.clienteUnico != null && !isReload) {
        _preencherCampos();
      }
      
    } catch (e) {
      // Em caso de erro, usa configuração padrão
      setState(() {
        _camposAtivos = ['Nome', 'Telefone'];
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

  // Busca horários já ocupados na data selecionada
  Future<Set<int>> _buscarHorariosOcupados(DateTime dataSelecionada) async {
    final horariosOcupadosMinutos = <int>{};
    
    try {
      final user = _authService.currentUser;
      if (user == null) return horariosOcupadosMinutos;
      
      // Formata a data no formato usado no banco: "dd-MM-yyyy"
      final dataFormatada = DateFormat('dd-MM-yyyy').format(dataSelecionada);
      
      // Busca todos os clientes únicos
      final clientes = await _databaseService.getClientesUnicos(user.uid);
      
      // Percorre todos os clientes e verifica os serviços na data selecionada
      for (final cliente in clientes) {
        // Ignora o cliente atual se estiver editando
        if (widget.clienteUnico != null && cliente.id == widget.clienteUnico!.id) {
          continue;
        }
        
        // Verifica se há serviço na data selecionada
        if (cliente.historicoServicos.containsKey(dataFormatada)) {
          final servico = cliente.historicoServicos[dataFormatada];
          final horarioStr = servico?['horario']?.toString();
          
          if (horarioStr != null && horarioStr.isNotEmpty) {
            try {
              final partes = horarioStr.split(':');
              if (partes.length == 2) {
                final hour = int.tryParse(partes[0]);
                final minute = int.tryParse(partes[1]);
                if (hour != null && minute != null) {
                  // Converte para minutos totais para facilitar comparação
                  final minutosTotais = hour * 60 + minute;
                  horariosOcupadosMinutos.add(minutosTotais);
                }
              }
            } catch (e) {
              // Ignora erro de parsing
            }
          }
        }
      }
    } catch (e) {
      // Em caso de erro, retorna lista vazia para não bloquear a seleção
    }
    
    return horariosOcupadosMinutos;
  }

  // Gera lista de horários disponíveis dentro do intervalo de atendimento
  Future<List<TimeOfDay>> _gerarHorariosDisponiveis() async {
    if (_horarioInicioAtendimento == null || _horarioFimAtendimento == null) {
      return [];
    }
    
    // Verifica se há data selecionada
    if (_dataServicoSelecionada == null) {
      // Se não houver data, retorna todos os horários possíveis
      return _gerarTodosHorariosPossiveis();
    }
    
    // Busca horários ocupados na data selecionada
    final horariosOcupados = await _buscarHorariosOcupados(_dataServicoSelecionada!);
    
    // Usa o tempoServico do usuário, ou padrão de 30 minutos se não estiver configurado
    final intervaloMinutos = _tempoServico ?? 30;
    if (intervaloMinutos <= 0) {
      return [];
    }
    
    final horarios = <TimeOfDay>[];
    final inicioMinutos = _horarioInicioAtendimento!.hour * 60 + _horarioInicioAtendimento!.minute;
    final fimMinutos = _horarioFimAtendimento!.hour * 60 + _horarioFimAtendimento!.minute;
    
    // Gera horários com intervalo baseado no tempoServico
    int minutosAtuais = inicioMinutos;
    while (minutosAtuais <= fimMinutos) {
      final hora = minutosAtuais ~/ 60;
      final minuto = minutosAtuais % 60;
      
      // Adiciona apenas se não estiver ocupado
      if (!horariosOcupados.contains(minutosAtuais)) {
        horarios.add(TimeOfDay(hour: hora, minute: minuto));
      }
      
      minutosAtuais += intervaloMinutos;
    }
    
    return horarios;
  }
  
  // Gera todos os horários possíveis (quando não há data selecionada)
  List<TimeOfDay> _gerarTodosHorariosPossiveis() {
    if (_horarioInicioAtendimento == null || _horarioFimAtendimento == null) {
      return [];
    }
    
    final intervaloMinutos = _tempoServico ?? 30;
    if (intervaloMinutos <= 0) {
      return [];
    }
    
    final horarios = <TimeOfDay>[];
    final inicioMinutos = _horarioInicioAtendimento!.hour * 60 + _horarioInicioAtendimento!.minute;
    final fimMinutos = _horarioFimAtendimento!.hour * 60 + _horarioFimAtendimento!.minute;
    
    int minutosAtuais = inicioMinutos;
    while (minutosAtuais <= fimMinutos) {
      final hora = minutosAtuais ~/ 60;
      final minuto = minutosAtuais % 60;
      horarios.add(TimeOfDay(hour: hora, minute: minuto));
      minutosAtuais += intervaloMinutos;
    }
    
    return horarios;
  }
  
  // Método para selecionar horário do serviço
  Future<void> _selecionarHorarioServico() async {
    // Verifica se há horários de atendimento configurados
    if (_horarioInicioAtendimento == null || _horarioFimAtendimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configure os horários de atendimento no perfil antes de agendar serviços.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Verifica se há data selecionada
    if (_dataServicoSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione primeiro a data do serviço.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Mostra loading enquanto busca horários disponíveis
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    final horariosDisponiveis = await _gerarHorariosDisponiveis();
    
    // Fecha o loading
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    if (horariosDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há horários disponíveis para esta data. Todos os horários já estão ocupados.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Mostra dialog customizado com horários disponíveis
    final TimeOfDay? horarioSelecionado = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Selecione o Horário',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: horariosDisponiveis.map((horario) {
                final horarioFormatado = '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
                final isSelecionado = _horarioServicoSelecionado != null &&
                    _horarioServicoSelecionado!.hour == horario.hour &&
                    _horarioServicoSelecionado!.minute == horario.minute;
                
                return ListTile(
                  title: Text(
                    horarioFormatado,
                    style: TextStyle(
                      color: isSelecionado ? Colors.green : Colors.white,
                      fontWeight: isSelecionado ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: Icon(
                    Icons.access_time,
                    color: isSelecionado ? Colors.green : Colors.white70,
                  ),
                  selected: isSelecionado,
                  selectedTileColor: Colors.green.withOpacity(0.1),
                  onTap: () {
                    Navigator.of(context).pop(horario);
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
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

  void _preencherCampos() {
    final clienteUnico = widget.clienteUnico!;
    _nomeController.text = clienteUnico.nome;
    
    // Formata o telefone para o padrão "44 999999999" (remove +55 se existir)
    String telefoneNumerico = clienteUnico.telefone.replaceAll(RegExp(r'[^0-9]'), '');
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
    
    // Preenche os novos campos dinâmicos
    _frequenciaController.text = clienteUnico.frequencia ?? '';
    
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
    _debounceTimer?.cancel();
    _ruaController.removeListener(_garantirRuaNoInicio);
    _nomeController.dispose();
    _telefoneController.dispose();
    _cidadeController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _numeroController.dispose();
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
        // Busca o valor do serviço selecionado, se houver
        double valorDouble = 0.0;
        if (_tipoServicoSelecionado != null && _servicosUnicos.containsKey(_tipoServicoSelecionado)) {
          valorDouble = _servicosUnicos[_tipoServicoSelecionado] ?? 0.0;
        }
        
        // Normaliza telefone para apenas dígitos (salvar sem espaços)
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
        
        final clienteUnico = ClienteUnico(
          id: widget.clienteUnico?.id ?? '',
          nome: _nomeController.text.trim(),
          telefone: telefoneSomenteDigitos,
          cidade: _cidadeController.text.trim(),
          rua: _ruaController.text.trim(),
          bairro: _bairroController.text.trim(),
          numero: _numeroController.text.trim(),
          status: widget.clienteUnico?.status ?? 'ativo', // Preserva o status do cliente
          frequencia: _frequenciaController.text.trim().isNotEmpty ? _frequenciaController.text.trim() : null,
          horarioServico: _horarioServicoController.text.trim().isNotEmpty ? _horarioServicoController.text.trim() : null,
          prioridade: _prioridadeController.text.trim().isNotEmpty ? _prioridadeController.text.trim() : null,
          dataVencimento: _dataVencimentoController.text.trim().isNotEmpty ? _dataVencimentoController.text.trim() : null,
          camposPersonalizados: camposPersonalizados,
          // Se estiver no modo editar info, preserva o histórico existente
          historicoServicos: widget.modoEditarInfo ? (widget.clienteUnico?.historicoServicos ?? {}) : {},
        );

        final user = _authService.currentUser;
        if (user != null) {
          // Se estiver no modo editar info, salva diretamente sem processar histórico
          if (widget.modoEditarInfo) {
            await _databaseService.updateClienteUnico(user.uid, clienteUnico.id, clienteUnico);
          } else {
            // Modo normal: processa histórico de serviços
            final dataServico = _dataServicoController.text.trim();
            final horarioServico = _horarioServicoController.text.trim();
            
            // Pega o histórico existente (se estiver editando)
            final historicoExistente = Map<String, Map<String, dynamic>>.from(widget.clienteUnico?.historicoServicos ?? {});
            
            // Salva apenas no histórico de serviços
            if (dataServico.isNotEmpty) {
              final dataServicoFormatada = dataServico.replaceAll('/', '-');
              
              // Cria um novo mapa com o histórico existente + o novo serviço
              final novoHistorico = Map<String, Map<String, dynamic>>.from(historicoExistente);
              novoHistorico[dataServicoFormatada] = {
                'valor': valorDouble,
                'horario': horarioServico,
                'statusPagamento': ClienteUnico.statusAgendado,
                if (_tipoServicoSelecionado != null) 'tipoServico': _tipoServicoSelecionado,
              };
              
              final clienteComHistorico = clienteUnico.copyWith(
                historicoServicos: novoHistorico,
              );
              
              if (widget.clienteUnico != null) {
                await _databaseService.updateClienteUnico(user.uid, clienteUnico.id, clienteComHistorico);
              } else {
                await _databaseService.createClienteUnico(user.uid, clienteComHistorico);
              }
            } else {
              if (widget.clienteUnico != null) {
                await _databaseService.updateClienteUnico(user.uid, clienteUnico.id, clienteUnico);
              } else {
                await _databaseService.createClienteUnico(user.uid, clienteUnico);
              }
            }
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
    
    // Campos que NÃO devem aparecer no modo editar info
    final camposBloqueadosNoModoEditar = ['Data do serviço', 'Horário do serviço'];
    
    // Filtra os campos ativos baseado no modo
    final camposParaExibir = widget.modoEditarInfo
        ? _camposAtivos.where((campo) => !camposBloqueadosNoModoEditar.contains(campo)).toList()
        : _camposAtivos;
    
    for (int i = 0; i < camposParaExibir.length; i++) {
      final campo = camposParaExibir[i];
      
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
      if (i < camposParaExibir.length - 1) {
        campos.add(const SizedBox(height: 16));
      }
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
        final sugestoes = await _databaseService.buscarClientesUnicosPorNome(user.uid, query);
        setState(() {
          _sugestoesClientes = sugestoes;
        });
      }
    } catch (e) {
      // Ignora erros de busca
    }
  }

  Widget _construirCampoNome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nomeController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nome Completo',
            prefixIcon: Icon(Icons.person, color: Colors.white70),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nome é obrigatório';
            }
            return null;
          },
          onChanged: (value) {
            // Cancela o timer anterior se existir
            _debounceTimer?.cancel();
            
            if (value.isNotEmpty) {
              // Inicia um novo timer para debounce (aguarda 500ms após parar de digitar)
              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                _buscarSugestoes(value);
              });
            } else {
              setState(() {
                _sugestoesClientes = [];
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
                    // Preenche o formulário com os dados do cliente existente
                    setState(() {
                      _sugestoesClientes = [];
                    });
                    _preencherCamposComCliente(cliente);
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
      ],
    );
  }

  void _preencherCamposComCliente(ClienteUnico cliente) {
    _nomeController.text = cliente.nome;
    // Normaliza e formata telefone para "44 999999999"
    String tel = cliente.telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (tel.startsWith('55')) {
      tel = tel.substring(2);
    }
    if (tel.length > 11) {
      tel = tel.substring(tel.length - 11);
    }
    _telefoneController.text = _telefoneMaskFormatter
        .formatEditUpdate(const TextEditingValue(), TextEditingValue(text: tel))
        .text;
    _cidadeController.text = cliente.cidade;
    _ruaController.text = cliente.rua;
    _bairroController.text = cliente.bairro;
    _numeroController.text = cliente.numero;
    
    // Preenche campos opcionais se existirem
    if (cliente.frequencia != null) _frequenciaController.text = cliente.frequencia!;
    if (cliente.horarioServico != null) _horarioServicoController.text = cliente.horarioServico!;
    if (cliente.prioridade != null) _prioridadeController.text = cliente.prioridade!;
    if (cliente.dataVencimento != null) _dataVencimentoController.text = cliente.dataVencimento!;
    
    // Preenche campos personalizados se existirem
    for (final entry in cliente.camposPersonalizados.entries) {
      final campo = entry.key;
      final valor = entry.value;
      if (_camposPersonalizadosControllers.containsKey(campo)) {
        _camposPersonalizadosControllers[campo]!.text = valor;
      }
    }
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
        hintText: 'Selecione um horário (obrigatório)',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Horário do serviço é obrigatório';
        }
        
        // Valida se o horário está dentro do intervalo de atendimento
        if (_horarioInicioAtendimento != null && _horarioFimAtendimento != null && _horarioServicoSelecionado != null) {
          final horarioMinutos = _horarioServicoSelecionado!.hour * 60 + _horarioServicoSelecionado!.minute;
          final inicioMinutos = _horarioInicioAtendimento!.hour * 60 + _horarioInicioAtendimento!.minute;
          final fimMinutos = _horarioFimAtendimento!.hour * 60 + _horarioFimAtendimento!.minute;
          
          if (horarioMinutos < inicioMinutos || horarioMinutos > fimMinutos) {
            return 'Horário fora do período de atendimento';
          }
        }
        
        return null;
      },
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
        hintText: 'Selecione uma data (obrigatório)',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Data do serviço é obrigatória';
        }
        return null;
      },
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

  Widget _construirDropdownTipoServico() {
    if (_isLoadingServicos) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_servicosUnicos.isEmpty) {
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
                      'Nenhum serviço cadastrado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cadastre um serviço na tela de configuração para poder selecioná-lo aqui.',
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
      value: _tipoServicoSelecionado,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.category, color: Colors.white70),
        hintText: 'Selecione o tipo de serviço',
      ),
      items: _servicosUnicos.entries.map((entry) {
        final servico = entry.key;
        final valor = entry.value;
        final valorFormatado = 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
        return DropdownMenuItem<String>(
          value: servico,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: servico,
                  style: const TextStyle(color: Colors.white),
                ),
                const TextSpan(text: ' - '),
                TextSpan(
                  text: valorFormatado,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tipo de serviço é obrigatório';
        }
        return null;
      },
      onChanged: (String? newValue) {
        setState(() {
          _tipoServicoSelecionado = newValue;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(widget.modoNovoServico 
              ? 'Novo serviço para: ${widget.clienteUnico?.nome ?? ''}'
              : (widget.modoEditarInfo 
                  ? 'Editar Informações'
                  : (widget.clienteUnico != null 
                      ? 'Editar Cliente Único' 
                      : 'Cadastre um novo cliente único'))),
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
        title: Text(widget.modoNovoServico 
            ? 'Novo serviço para: ${widget.clienteUnico?.nome ?? ''}'
            : (widget.modoEditarInfo 
                ? 'Editar Informações'
                : (widget.clienteUnico != null 
                    ? 'Editar Cliente Único' 
                    : 'Cadastre um novo cliente único'))),
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
                  // Dropdown de tipo de serviço (apenas se não estiver no modo editar info)
                  if (!widget.modoEditarInfo) ...[
                    const SizedBox(height: 16),
                    _construirDropdownTipoServico(),
                  ],
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
