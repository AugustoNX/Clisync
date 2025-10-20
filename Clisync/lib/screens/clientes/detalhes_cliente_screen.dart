import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clisync/models/cliente.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/services/config_service.dart';
import 'package:clisync/screens/clientes/cadastro_cliente_screen.dart';

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
  
  // Configuração de campos ativos
  List<String> _camposAtivos = [];
  Map<String, bool> _camposPersonalizados = {};
  
  // Cliente atual (pode ser atualizado)
  late Cliente _clienteAtual;

  @override
  void initState() {
    super.initState();
    _clienteAtual = widget.cliente;
    _carregarConfiguracao();
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
                  const SizedBox(height: 16),
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildServicoCard(),
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
    if (_camposAtivos.contains('Valor')) {
      camposBasicos.add(_buildInfoRow('Valor', 'R\$ ${_formatarValor(_clienteAtual.valor)}'));
    }
    
    // Sempre mostra modalidade e data de cadastro
    camposBasicos.add(_buildInfoRow('Modalidade', _clienteAtual.modalidade));
    camposBasicos.add(_buildInfoRow('Data de Cadastro', _formatarData(_clienteAtual.dataCadastro)));
    
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
    final mesAtual = DateFormat('yyyy-MM').format(DateTime.now());
    final isAdimplente = _clienteAtual.isAdimplente(mesAtual);
    
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
                    color: isAdimplente ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAdimplente ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isAdimplente ? 'Adimplente' : 'Inadimplente',
                    style: TextStyle(
                      color: isAdimplente ? Colors.green : Colors.red,
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
          ],
        ),
      ),
    );
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
    ).then((clienteEditado) {
      // Se retornou um cliente editado, atualiza a tela
      if (clienteEditado != null && mounted) {
        setState(() {
          _clienteAtual = clienteEditado;
        });
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
