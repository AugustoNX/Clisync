import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clisync/models/cliente.dart';
import 'package:clisync/models/usuario.dart';
import 'package:clisync/models/plano.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/services/config_service.dart';
import 'package:clisync/screens/clientes/cadastro/cadastro_cliente_screen.dart';
import 'package:clisync/screens/configuracao/editar_perfil_screen.dart';

class DetalhesClienteScreen extends StatefulWidget {
  final Cliente cliente;
  
  const DetalhesClienteScreen({super.key, required this.cliente});

  @override
  State<DetalhesClienteScreen> createState() => _DetalhesClienteScreenState();
}

class _DetalhesClienteScreenState extends State<DetalhesClienteScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  bool _isLoading = false;
  bool _isLoadingConfig = true;
  bool _isAdimplenteAtual = false;
  bool _temChavePix = false;
  
  // Configuração de campos ativos
  List<String> _camposAtivos = [];
  Map<String, bool> _camposPersonalizados = {};
  
  // Cliente atual (pode ser atualizado)
  late Cliente _clienteAtual;
  Plano? _planoAtual; // null = não verificado ou não existe

  @override
  void initState() {
    super.initState();
    _clienteAtual = widget.cliente;
    _carregarConfiguracao();
    _verificarStatusAdimplencia();
    _verificarPlanoExiste();
    _verificarChavePix();
  }

  Future<void> _verificarStatusAdimplencia() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final isAdimplente = await _databaseService.isClienteAdimplente(_clienteAtual, user.uid);
        if (mounted) {
          setState(() {
            _isAdimplenteAtual = isAdimplente;
          });
        }
      }
    } catch (e) {
      // Em caso de erro, usa lógica padrão mensal
      final mesAtual = DateFormat('yyyy-MM').format(DateTime.now());
      if (mounted) {
        setState(() {
          _isAdimplenteAtual = _clienteAtual.isAdimplente(mesAtual);
        });
      }
    }
  }

  Future<void> _verificarPlanoExiste() async {
    if (_clienteAtual.planoId == null) {
      setState(() {
        _planoAtual = null;
      });
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final plano = await _databaseService.getPlanoPorId(user.uid, _clienteAtual.planoId!);
        if (mounted) {
          setState(() {
            _planoAtual = plano;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _planoAtual = null;
        });
      }
    }
  }

  Future<void> _verificarChavePix() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUser(user.uid);
        if (userData != null) {
          final usuario = Usuario.fromMap(user.uid, userData);
          final temChave = usuario.chavePix != null && usuario.chavePix!.trim().isNotEmpty;
          if (mounted) {
            setState(() {
              _temChavePix = temChave;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _temChavePix = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _temChavePix = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _temChavePix = false;
        });
      }
    }
  }

  Future<void> _carregarConfiguracao() async {
    try {
      final camposAtivos = await ConfigService.obterCamposAtivos();
      final config = await ConfigService.carregarConfiguracaoCampos();
      
      setState(() {
        _camposAtivos = camposAtivos;
        _camposPersonalizados = Map<String, bool>.from(config['camposPersonalizados']);
        _isLoadingConfig = false;
      });
    } catch (e) {
      // Em caso de erro, usa configuração padrão
      setState(() {
        _camposAtivos = ['Nome', 'Telefone', 'Valor'];
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
            tooltip: 'Editar Cliente',
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
                  _buildStatusCard(),
                  _buildServicoCard(),
                  const SizedBox(height: 10),
                  _buildEnderecoCard(),
                  const SizedBox(height: 10),
                  _buildCamposPersonalizadosCard(),
                  const SizedBox(height: 10),
                  _buildHistoricoPagamentoCard(),
                  const SizedBox(height: 10),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
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
    if (_camposAtivos.contains('Valor')) {
      camposBasicos.add(_buildInfoRow('Valor', 'R\$ ${_formatarValor(_clienteAtual.valor)}'));
    }
    
    // Sempre mostra data de cadastro
    camposBasicos.add(_buildInfoRow('Cadastro', _formatarData(_clienteAtual.dataCadastro)));

        // Exibe o plano do cliente se houver
    if (_clienteAtual.planoId != null && _clienteAtual.planoNome != null) {
      String nomePlano;
      if (_planoAtual == null) {
        // Plano não existe (foi excluído)
        nomePlano = '*';
      } else if (_planoAtual!.status == 'desativado') {
        // Plano existe mas está desativado
        nomePlano = '${_clienteAtual.planoNome!} #';
      } else {
        // Plano existe e está ativo
        nomePlano = _clienteAtual.planoNome!;
      }
      camposBasicos.add(_buildInfoRow('Plano atual', nomePlano));
    }
    
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

  Widget _buildStatusCard() {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _clienteAtual.status == 'ativo' ? Icons.check_circle : Icons.pause_circle,
                  color: _clienteAtual.status == 'ativo' ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Status Ativo/Pausado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _clienteAtual.status == 'ativo' ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _clienteAtual.status == 'ativo' ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _clienteAtual.status == 'ativo' ? 'Ativo' : 'Pausado',
                    style: TextStyle(
                      color: _clienteAtual.status == 'ativo' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Status Adimplência
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isAdimplenteAtual ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isAdimplenteAtual ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _isAdimplenteAtual ? 'Adimplente' : 'Inadimplente',
                    style: TextStyle(
                      color: _isAdimplenteAtual ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
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

  Widget _buildServicoCard() {
    final camposServico = <Widget>[];
    
    // Adiciona campos de serviço baseado na configuração
    if (_camposAtivos.contains('Tipo do serviço') && _clienteAtual.tipoServico != null) {
      camposServico.add(_buildInfoRow('Tipo do Serviço', _clienteAtual.tipoServico!));
    }
    if (_camposAtivos.contains('Horário do serviço') && _clienteAtual.horarioServico != null) {
      camposServico.add(_buildInfoRow('Horário do Serviço', _clienteAtual.horarioServico!));
    }
    if (_camposAtivos.contains('Data do serviço') && _clienteAtual.dataServico != null) {
      camposServico.add(_buildInfoRow('Data do Serviço', _clienteAtual.dataServico!));
    }
    if (_camposAtivos.contains('Frequência') && _clienteAtual.frequencia != null) {
      camposServico.add(_buildInfoRow('Frequência', _clienteAtual.frequencia!));
    }
    if (_camposAtivos.contains('Prioridade') && _clienteAtual.prioridade != null) {
      camposServico.add(_buildInfoRow('Prioridade', _clienteAtual.prioridade!));
    }
    if (_camposAtivos.contains('Data de vencimento do pagamento') && _clienteAtual.dataVencimento != null) {
      camposServico.add(_buildInfoRow('Data de Vencimento', _clienteAtual.dataVencimento!));
    }

    if (camposServico.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: Theme.of(context).colorScheme.secondary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Informações do Serviço',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...camposServico,
          ],
        ),
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

  Future<List<Map<String, dynamic>>> _gerarHistoricoPagamento() async {
    final historico = <Map<String, dynamic>>[];
    final hoje = DateTime.now();
    final dataCadastro = _clienteAtual.dataCadastro;
    
    String frequencia = 'mensal'; // Default
    List<Map<String, dynamic>> periodos = [];
    
    // Busca o plano do cliente para obter a frequência
    try {
      final user = _authService.currentUser;
      if (user != null && _clienteAtual.planoId != null) {
        final plano = await _databaseService.getPlanoPorId(user.uid, _clienteAtual.planoId!);
        if (plano != null) {
          frequencia = plano.frequencia;
        }
      }
    } catch (e) {
      // Em caso de erro, usa frequência mensal
    }
    
    // Gera períodos baseados na frequência
    periodos = _databaseService.gerarPeriodosHistorico(frequencia, dataCadastro, hoje);
    
    // Processa cada período
    for (final periodo in periodos) {
      final chavePeriodo = periodo['chave'] as String;
      final dataFim = periodo['dataFim'] as DateTime;
      final sequencia = periodo['sequencia'] as int;
      
      final isPago = _clienteAtual.statusPagamento[chavePeriodo] ?? false;
      
      // Determina a data a ser exibida
      String dataExibicao;
      String? dataPagamentoArmazenada;
      bool isPagamentoAtrasado = false;
      
      // Verifica se há uma data de pagamento armazenada
      final chaveDataPagamento = '_dataPagamento_$chavePeriodo';
      dataPagamentoArmazenada = _clienteAtual.camposPersonalizados[chaveDataPagamento];
      
      // Se o pagamento foi feito e há uma data de pagamento selecionada, usa essa data
      // Caso contrário (inadimplente ou sem data), usa o formato 00/MM/YYYY
      if (isPago && dataPagamentoArmazenada != null && dataPagamentoArmazenada.isNotEmpty) {
        dataExibicao = dataPagamentoArmazenada;
      } else {
        // Formata como 00/MM/YYYY usando a data de fim do período
        final mesFormatado = dataFim.month.toString().padLeft(2, '0');
        final anoFormatado = dataFim.year.toString();
        dataExibicao = '00/$mesFormatado/$anoFormatado';
      }
      
      historico.add({
        'sequencia': sequencia,
        'data': dataExibicao,
        'pago': isPago,
        'valor': _clienteAtual.valor,
        'mesAno': chavePeriodo, // Usa a chave do período
        'dataPagamento': dataPagamentoArmazenada,
        'isPagamentoAtrasado': isPagamentoAtrasado,
      });
    }
    
    // Ordena do mais recente para o mais antigo (ou vice-versa - vou deixar do mais antigo para o mais recente)
    return historico;
  }

  Widget _buildHistoricoPagamentoCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _gerarHistoricoPagamento(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        
        final historico = snapshot.data ?? [];
        
        if (historico.isEmpty) {
          return const SizedBox.shrink();
        }
    
    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Histórico de Pagamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...historico.map((item) => _buildItemHistorico(item)),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildItemHistorico(Map<String, dynamic> item) {
    final sequencia = item['sequencia'] as int;
    final data = item['data'] as String;
    final isPago = item['pago'] as bool;
    final valor = item['valor'] as double;
    final mesAno = item['mesAno'] as String;
    final dataPagamento = item['dataPagamento'] as String?;
    final isPagamentoAtrasado = item['isPagamentoAtrasado'] as bool? ?? false;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$sequencia - ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPago 
                          ? (isPagamentoAtrasado && dataPagamento != null && dataPagamento.isNotEmpty
                              ? '- pago em $dataPagamento'
                              : '- pago')
                          : '- inadimplente',
                      style: TextStyle(
                        color: isPago ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${_formatarValor(valor)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!isPago)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton(
                onPressed: () => _marcarMesComoPago(mesAno),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text(
                  'Pago',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _marcarMesComoPago(String chavePeriodo) async {
    // Abre o calendário para o usuário selecionar a data do pagamento
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)), // Permite até 2 anos atrás
      lastDate: DateTime.now().add(const Duration(days: 30)), // Permite até 30 dias no futuro
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
    
    // Se o usuário cancelou, não faz nada
    if (dataSelecionada == null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Usa a data selecionada pelo usuário
        final dataFormatada = DateFormat('dd/MM/yyyy').format(dataSelecionada);
        
        // Obtém a chave do período atual baseada na frequência do plano
        final chavePeriodo = await _databaseService.obterChavePeriodoAtual(
          user.uid, 
          _clienteAtual, 
          dataReferencia: dataSelecionada
        );
        
        // Atualiza o status de pagamento no banco usando a chave do período
        await _databaseService.updateStatusPagamento(user.uid, _clienteAtual.id, chavePeriodo, true);
        
        // Atualiza o status de pagamento localmente
        final novoStatusPagamento = Map<String, bool>.from(_clienteAtual.statusPagamento);
        novoStatusPagamento[chavePeriodo] = true;
        
        // Atualiza os campos personalizados com a data do pagamento
        final novosCamposPersonalizados = Map<String, String>.from(_clienteAtual.camposPersonalizados);
        final chaveDataPagamento = '_dataPagamento_$chavePeriodo';
        novosCamposPersonalizados[chaveDataPagamento] = dataFormatada;
        
        final clienteAtualizado = _clienteAtual.copyWith(
          statusPagamento: novoStatusPagamento,
          camposPersonalizados: novosCamposPersonalizados,
        );
        
        // Atualiza o cliente no banco para salvar a data do pagamento
        await _databaseService.updateCliente(user.uid, _clienteAtual.id, clienteAtualizado);
        
        if (mounted) {
          setState(() {
            _clienteAtual = clienteAtualizado;
            _isLoading = false;
          });
          
          // Atualiza o status de adimplência e verifica se o plano existe
          await _verificarStatusAdimplencia();
          await _verificarPlanoExiste();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pagamento registrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar pagamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                    onPressed: _editarCliente,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleStatus,
                    icon: Icon(_clienteAtual.status == 'ativo' ? Icons.pause : Icons.play_arrow),
                    label: Text(_clienteAtual.status == 'ativo' ? 'Pausar' : 'Ativar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _clienteAtual.status == 'ativo' ? Colors.orange : Colors.green,
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: (_temTelefoneValido() && _temChavePix) ? _enviarMensagemWhatsApp : null,
                    icon: const Icon(Icons.message),
                    label: const Text('Enviar cobrança via WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (!_temTelefoneValido())
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Cadastre o número de telefone do cliente para enviar mensagens',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_temChavePix && _temTelefoneValido())
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Para enviar cobranças, é necessário cadastrar a chave Pix',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditarPerfilScreen(),
                                ),
                              ).then((_) {
                                // Atualiza a chave PIX quando voltar da tela de editar perfil
                                _verificarChavePix();
                              });
                            },
                            icon: const Icon(Icons.pix, size: 18),
                            label: const Text('Cadastrar Chave Pix'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
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

  bool _temTelefoneValido() {
    return _clienteAtual.telefone.isNotEmpty && 
           _clienteAtual.telefone.trim().isNotEmpty &&
           _clienteAtual.telefone.replaceAll(RegExp(r'[^\d]'), '').length >= 10;
  }

  Future<void> _enviarMensagemWhatsApp() async {
    try {
      // Obtém o usuário logado e sua chave Pix
      final user = _authService.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro: usuário não autenticado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final userData = await _databaseService.getUser(user.uid);
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao carregar dados do usuário'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      var usuario = Usuario.fromMap(user.uid, userData);
      var chavePix = usuario.chavePix;

      // Verifica se a chave Pix está cadastrada
      if (chavePix == null || chavePix.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chave Pix não cadastrada. Por favor, cadastre antes de enviar mensagens.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Verifica se o telefone é válido antes de continuar
      if (!_temTelefoneValido()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telefone do cliente não está preenchido ou é inválido'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Formata o valor em reais brasileiro
      final valorFormatado = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(_clienteAtual.valor);

      // Monta a mensagem
      final mensagem = 'Olá ${_clienteAtual.nome}!\n\nTudo bem? Passando só pra lembrar que há um valor pendente de $valorFormatado.\n\nO pagamento pode ser feito via PIX pela chave: $chavePix.\n\nAssim que o pagamento for concluído, por favor me avise. Agradeço desde já pela atenção e pela parceria!';

      // Remove caracteres não numéricos do telefone
      final telefoneLimpo = _clienteAtual.telefone.replaceAll(RegExp(r'[^\d]'), '');

      // Codifica a mensagem para URL
      final mensagemEncoded = Uri.encodeQueryComponent(mensagem);

      // Monta a URL do WhatsApp
      final url = 'https://api.whatsapp.com/send/?phone=$telefoneLimpo&text=$mensagemEncoded&type=phone_number&app_absent=0';

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


  String _formatarValor(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: '').format(valor);    
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  void _editarCliente() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroClienteScreen(cliente: _clienteAtual),
      ),
    ).then((clienteEditado) async {
      // Se retornou um cliente editado, atualiza a tela
      if (clienteEditado != null && mounted) {
        setState(() {
          _clienteAtual = clienteEditado;
        });
        // Verifica se o plano ainda existe após edição
        await _verificarPlanoExiste();
      }
    });
  }

  void _toggleStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final novoStatus = _clienteAtual.status == 'ativo' ? 'desativado' : 'ativo';
        final clienteAtualizado = _clienteAtual.copyWith(status: novoStatus);
        
        await _databaseService.updateCliente(user.uid, _clienteAtual.id, clienteAtualizado);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(novoStatus == 'ativo' 
                  ? 'Cliente ativado com sucesso!' 
                  : 'Cliente pausado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Atualiza o estado local do cliente
          setState(() {
            _clienteAtual = clienteAtualizado;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar status: $e'),
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
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
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
          await _databaseService.deleteCliente(user.uid, _clienteAtual.id);
          
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
