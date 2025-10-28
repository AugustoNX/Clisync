import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clisync/models/cliente_unico.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/services/config_unique_service.dart';
import 'package:clisync/screens/clientes/cadastro_cliente_unico_screen.dart';

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
                  const SizedBox(height: 16),
                  _buildUltimosServicosCard(),
                  const SizedBox(height: 16),
                  _buildEnderecoCard(),
                  const SizedBox(height: 16),
                  _buildCamposPersonalizadosCard(),
                  const SizedBox(height: 16),
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
    
    // Sempre mostra data de cadastro
    camposBasicos.add(_buildInfoRow('Primeiro serviço', _formatarData(_clienteAtual.dataCadastro)));
    
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
    
    // Separa serviços em prestados (datas passadas/atuais) e agendados (datas futuras)
    final servicosPrestados = <MapEntry<String, Map<String, dynamic>>>[];
    final servicosAgendados = <MapEntry<String, Map<String, dynamic>>>[];
    
    for (final entry in historico.entries) {
      try {
        final partesData = entry.key.split('-');
        if (partesData.length == 3) {
          final dia = int.parse(partesData[0]);
          final mes = int.parse(partesData[1]);
          final ano = int.parse(partesData[2]);
          final dataServico = DateTime(ano, mes, dia);
          
          if (dataServico.isBefore(agora) || dataServico.isAtSameMomentAs(agora)) {
            servicosPrestados.add(entry);
          } else {
            servicosAgendados.add(entry);
          }
        }
      } catch (e) {
        // Se não conseguir parsear a data, assume como prestado
        servicosPrestados.add(entry);
      }
    }

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
                      final entry = servicosPrestados[servicosPrestados.length - 1 - index];
                      final dataServicoOriginal = entry.key.replaceAll('-', '/');
                      final infoServico = entry.value;
                      final valorServico = infoServico['valor'] as double? ?? 0.0;
                      final horarioServico = infoServico['horario'] as String? ?? '';
                      
                      return _buildServicoItem(index, dataServicoOriginal, valorServico, Colors.green, horario: horarioServico);
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
                      final entry = servicosAgendados[index];
                      final dataServicoOriginal = entry.key.replaceAll('-', '/');
                      final infoServico = entry.value;
                      final valorServico = infoServico['valor'] as double? ?? 0.0;
                      final horarioServico = infoServico['horario'] as String? ?? '';
                      
                      return _buildServicoItem(index, dataServicoOriginal, valorServico, Colors.orange, horario: horarioServico);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildServicoItem(int index, String data, double valor, Color color, {String horario = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: color,
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
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Segunda linha: Valor
                Text(
                  'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(valor)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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

  void _adicionarNovoServico() {
    // Navega para o cadastro com o cliente pré-preenchido para adicionar novo serviço
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroClienteUnicoScreen(clienteUnico: _clienteAtual),
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

