import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clisync/models/cliente_unico.dart';
import 'package:clisync/models/usuario.dart';
import 'package:clisync/screens/clientes/detalhes/detalhes_cliente_unico_screen.dart';
import 'package:clisync/screens/configuracao/editar_perfil_screen.dart';
import 'package:clisync/screens/onboarding/configuracao_servicos_screen.dart';
import 'package:clisync/screens/configuracao/configuracao_clientes_unicos_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:clisync/theme/app_theme.dart';

class ProximosServicosScreen extends StatefulWidget {
  const ProximosServicosScreen({super.key});

  @override
  State<ProximosServicosScreen> createState() => _ProximosServicosScreenState();
}

class _ProximosServicosScreenState extends State<ProximosServicosScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _proximosServicos = [];
  List<Map<String, dynamic>> _proximosServicosFiltrados = [];
  bool _isLoading = true;
  DateTime? _dataFiltroInicio;
  DateTime? _dataFiltroFim;
  String? _linkFormulario;
  bool _informacoesPreenchidas = false;
  Usuario? _currentUser;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _carregarProximosServicos();
    _carregarUsuario();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarrega o usuário quando a tela volta ao foco para atualizar validações
    // Isso garante que se o usuário preencheu algo em outra tela, aqui será atualizado
    if (_hasLoadedOnce) {
      // Aguarda um pequeno delay para evitar recarregamentos muito frequentes
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _carregarUsuario();
        }
      });
    } else {
      _hasLoadedOnce = true;
    }
  }


  Future<void> _carregarUsuario() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final userData = await _databaseService.getUser(user.uid);
        if (userData != null) {
          final novoUsuario = Usuario.fromMap(user.uid, userData);
          // Só atualiza se os dados mudaram para evitar rebuilds desnecessários
          if (mounted) {
            setState(() {
              _currentUser = novoUsuario;
            });
            // Verifica informações após carregar usuário
            await _verificarInformacoes();
          }
        }
      } catch (e) {
        // Erro ao carregar usuário
      }
    }
  }

  Future<void> _verificarInformacoes() async {
    final preenchidas = await _verificarInformacoesPreenchidas();
    if (mounted) {
      setState(() {
        _informacoesPreenchidas = preenchidas;
      });
    }
  }

  Future<void> _recarregarTelaCompleta() async {
    // Recarrega tudo: usuário, serviços e informações
    await Future.wait([
      _carregarUsuario(),
      _carregarProximosServicos(),
    ]);
    await _verificarInformacoes();
    
    // Rola para o topo após recarregar
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _carregarProximosServicos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final servicos = await _databaseService.getProximosServicosAgendados(user.uid, limite: 1000);
        setState(() {
          _proximosServicos = servicos;
          _aplicarFiltroData();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatarData(String data) {
    try {
      // Formato recebido: "29/10/2025"
      final partes = data.split('/');
      if (partes.length == 3) {
        final dia = partes[0];
        final mes = partes[1];
        final ano = partes[2];
        final dateTime = DateTime(int.parse(ano), int.parse(mes), int.parse(dia));
        
        // Formato: "Segunda-feira, 29/10/2025"
        final weekday = DateFormat('EEEE', 'pt_BR').format(dateTime);
        return '${weekday[0].toUpperCase()}${weekday.substring(1)}, $data';
      }
    } catch (e) {
      // Se der erro, retorna a data original
    }
    return data;
  }

  DateTime? _parseData(String data) {
    try {
      final partes = data.split('/');
      if (partes.length == 3) {
        final dia = int.parse(partes[0]);
        final mes = int.parse(partes[1]);
        final ano = int.parse(partes[2]);
        return DateTime(ano, mes, dia);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  void _aplicarFiltroData() {
    if (_dataFiltroInicio == null) {
      _proximosServicosFiltrados = List.from(_proximosServicos);
      return;
    }

    _proximosServicosFiltrados = _proximosServicos.where((servico) {
      final dataServico = _parseData(servico['data'] as String);
      if (dataServico == null) return false;

      if (_dataFiltroFim == null) {
        // Filtro por data única
        return dataServico.year == _dataFiltroInicio!.year &&
               dataServico.month == _dataFiltroInicio!.month &&
               dataServico.day == _dataFiltroInicio!.day;
      } else {
        // Filtro por período
        // Normaliza as datas para comparar apenas dia/mês/ano
        final inicio = DateTime(_dataFiltroInicio!.year, _dataFiltroInicio!.month, _dataFiltroInicio!.day);
        final fim = DateTime(_dataFiltroFim!.year, _dataFiltroFim!.month, _dataFiltroFim!.day);
        final data = DateTime(dataServico.year, dataServico.month, dataServico.day);
        
        return (data.isAfter(inicio) || data.isAtSameMomentAs(inicio)) &&
               (data.isBefore(fim) || data.isAtSameMomentAs(fim));
      }
    }).toList();
  }

  Future<void> _mostrarDialogFiltroData() async {
    DateTime dataVisualizacao = _dataFiltroInicio ?? DateTime.now();
    DateTime? dataInicioTemp = _dataFiltroInicio;
    DateTime? dataFimTemp = _dataFiltroFim;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Título e navegação de mês
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        setModalState(() {
                          dataVisualizacao = DateTime(
                            dataVisualizacao.year,
                            dataVisualizacao.month - 1,
                            1,
                          );
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy', 'pt_BR').format(dataVisualizacao),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: () {
                        setModalState(() {
                          dataVisualizacao = DateTime(
                            dataVisualizacao.year,
                            dataVisualizacao.month + 1,
                            1,
                          );
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              // Calendário customizado
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildCalendario(
                  dataVisualizacao,
                  dataInicioTemp,
                  dataFimTemp,
                  (date) {
                    setModalState(() {
                      if (dataInicioTemp == null) {
                        dataInicioTemp = date;
                        dataFimTemp = null;
                      } else if (dataFimTemp == null) {
                        final inicioNormalizado = DateTime(
                          dataInicioTemp!.year,
                          dataInicioTemp!.month,
                          dataInicioTemp!.day,
                        );
                        final fimNormalizado = DateTime(
                          date.year,
                          date.month,
                          date.day,
                        );
                        
                        if (inicioNormalizado.isAtSameMomentAs(fimNormalizado)) {
                          dataFimTemp = null;
                        } else {
                          if (date.isBefore(dataInicioTemp!)) {
                            dataFimTemp = dataInicioTemp;
                            dataInicioTemp = date;
                          } else {
                            dataFimTemp = date;
                          }
                        }
                      } else {
                        dataInicioTemp = date;
                        dataFimTemp = null;
                      }
                    });
                  },
                ),
              ),
              // Informação do período selecionado
              if (dataInicioTemp != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, 
                          color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            dataFimTemp == null
                                ? DateFormat('dd/MM/yyyy', 'pt_BR').format(dataInicioTemp!)
                                : '${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataInicioTemp!)} - ${DateFormat('dd/MM/yyyy', 'pt_BR').format(dataFimTemp!)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Botões
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final inicioNormalizado = dataInicioTemp != null
                              ? DateTime(
                                  dataInicioTemp!.year,
                                  dataInicioTemp!.month,
                                  dataInicioTemp!.day,
                                )
                              : null;
                          final fimNormalizado = dataFimTemp != null
                              ? DateTime(
                                  dataFimTemp!.year,
                                  dataFimTemp!.month,
                                  dataFimTemp!.day,
                                )
                              : null;

                          setState(() {
                            _dataFiltroInicio = inicioNormalizado;
                            _dataFiltroFim = fimNormalizado;
                            _aplicarFiltroData();
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendario(
    DateTime mesAno,
    DateTime? dataInicio,
    DateTime? dataFim,
    Function(DateTime) onDateSelected,
  ) {
    final primeiroDiaMes = DateTime(mesAno.year, mesAno.month, 1);
    final ultimoDiaMes = DateTime(mesAno.year, mesAno.month + 1, 0);
    final primeiroDiaSemana = primeiroDiaMes.weekday;
    
    final diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final dias = <DateTime>[];
    
    // Adiciona dias do mês anterior se necessário
    final diasAnteriores = primeiroDiaSemana % 7;
    for (int i = diasAnteriores - 1; i >= 0; i--) {
      dias.add(primeiroDiaMes.subtract(Duration(days: i + 1)));
    }
    
    // Adiciona dias do mês atual
    for (int dia = 1; dia <= ultimoDiaMes.day; dia++) {
      dias.add(DateTime(mesAno.year, mesAno.month, dia));
    }
    
    // Adiciona dias do próximo mês para completar a grade
    final diasRestantes = 42 - dias.length; // 6 semanas * 7 dias
    for (int dia = 1; dia <= diasRestantes; dia++) {
      dias.add(DateTime(mesAno.year, mesAno.month + 1, dia));
    }

    final hoje = DateTime.now();
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);

    return Table(
      children: [
        // Cabeçalho dos dias da semana
        TableRow(
          children: diasSemana.map((dia) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  dia,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Semanas do mês
        ...List.generate(6, (semana) {
          return TableRow(
            children: List.generate(7, (diaIndex) {
              final index = semana * 7 + diaIndex;
              if (index >= dias.length) {
                return const SizedBox.shrink();
              }
              
              final data = dias[index];
              final dataNormalizada = DateTime(data.year, data.month, data.day);
              final isMesAtual = data.month == mesAno.month;
              final isHoje = dataNormalizada.isAtSameMomentAs(hojeNormalizado);
              
              bool isSelecionada = false;
              bool isNoPeriodo = false;
              
              if (dataInicio != null) {
                final inicioNormalizado = DateTime(
                  dataInicio.year,
                  dataInicio.month,
                  dataInicio.day,
                );
                
                if (dataFim == null) {
                  isSelecionada = dataNormalizada.isAtSameMomentAs(inicioNormalizado);
                } else {
                  final fimNormalizado = DateTime(
                    dataFim.year,
                    dataFim.month,
                    dataFim.day,
                  );
                  isSelecionada = dataNormalizada.isAtSameMomentAs(inicioNormalizado) ||
                                  dataNormalizada.isAtSameMomentAs(fimNormalizado);
                  isNoPeriodo = (dataNormalizada.isAfter(inicioNormalizado) ||
                                dataNormalizada.isAtSameMomentAs(inicioNormalizado)) &&
                               (dataNormalizada.isBefore(fimNormalizado) ||
                                dataNormalizada.isAtSameMomentAs(fimNormalizado));
                }
              }

              return GestureDetector(
                onTap: () => onDateSelected(data),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelecionada
                        ? Colors.green
                        : isNoPeriodo
                            ? Colors.green.withOpacity(0.3)
                            : isHoje
                                ? Colors.green.withOpacity(0.1)
                                : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isHoje && !isSelecionada
                        ? Border.all(color: Colors.green, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${data.day}',
                      style: TextStyle(
                        color: isMesAtual
                            ? (isSelecionada || isNoPeriodo
                                ? Colors.white
                                : Colors.white)
                            : Colors.grey,
                        fontSize: 14,
                        fontWeight: isSelecionada || isHoje
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  void _limparFiltroData() {
    setState(() {
      _dataFiltroInicio = null;
      _dataFiltroFim = null;
      _aplicarFiltroData();
    });
  }

  String _getTextoFiltroAtivo() {
    if (_dataFiltroInicio == null) return '';
    
    final dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
    
    if (_dataFiltroFim == null) {
      return dateFormat.format(_dataFiltroInicio!);
    } else {
      return '${dateFormat.format(_dataFiltroInicio!)} - ${dateFormat.format(_dataFiltroFim!)}';
    }
  }

  Map<String, List<Map<String, dynamic>>> _agruparPorMes() {
    final grupos = <String, List<Map<String, dynamic>>>{};
    
    for (final servico in _proximosServicosFiltrados) {
      final dataServico = _parseData(servico['data'] as String);
      if (dataServico != null) {
        // Usa mês/ano como chave para agrupamento, mas mostra apenas o mês no título
        final chaveMes = DateFormat('yyyy-MM', 'pt_BR').format(dataServico);
        grupos.putIfAbsent(chaveMes, () => []).add(servico);
      }
    }
    
    // Ordena os grupos por data (mais antigo primeiro)
    final gruposOrdenados = Map.fromEntries(
      grupos.entries.toList()
        ..sort((a, b) {
          final dataA = _parseData(a.value.first['data'] as String);
          final dataB = _parseData(b.value.first['data'] as String);
          if (dataA == null || dataB == null) return 0;
          return dataA.compareTo(dataB);
        })
    );
    
    // Ordena os serviços dentro de cada grupo por data
    gruposOrdenados.forEach((key, value) {
      value.sort((a, b) {
        final dataA = _parseData(a['data'] as String);
        final dataB = _parseData(b['data'] as String);
        if (dataA == null || dataB == null) return 0;
        return dataA.compareTo(dataB);
      });
    });
    
    return gruposOrdenados;
  }

  String _getNomeMes(String chaveMes) {
    try {
      // chaveMes está no formato "yyyy-MM"
      final partes = chaveMes.split('-');
      if (partes.length == 2) {
        final ano = int.parse(partes[0]);
        final mes = int.parse(partes[1]);
        final data = DateTime(ano, mes, 1);
        final nomeMes = DateFormat('MMMM', 'pt_BR').format(data);
        return nomeMes[0].toUpperCase() + nomeMes.substring(1);
      }
    } catch (e) {
      return chaveMes;
    }
    return chaveMes;
  }

  Widget _buildListaAgrupadaPorMes() {
    final grupos = _agruparPorMes();
    final listaItens = <Widget>[];
    
    grupos.forEach((chaveMes, servicos) {
      // Título do mês com linha
      listaItens.add(
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 16, left: 16, right: 16),
          child: Row(
            children: [
              Text(
                _getNomeMes(chaveMes),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
      
      // Cards do mês
      for (final servico in servicos) {
        listaItens.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatarData(servico['data'] as String),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (servico['horario'] != null && (servico['horario'] as String).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Horário: ${servico['horario']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  servico['nomeCliente'] as String,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                if (servico['tipoServico'] != null && (servico['tipoServico'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      servico['tipoServico'] as String,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.blueAccent,
                              size: 26,
                            ),
                            onPressed: () => _abrirDetalhesCliente(servico),
                            tooltip: 'Ver detalhes do cliente',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.chat,
                              color: Color(0xFF25D366),
                              size: 28,
                            ),
                            onPressed: () {
                              final telefone = servico['telefone']?.toString() ?? '';
                              final data = servico['data'] as String;
                              final horario = servico['horario']?.toString() ?? 'Não informado';
                              
                              if (telefone.isNotEmpty) {
                                _abrirWhatsApp(telefone, data, horario);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Telefone não cadastrado para este cliente'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    });
    
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      children: listaItens,
    );
  }

  Future<void> _abrirWhatsApp(String telefone, String data, String horario) async {
    // Remove caracteres não numéricos do telefone
    final telefoneLimpo = telefone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Monta a mensagem
    final mensagem = 'Lembrete de serviço agendado:\n\nData: $data\nHorário: $horario';
    
    // Codifica a mensagem para URL usando encodeQueryComponent para usar + nos espaços
    final mensagemEncoded = Uri.encodeQueryComponent(mensagem);
    
    // Monta a URL do WhatsApp com os parâmetros adicionais para melhor compatibilidade
    final url = 'https://api.whatsapp.com/send/?phone=$telefoneLimpo&text=$mensagemEncoded&type=phone_number&app_absent=0';
    
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir WhatsApp: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _abrirDetalhesCliente(Map<String, dynamic> servico) async {
    final clienteObj = servico['clienteUnico'];
    if (clienteObj is ClienteUnico) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalhesClienteUnicoScreen(clienteUnico: clienteObj),
        ),
      );
      return;
    }

    final clienteId = servico['clienteId'] as String?;
    if (clienteId != null) {
      final user = _authService.currentUser;
      if (user != null) {
        try {
          final clientes = await _databaseService.getClientesUnicos(user.uid);
          final encontrado = clientes.firstWhere(
            (cliente) => cliente.id == clienteId,
            orElse: () => throw StateError('Cliente não encontrado'),
          );
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalhesClienteUnicoScreen(clienteUnico: encontrado),
            ),
          );
          return;
        } catch (e) {
          // Continua para mostrar mensagem de erro
        }
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível abrir os detalhes do cliente.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Próximos Serviços'),
            if (_dataFiltroInicio != null)
              Text(
                _getTextoFiltroAtivo(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          if (_dataFiltroInicio != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar filtro',
              onPressed: _limparFiltroData,
            ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filtrar por data',
            onPressed: _mostrarDialogFiltroData,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recarregarTelaCompleta,
          ),
        ],
      ),
      body: Column(
        children: [
          // Topo com botão de copiar link do formulário (igual à Home)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _informacoesPreenchidas
                        ? _mostrarLinkFormulario
                        : _mostrarDialogAcoesPendentes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _informacoesPreenchidas
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _linkFormulario != null ? () => _abrirLink(_linkFormulario!) : null,
                            child: Text(
                              _linkFormulario ?? 'Gerar e copiar link do formulário',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                decoration: _linkFormulario != null ? TextDecoration.underline : TextDecoration.none,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.copy),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Conteúdo da lista
          Expanded(
            child: RefreshIndicator(
              onRefresh: _recarregarTelaCompleta,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _proximosServicosFiltrados.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height - 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                    child: Text(
                                      _dataFiltroInicio != null 
                                          ? 'Nenhum serviço encontrado no período selecionado'
                                          : 'Nenhum serviço agendado',
                                      style: const TextStyle(fontSize: 18, color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  if (_dataFiltroInicio != null) ...[
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: _limparFiltroData,
                                      child: const Text('Limpar filtro', style: TextStyle(color: Colors.green),),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        )
                      : _buildListaAgrupadaPorMes(),
            ),
          ),
        ],
      ),
    );
  }

  // Verifica se as informações necessárias estão preenchidas
  Future<bool> _verificarInformacoesPreenchidas() async {
    if (_currentUser == null) return false;
    
    // Verifica nome da empresa
    final temNomeEmpresa = _currentUser!.nomeEmpresa != null && 
                           _currentUser!.nomeEmpresa!.trim().isNotEmpty;
    
    // Verifica se há serviços únicos cadastrados (tela específica para clientes únicos)
    final temServicosUnicos = _currentUser!.servicosUnicos.isNotEmpty;
    
    // Verifica se há configuração de campos para clientes únicos salva no Firebase
    bool temConfiguracaoCampos = false;
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final database = FirebaseDatabase.instance;
        final configRef = database.ref('usuarios/${user.uid}/configuracao_unicos');
        final snapshot = await configRef.get();
        if (snapshot.exists && snapshot.value != null) {
          // Verifica se há pelo menos um campo configurado (mesmo que seja false)
          final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
          // Remove campos que não são de configuração (como camposPersonalizados)
          data.remove('camposPersonalizados');
          temConfiguracaoCampos = data.isNotEmpty;
        }
      }
    } catch (e) {
      temConfiguracaoCampos = false;
    }
    
    return temNomeEmpresa && temServicosUnicos && temConfiguracaoCampos;
  }

  // Obtém lista de ações pendentes
  Future<List<Map<String, dynamic>>> _obterAcoesPendentes() async {
    if (_currentUser == null) return [];
    
    final List<Map<String, dynamic>> acoesPendentes = [];
    
    // Verifica se nome da empresa está vazio
    if (_currentUser!.nomeEmpresa == null || _currentUser!.nomeEmpresa!.trim().isEmpty) {
      acoesPendentes.add({
        'titulo': 'Preencher dados da empresa',
        'icone': Icons.business,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditarPerfilScreen(),
            ),
          ).then((_) async {
            // Recarrega o usuário após voltar da tela de editar perfil
            await _carregarUsuario();
            // Fecha o dialog se ainda estiver aberto
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // Força atualização do botão após recarregar
            if (mounted) {
              setState(() {});
            }
          });
        },
      });
    }
    
    // Verifica se há serviços únicos cadastrados (tela específica para clientes únicos)
    final temServicosUnicos = _currentUser!.servicosUnicos.isNotEmpty;
    
    if (!temServicosUnicos) {
      acoesPendentes.add({
        'titulo': 'Adicionar um serviço',
        'icone': Icons.add_business,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfiguracaoServicosScreen(usuario: _currentUser!),
            ),
          ).then((_) async {
            // Recarrega o usuário após voltar da tela de configuração de serviços
            await _carregarUsuario();
            // Fecha o dialog se ainda estiver aberto
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // Força atualização do botão após recarregar
            if (mounted) {
              setState(() {});
            }
          });
        },
      });
    }
    
    // Verifica se há configuração de campos para clientes únicos salva no Firebase
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final database = FirebaseDatabase.instance;
        final configRef = database.ref('usuarios/${user.uid}/configuracao_unicos');
        final snapshot = await configRef.get();
        
        bool temConfiguracao = false;
        if (snapshot.exists && snapshot.value != null) {
          // Verifica se há pelo menos um campo configurado (mesmo que seja false)
          final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
          // Remove campos que não são de configuração (como camposPersonalizados)
          data.remove('camposPersonalizados');
          temConfiguracao = data.isNotEmpty;
        }
        
        if (!temConfiguracao) {
          acoesPendentes.add({
            'titulo': 'Configurar campos dos clientes únicos',
            'icone': Icons.settings,
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfiguracaoClientesUnicosScreen(),
                ),
              ).then((_) async {
                // Recarrega após voltar da tela de configuração
                await _carregarUsuario();
                // Fecha o dialog se ainda estiver aberto
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                // Força atualização do botão após recarregar
                if (mounted) {
                  setState(() {});
                }
              });
            },
          });
        }
      }
    } catch (e) {
      // Se der erro ao carregar, adiciona como pendente
      acoesPendentes.add({
        'titulo': 'Configurar campos dos clientes únicos',
        'icone': Icons.settings,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ConfiguracaoClientesUnicosScreen(),
            ),
          ).then((_) async {
            // Recarrega após voltar da tela de configuração
            await _carregarUsuario();
            // Fecha o dialog se ainda estiver aberto
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // Força atualização do botão após recarregar
            if (mounted) {
              setState(() {});
            }
          });
        },
      });
    }
    
    return acoesPendentes;
  }

  // Mostra dialog com ações pendentes
  void _mostrarDialogAcoesPendentes() async {
    final acoesPendentes = await _obterAcoesPendentes();
    
    if (acoesPendentes.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF374151),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Ações Pendentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Para gerar o link do formulário, é necessário preencher as seguintes informações:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              ...acoesPendentes.map((acao) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: acao['onTap'] as VoidCallback,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            acao['icone'] as IconData,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              acao['titulo'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarLinkFormulario() async {
    final usuario = _authService.currentUser;
    if (usuario == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não identificado. Tente novamente em instantes.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verifica novamente se as informações estão preenchidas antes de gerar o link
    final informacoesPreenchidas = await _verificarInformacoesPreenchidas();
    if (!informacoesPreenchidas) {
      _mostrarDialogAcoesPendentes();
      return;
    }

    final link = 'https://clisync.com.br/agendamento/index.php?id=${usuario.uid}';

    setState(() {
      _linkFormulario = link;
    });

    Clipboard.setData(ClipboardData(text: link));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado para a área de transferência.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _abrirLink(String link) async {
    try {
      final uri = Uri.parse(link);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Falha ao abrir o link';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir o link.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

