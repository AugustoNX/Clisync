import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clisync/models/cliente_unico.dart';
import 'package:clisync/models/usuario.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/services/config_unique_service.dart';
import 'package:clisync/screens/clientes/cadastro/cadastro_cliente_unico_screen.dart';

class DetalhesClienteUnicoScreen extends StatefulWidget {
  final ClienteUnico clienteUnico;
  
  const DetalhesClienteUnicoScreen({super.key, required this.clienteUnico});

  @override
  State<DetalhesClienteUnicoScreen> createState() => _DetalhesClienteUnicoScreenState();
}

class _DetalhesClienteUnicoScreenState extends State<DetalhesClienteUnicoScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  bool _isLoading = false;
  bool _isLoadingConfig = true;
  
  // Configuração de campos ativos
  List<String> _camposAtivos = [];
  Map<String, bool> _camposPersonalizados = {};
  
  // Cliente atual (pode ser atualizado)
  late ClienteUnico _clienteAtual;

  @override
  void initState() {
    super.initState();
    _clienteAtual = widget.clienteUnico;
    _carregarConfiguracao();
  }

  Future<void> _carregarConfiguracao() async {
    try {
      final camposAtivos = await ConfigUniqueService.obterCamposAtivos();
      final config = await ConfigUniqueService.carregarConfiguracaoCampos();
      
      setState(() {
        _camposAtivos = camposAtivos;
        _camposPersonalizados = Map<String, bool>.from(config['camposPersonalizados']);
        _isLoadingConfig = false;
      });
    } catch (e) {
      // Em caso de erro, usa configuração padrão
      setState(() {
        _camposAtivos = ['Nome', 'Telefone'];
        _camposPersonalizados = <String, bool>{};
        _isLoadingConfig = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_clienteAtual.nome),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editarCliente,
            tooltip: 'Editar Informações do Cliente',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _adicionarNovoServico,
            tooltip: 'Adicionar Novo Serviço',
          ),
        ],
      ),
      body: _isLoadingConfig
          ? const Center(child: CircularProgressIndicator())
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 10),
                  _buildUltimosServicosCard(),
                  const SizedBox(height: 10),
                  _buildEnderecoCard(),
                  const SizedBox(height: 10),
                  _buildCamposPersonalizadosCard(),
                  const SizedBox(height: 10),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  // Obtém a primeira data do histórico de serviços (mais antiga)
  DateTime? _obterPrimeiraDataServico() {
    if (_clienteAtual.historicoServicos.isEmpty) {
      return null;
    }

    DateTime? primeiraData;
    
    for (final entry in _clienteAtual.historicoServicos.entries) {
      final dataKey = entry.key;
      final horario = entry.value['horario']?.toString();
      final dataHora = _parseDataHoraServico(dataKey, horario);
      
      if (dataHora != null) {
        if (primeiraData == null || dataHora.isBefore(primeiraData)) {
          primeiraData = dataHora;
        }
      }
    }
    
    return primeiraData;
  }

  Widget _buildInfoCard() {
    final camposBasicos = <Widget>[];
    
    // Adiciona campos básicos baseado na configuração
    if (_camposAtivos.contains('Nome')) {
      camposBasicos.add(_buildInfoRow('Nome', _clienteAtual.nome));
    }
    if (_camposAtivos.contains('Telefone')) {
      camposBasicos.add(_buildInfoRow('Telefone', _clienteAtual.telefone));
    }
    
    // Sempre mostra primeira data de serviço
    final primeiraDataServico = _obterPrimeiraDataServico();
    if (primeiraDataServico != null) {
      camposBasicos.add(_buildInfoRow('Primeiro serviço', _formatarData(primeiraDataServico)));
    }
    camposBasicos.add(_buildInfoRow('Status atual', _formatarStatus(_clienteAtual.statusAtual)));
    
    if (camposBasicos.isEmpty) return const SizedBox.shrink();
    
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Informações Básicas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...camposBasicos,
          ],
        ),
      ),
    );
  }

  Widget _buildUltimosServicosCard() {
    if (_clienteAtual.historicoServicos.isEmpty) {
      return const SizedBox.shrink();
    }

    final historico = _clienteAtual.historicoServicos;
    final agora = DateTime.now();

    final servicosPrestados = <Map<String, dynamic>>[];
    final servicosAgendados = <Map<String, dynamic>>[];

    final entradasOrdenadas = historico.entries.toList()
      ..sort((a, b) {
        final dataA = _parseDataHoraServico(a.key, a.value['horario']?.toString());
        final dataB = _parseDataHoraServico(b.key, b.value['horario']?.toString());
        final millisA = dataA?.millisecondsSinceEpoch ?? 0;
        final millisB = dataB?.millisecondsSinceEpoch ?? 0;
        return millisB.compareTo(millisA);
      });

    for (final entry in entradasOrdenadas) {
      final status = _clienteAtual.obterStatusPagamento(entry.key, referencia: agora);
      final dataHora = _parseDataHoraServico(entry.key, entry.value['horario']?.toString());
      final item = {
        'dataKey': entry.key,
        'info': entry.value,
        'status': status,
        'dateTime': dataHora,
      };

      // Serviços cancelados vão para prestados (histórico), mas não aparecem em agendados
      if (status == ClienteUnico.statusAgendado) {
        servicosAgendados.add(item);
      } else {
        servicosPrestados.add(item);
      }
    }

    servicosPrestados.sort((a, b) {
      final dataA = a['dateTime'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dataB = b['dateTime'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dataB.compareTo(dataA);
    });

    servicosAgendados.sort((a, b) {
      final dataA = a['dateTime'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dataB = b['dateTime'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dataA.compareTo(dataB);
    });

    return Column(
      children: [
        // Serviços Prestados
        if (servicosPrestados.isNotEmpty)
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Serviços Prestados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${servicosPrestados.length} ${servicosPrestados.length == 1 ? 'serviço' : 'serviços'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                                    ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: servicosPrestados.length,
                    itemBuilder: (context, index) {
                      final item = servicosPrestados[index];
                      final dataKey = item['dataKey'] as String;
                      final infoServico = item['info'] as Map<String, dynamic>;
                      final statusPagamento = item['status'] as String? ?? ClienteUnico.statusPago;
                      final dataServicoOriginal = dataKey.replaceAll('-', '/');
                      final valorServico = (infoServico['valor'] is num) 
                          ? (infoServico['valor'] as num).toDouble() 
                          : 0.0;                                                                              
                      final horarioServico = infoServico['horario']?.toString() ?? '';                                                                           
                      final tipoServico = infoServico['tipoServico']?.toString();

                      return _buildServicoItem(
                        index,
                        dataKey,
                        dataServicoOriginal, 
                        valorServico, 
                        _getStatusColor(statusPagamento),
                        statusPagamento: statusPagamento,
                        horario: horarioServico,
                        tipoServico: tipoServico,
                        isAgendado: false,
                        onMarcarPago: statusPagamento == ClienteUnico.statusAguardandoPagamento
                            ? () => _marcarServicoComoPago(dataKey)
                            : null,
                      );                                
                    },
                  ),
                ],
              ),
            ),
          ),
        
        // Espaço entre os cards
        if (servicosPrestados.isNotEmpty && servicosAgendados.isNotEmpty)
          const SizedBox(height: 16),
        
        // Serviços Agendados
        if (servicosAgendados.isNotEmpty)
          Card(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Serviços Agendados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${servicosAgendados.length} ${servicosAgendados.length == 1 ? 'serviço' : 'serviços'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                                    ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: servicosAgendados.length,
                    itemBuilder: (context, index) {
                      final item = servicosAgendados[index];
                      final dataKey = item['dataKey'] as String;
                      final infoServico = item['info'] as Map<String, dynamic>;
                      final statusPagamento = item['status'] as String? ?? ClienteUnico.statusAgendado;
                      final dataServicoOriginal = dataKey.replaceAll('-', '/');
                      final valorServico = (infoServico['valor'] is num) 
                          ? (infoServico['valor'] as num).toDouble() 
                          : 0.0;                                                                              
                      final horarioServico = infoServico['horario']?.toString() ?? '';                                                                           
                      final tipoServico = infoServico['tipoServico']?.toString();

                      return _buildServicoItem(
                        index, 
                        dataKey, 
                        dataServicoOriginal, 
                        valorServico, 
                        _getStatusColor(statusPagamento),
                        statusPagamento: statusPagamento,
                        horario: horarioServico,
                        tipoServico: tipoServico,
                        isAgendado: true,
                      );                               
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildServicoItem(
    int index,
    String dataKey,
    String data,
    double valor,
    Color corBase, {
    String horario = '',
    String? tipoServico,
    required bool isAgendado,
    required String statusPagamento,
    VoidCallback? onMarcarPago,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: corBase.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: corBase,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primeira linha: Data e horário juntos
                Text(
                  horario.isNotEmpty ? '$data - $horario' : data,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Segunda linha: Tipo e Valor
                Text(
                  tipoServico != null && tipoServico.isNotEmpty
                      ? '$tipoServico - R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(valor).replaceAll('.', ',')}'
                      : 'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(valor).replaceAll('.', ',')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: corBase,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: corBase.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatarStatus(statusPagamento),
                    style: TextStyle(
                      fontSize: 12,
                      color: corBase,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isAgendado && statusPagamento == ClienteUnico.statusAguardandoPagamento && onMarcarPago != null)
            IconButton(
              icon: const Icon(Icons.attach_money, size: 20),
              color: Colors.greenAccent,
              tooltip: 'Marcar como pago',
              onPressed: onMarcarPago,
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editarServico(dataKey, isAgendado);
              } else if (value == 'cancel') {
                _cancelarServico(dataKey, isAgendado);
              } else if (value == 'reativar') {
                _reativarServico(dataKey);
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuItem<String>>[
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
              ];
              
              // Se estiver cancelado, mostra opção de reativar
              if (statusPagamento == ClienteUnico.statusCancelado) {
                items.add(
                  const PopupMenuItem(
                    value: 'reativar',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Reativar'),
                      ],
                    ),
                  ),
                );
              } 
              // Se não estiver pago nem cancelado, mostra opção de cancelar
              else if (statusPagamento != ClienteUnico.statusPago) {
                items.add(
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Cancelar'),
                      ],
                    ),
                  ),
                );
              }
              
              return items;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnderecoCard() {
    final camposEndereco = <Widget>[];
    
    // Adiciona campos de endereço baseado na configuração
    if (_camposAtivos.contains('Cidade') && _clienteAtual.cidade.isNotEmpty) {
      camposEndereco.add(_buildInfoRow('Cidade', _clienteAtual.cidade));
    }
    if (_camposAtivos.contains('Rua') && _clienteAtual.rua.isNotEmpty) {
      camposEndereco.add(_buildInfoRow('Rua', _clienteAtual.rua));
    }
    if (_camposAtivos.contains('Bairro') && _clienteAtual.bairro.isNotEmpty) {
      camposEndereco.add(_buildInfoRow('Bairro', _clienteAtual.bairro));
    }
    if (_camposAtivos.contains('Número') && _clienteAtual.numero.isNotEmpty) {
      camposEndereco.add(_buildInfoRow('Número', _clienteAtual.numero));
    }

    if (camposEndereco.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Endereço',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...camposEndereco,
          ],
        ),
      ),
    );
  }

  Widget _buildCamposPersonalizadosCard() {
    final camposPersonalizadosAtivos = <Widget>[];
    
    // Adiciona apenas campos personalizados que estão ativos na configuração
    for (final entry in _clienteAtual.camposPersonalizados.entries) {
      final campo = entry.key;
      final valor = entry.value;
      
      if (_camposPersonalizados.containsKey(campo) && _camposPersonalizados[campo] == true) {
        camposPersonalizadosAtivos.add(_buildInfoRow(campo, valor));
      }
    }
    
    if (camposPersonalizadosAtivos.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Theme.of(context).colorScheme.secondary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Campos Personalizados',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...camposPersonalizadosAtivos,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarStatus(String status) {
    switch (status) {
      case ClienteUnico.statusAgendado:
        return 'Agendado';
      case ClienteUnico.statusAguardandoPagamento:
        return 'Aguardando pagamento';
      case ClienteUnico.statusCancelado:
        return 'Cancelado';
      case ClienteUnico.statusPago:
      default:
        return 'Pago';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case ClienteUnico.statusAgendado:
        return Colors.orange;
      case ClienteUnico.statusAguardandoPagamento:
        return Colors.redAccent;
      case ClienteUnico.statusCancelado:
        return Colors.grey;
      case ClienteUnico.statusPago:
      default:
        return Colors.green;
    }
  }

  DateTime? _parseDataHoraServico(String dataKey, String? horario) {
    try {
      final partesData = dataKey.split('-');
      if (partesData.length != 3) return null;

      final dia = int.parse(partesData[0]);
      final mes = int.parse(partesData[1]);
      final ano = int.parse(partesData[2]);

      int hora = 0;
      int minuto = 0;

      if (horario != null && horario.isNotEmpty) {
        final partesHorario = horario.split(':');
        if (partesHorario.length == 2) {
          hora = int.tryParse(partesHorario[0]) ?? 0;
          minuto = int.tryParse(partesHorario[1]) ?? 0;
        }
      }

      return DateTime(ano, mes, dia, hora, minuto);
    } catch (_) {
      return null;
    }
  }

  Widget _buildActionButtons() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _adicionarNovoServico,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Novo Serviço'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _excluirCliente,
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  void _editarCliente() async {
    // Navega para o cadastro em modo de edição SEM os campos de valor/data/horário
    final clienteEditado = await Navigator.push<ClienteUnico?>(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroClienteUnicoScreen(clienteUnico: _clienteAtual, modoEditarInfo: true),
      ),
    );
    
    // Se retornou um cliente editado, recarrega
    if (clienteEditado != null && mounted) {
      _recarregarCliente();
    }
  }

  void _adicionarNovoServico() {
    // Navega para o cadastro com o cliente pré-preenchido para adicionar novo serviço
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroClienteUnicoScreen(clienteUnico: _clienteAtual, modoNovoServico: true),
      ),
    ).then((clienteAtualizado) {
      // Se retornou um cliente atualizado, recarrega a lista completa do banco
      if (clienteAtualizado != null && mounted) {
        _recarregarCliente();
      }
    });
  }
  
  Future<void> _recarregarCliente() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final clientes = await _databaseService.getClientesUnicos(user.uid);
        final clienteAtualizado = clientes.firstWhere(
          (c) => c.id == _clienteAtual.id,
          orElse: () => _clienteAtual,
        );
        
        setState(() {
          _clienteAtual = clienteAtualizado;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editarServico(String dataKey, bool isAgendado) async {
    // Busca o serviço atual no histórico
    final servicoAtual = _clienteAtual.historicoServicos[dataKey];
    if (servicoAtual == null) return;

    final tipoServicoAtual = servicoAtual['tipoServico']?.toString() ?? '';
    final horarioAtual = servicoAtual['horario'] as String? ?? '';

    // Parse da data atual
    final partesData = dataKey.split('-');
    DateTime dataAtual;
    if (partesData.length == 3) {
      try {
        final dia = int.parse(partesData[0]);
        final mes = int.parse(partesData[1]);
        final ano = int.parse(partesData[2]);
        dataAtual = DateTime(ano, mes, dia);
      } catch (e) {
        dataAtual = DateTime.now();
      }
    } else {
      dataAtual = DateTime.now();
    }

    // Parse do horário atual
    TimeOfDay? horarioSelecionado;
    if (horarioAtual.isNotEmpty) {
      try {
        final partesHorario = horarioAtual.split(':');
        if (partesHorario.length == 2) {
          horarioSelecionado = TimeOfDay(
            hour: int.parse(partesHorario[0]),
            minute: int.parse(partesHorario[1]),
          );
        }
      } catch (e) {
        // Se não conseguir parsear, deixa como null
      }
    }

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => _EditarServicoDialog(
        dataKey: dataKey,
        dataInicial: dataAtual,
        horarioInicial: horarioSelecionado,
        tipoServicoInicial: tipoServicoAtual,
        clienteId: _clienteAtual.id,
      ),
    );

    if (resultado != null && mounted) {
      await _atualizarServico(
        resultado['dataAntiga'] as String,
        resultado['dataNova'] as String,
        resultado['horario'] as String,
        resultado['tipoServico'] as String,
        resultado['valor'] as double,
      );
    }

  }
  void _cancelarServico(String dataKey, bool isAgendado) async {
    // Busca o serviço para mostrar informações na confirmação
    final servico = _clienteAtual.historicoServicos[dataKey];
    if (servico == null) return;

    final valor = (servico['valor'] is num) 
        ? (servico['valor'] as num).toDouble() 
        : 0.0;
    final horario = servico['horario']?.toString() ?? '';
    final tipoServico = servico['tipoServico']?.toString();
    final dataFormatada = dataKey.replaceAll('-', '/');
    
    final valorFormatado = tipoServico != null && tipoServico.isNotEmpty
        ? '$tipoServico - R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(valor)}'
        : 'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(valor)}';

    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelamento'),
        content: Text(
          'Tem certeza que deseja cancelar o serviço?\n\n'
          'Data: $dataFormatada\n'
          'Horário: ${horario.isNotEmpty ? horario : 'Não informado'}\n'
          'Valor: $valorFormatado\n\n'
          'O serviço será marcado como cancelado e não aparecerá mais na lista de agendamentos, mas permanecerá no histórico.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Cancelar Serviço'),
          ),
        ],
      ),
    );

    if (confirmacao == true && mounted) {
      await _marcarServicoComoCancelado(dataKey);
    }
  }

  Future<void> _marcarServicoComoPago(String dataKey) async {
    if (!_clienteAtual.historicoServicos.containsKey(dataKey)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final novoHistorico = Map<String, Map<String, dynamic>>.from(_clienteAtual.historicoServicos);
      final servico = Map<String, dynamic>.from(novoHistorico[dataKey] ?? {});
      servico['statusPagamento'] = ClienteUnico.statusPago;
      novoHistorico[dataKey] = servico;

      final clienteAtualizado = _clienteAtual.copyWith(
        historicoServicos: novoHistorico,
      );

      await _databaseService.updateClienteUnico(user.uid, _clienteAtual.id, clienteAtualizado);

      if (mounted) {
        setState(() {
          _clienteAtual = clienteAtualizado;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço marcado como pago!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar pagamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _atualizarServico(
    String dataAntiga,
    String dataNova,
    String horario,
    String tipoServico,
    double valor,
  ) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Cria uma cópia do histórico
      final novoHistorico = Map<String, Map<String, dynamic>>.from(_clienteAtual.historicoServicos);
      final statusAnterior = _clienteAtual.historicoServicos[dataAntiga]?['statusPagamento']?.toString() ?? ClienteUnico.statusAgendado;
      final dataHoraNova = _parseDataHoraServico(dataNova, horario);
      String statusAtualizado;
      if (statusAnterior == ClienteUnico.statusPago) {
        statusAtualizado = ClienteUnico.statusPago;
      } else if (dataHoraNova != null && dataHoraNova.isAfter(DateTime.now())) {
        statusAtualizado = ClienteUnico.statusAgendado;
      } else {
        statusAtualizado = ClienteUnico.statusAguardandoPagamento;
      }

      // Remove o serviço antigo
      novoHistorico.remove(dataAntiga);

      // Adiciona o serviço atualizado com o valor do tipoServico selecionado
      novoHistorico[dataNova] = {
        'valor': valor,
        'horario': horario,
        'tipoServico': tipoServico,
        'statusPagamento': statusAtualizado,
      };

      // Atualiza o cliente
      final clienteAtualizado = _clienteAtual.copyWith(
        historicoServicos: novoHistorico,
      );

      // Salva no banco
      await _databaseService.updateClienteUnico(user.uid, _clienteAtual.id, clienteAtualizado);

      // Recarrega o cliente
      await _recarregarCliente();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar serviço: $e'),
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

  Future<void> _marcarServicoComoCancelado(String dataKey) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Cria uma cópia do histórico e atualiza o status do serviço para cancelado
      final novoHistorico = Map<String, Map<String, dynamic>>.from(_clienteAtual.historicoServicos);
      if (novoHistorico.containsKey(dataKey)) {
        final servico = Map<String, dynamic>.from(novoHistorico[dataKey] ?? {});
        servico['statusPagamento'] = ClienteUnico.statusCancelado;
        novoHistorico[dataKey] = servico;
      }

      // Atualiza o cliente
      final clienteAtualizado = _clienteAtual.copyWith(
        historicoServicos: novoHistorico,
      );

      // Salva no banco
      await _databaseService.updateClienteUnico(user.uid, _clienteAtual.id, clienteAtualizado);

      // Recarrega o cliente
      await _recarregarCliente();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço cancelado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cancelar serviço: $e'),
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

  Future<void> _reativarServico(String dataKey) async {
    if (!_clienteAtual.historicoServicos.containsKey(dataKey)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Busca informações do serviço
      final servico = _clienteAtual.historicoServicos[dataKey];
      final horario = servico?['horario']?.toString() ?? '';
      
      // Parse da data e horário
      final dataHora = _parseDataHoraServico(dataKey, horario);
      final agora = DateTime.now();
      
      // Determina o novo status baseado na data
      String novoStatus;
      if (dataHora != null && dataHora.isAfter(agora)) {
        // Data futura = agendado
        novoStatus = ClienteUnico.statusAgendado;
      } else {
        // Data passada = aguardando pagamento
        novoStatus = ClienteUnico.statusAguardandoPagamento;
      }

      // Cria uma cópia do histórico e atualiza o status do serviço
      final novoHistorico = Map<String, Map<String, dynamic>>.from(_clienteAtual.historicoServicos);
      if (novoHistorico.containsKey(dataKey)) {
        final servicoAtualizado = Map<String, dynamic>.from(novoHistorico[dataKey] ?? {});
        servicoAtualizado['statusPagamento'] = novoStatus;
        novoHistorico[dataKey] = servicoAtualizado;
      }

      // Atualiza o cliente
      final clienteAtualizado = _clienteAtual.copyWith(
        historicoServicos: novoHistorico,
      );

      // Salva no banco
      await _databaseService.updateClienteUnico(user.uid, _clienteAtual.id, clienteAtualizado);

      // Recarrega o cliente
      await _recarregarCliente();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço reativado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao reativar serviço: $e'),
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

  void _excluirCliente() async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir o cliente "${_clienteAtual.nome}"?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.currentUser;
        if (user != null) {
          await _databaseService.deleteClienteUnico(user.uid, _clienteAtual.id);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cliente excluído com sucesso!'),
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
              content: Text('Erro ao excluir cliente: $e'),
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
}

class _EditarServicoDialog extends StatefulWidget {
  final String dataKey;
  final DateTime dataInicial;
  final TimeOfDay? horarioInicial;
  final String tipoServicoInicial;
  final String? clienteId; // ID do cliente atual para ignorar na busca de horários ocupados

  const _EditarServicoDialog({
    required this.dataKey,
    required this.dataInicial,
    required this.horarioInicial,
    required this.tipoServicoInicial,
    this.clienteId,
  });

  @override
  State<_EditarServicoDialog> createState() => _EditarServicoDialogState();
}

class _EditarServicoDialogState extends State<_EditarServicoDialog> {
  late DateTime _dataSelecionada;
  TimeOfDay? _horarioSelecionado;
  String? _tipoServicoSelecionado;

  late final TextEditingController _dataController;
  late final TextEditingController _horarioController;
  
  // Serviços e horários de atendimento
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  TimeOfDay? _horarioInicioAtendimento;
  TimeOfDay? _horarioFimAtendimento;
  int? _tempoServico;
  
  // Lista de tipos de serviço e seus valores
  List<String> _tiposServico = [];
  Map<String, double> _servicosUnicos = {}; // Mapa com tipo -> valor
  bool _isLoadingTipos = true;

  @override
  void initState() {
    super.initState();
    _dataSelecionada = widget.dataInicial;
    _horarioSelecionado = widget.horarioInicial;
    _tipoServicoSelecionado = widget.tipoServicoInicial.isNotEmpty ? widget.tipoServicoInicial : null;
    _dataController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_dataSelecionada),
    );
    _horarioController = TextEditingController(
      text: _horarioSelecionado != null
          ? '${_horarioSelecionado!.hour.toString().padLeft(2, '0')}:${_horarioSelecionado!.minute.toString().padLeft(2, '0')}'
          : '',
    );
    _carregarDadosUsuario();
    _carregarTiposServico();
  }
  
  Future<void> _carregarTiposServico() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUser(user.uid);
        if (userData != null) {
          final servicosUnicos = userData['servicosUnicos'] as Map<dynamic, dynamic>? ?? {};
          
          // Converte para Map<String, double> para facilitar acesso aos valores
          final servicosMap = <String, double>{};
          servicosUnicos.forEach((key, value) {
            final tipo = key.toString();
            final valor = value is num ? value.toDouble() : 0.0;
            servicosMap[tipo] = valor;
          });
          
          final tipos = servicosMap.keys.toList();
          
          setState(() {
            _tiposServico = tipos;
            _servicosUnicos = servicosMap;
            _isLoadingTipos = false;
            // Se o tipo inicial não estiver na lista, adiciona
            if (widget.tipoServicoInicial.isNotEmpty && !tipos.contains(widget.tipoServicoInicial)) {
              _tiposServico.add(widget.tipoServicoInicial);
            }
          });
        } else {
          setState(() {
            _isLoadingTipos = false;
          });
        }
      } else {
        setState(() {
          _isLoadingTipos = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingTipos = false;
      });
    }
  }
  
  Future<void> _carregarDadosUsuario() async {
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
          
          if (mounted) {
            setState(() {
              _horarioInicioAtendimento = horarioInicio;
              _horarioFimAtendimento = horarioFim;
              _tempoServico = usuario.tempoServico;
            });
          }
        }
      }
    } catch (e) {
      // Em caso de erro, continua sem os dados
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    _horarioController.dispose();
    super.dispose();
  }


  Future<void> _selecionarData() async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
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

    if (!mounted || dataEscolhida == null) return;

    setState(() {
      _dataSelecionada = dataEscolhida;
      _dataController.text = DateFormat('dd/MM/yyyy').format(dataEscolhida);
      // Limpa o horário selecionado quando a data muda, pois os horários disponíveis podem ser diferentes
      _horarioSelecionado = null;
      _horarioController.clear();
    });
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
        if (widget.clienteId != null && cliente.id == widget.clienteId) {
          continue;
        }
        
        // Verifica se há serviço na data selecionada
        if (cliente.historicoServicos.containsKey(dataFormatada)) {
          final servico = cliente.historicoServicos[dataFormatada];
          final statusArmazenado = servico?['statusPagamento']?.toString() ?? ClienteUnico.statusPago;
          
          // Ignora serviços cancelados na verificação de horários ocupados
          if (statusArmazenado == ClienteUnico.statusCancelado) {
            continue;
          }
          
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
    
    // Busca horários ocupados na data selecionada
    final horariosOcupados = await _buscarHorariosOcupados(_dataSelecionada);
    
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

  Future<void> _selecionarHorario() async {
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
    final TimeOfDay? horarioEscolhido = await showDialog<TimeOfDay>(
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
                final isSelecionado = _horarioSelecionado != null &&
                    _horarioSelecionado!.hour == horario.hour &&
                    _horarioSelecionado!.minute == horario.minute;
                
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

    if (!mounted || horarioEscolhido == null) return;

    setState(() {
      _horarioSelecionado = horarioEscolhido;
      _horarioController.text =
          '${horarioEscolhido.hour.toString().padLeft(2, '0')}:${horarioEscolhido.minute.toString().padLeft(2, '0')}';
    });
  }

  void _cancelar() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  void _salvar() {
    FocusManager.instance.primaryFocus?.unfocus();

    // Validação dos campos obrigatórios
    if (_horarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um horário'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tipoServicoSelecionado == null || _tipoServicoSelecionado!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um tipo de serviço'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Busca o valor do tipo de serviço selecionado em servicosUnicos
    final valorServico = _servicosUnicos[_tipoServicoSelecionado] ?? 0.0;

    Navigator.of(context).pop({
      'dataAntiga': widget.dataKey,
      'dataNova': DateFormat('dd-MM-yyyy').format(_dataSelecionada),
      'horario': _horarioController.text.trim(),
      'tipoServico': _tipoServicoSelecionado!,
      'valor': valorServico,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Serviço'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _dataController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Data do Serviço *',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: _selecionarData,
                ),
                hintText: 'Selecione uma data',
                border: const OutlineInputBorder(),
              ),
              onTap: _selecionarData,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _horarioController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Horário *',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.schedule),
                  onPressed: _selecionarHorario,
                ),
                hintText: 'Selecione um horário',
                border: const OutlineInputBorder(),
              ),
              onTap: _selecionarHorario,
            ),
            const SizedBox(height: 16),
            _isLoadingTipos
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _tipoServicoSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Serviço *',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: _tiposServico.map((tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _tipoServicoSelecionado = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione um tipo de serviço';
                      }
                      return null;
                    },
                  ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancelar,
          child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

