import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clisync/models/meta.dart';
import 'package:clisync/screens/metas/criar_meta_screen.dart';
import 'package:clisync/screens/metas/editar_meta_screen.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/theme/app_theme.dart';

class ListaMetasScreen extends StatefulWidget {
  const ListaMetasScreen({super.key});

  @override
  State<ListaMetasScreen> createState() => _ListaMetasScreenState();
}

class _ListaMetasScreenState extends State<ListaMetasScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  
  List<Meta> _metas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarMetas();
  }

  Future<void> _carregarMetas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final metas = await _databaseService.getMetas(user.uid);
        
        // Atualiza metas que passaram do prazo
        final agora = DateTime.now();
        
        for (final meta in metas) {
          if (meta.status == 'ativa' && meta.dataLimite.isBefore(agora) && meta.id != null) {
            // Calcula o valor atual para verificar se atingiu o objetivo
            final valorAtual = await _databaseService.calcularValorAtualIndicador(
              user.uid,
              meta.indicador,
              dataInicio: meta.dataCriacao,
              dataFim: meta.dataLimite,
            );
            
            // Se atingiu o objetivo, marca como concluída, senão como expirada
            final novoStatus = valorAtual >= meta.valorAlvo ? 'concluida' : 'expirada';
            final metaAtualizada = meta.copyWith(status: novoStatus);
            await _databaseService.updateMeta(user.uid, meta.id!, metaAtualizada);
          }
        }
        
        // Recarrega as metas após atualizações
        final metasAtualizadas = await _databaseService.getMetas(user.uid);
        
        // Ordena por data de criação (mais recente primeiro)
        metasAtualizadas.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
        
        setState(() {
          _metas = metasAtualizadas;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar metas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletarMeta(Meta meta) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text(
          'Confirmar exclusão',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja realmente excluir esta meta?',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.green),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmacao != true || meta.id == null) return;

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _databaseService.deleteMeta(user.uid, meta.id!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meta excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _carregarMetas();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir meta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, double>> _calcularProgressoEValorAtual(Meta meta) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return {'progresso': 0.0, 'valorAtual': 0.0};

      // Calcula o valor atual considerando apenas o período da meta (da criação até o prazo)
      final valorAtual = await _databaseService.calcularValorAtualIndicador(
        user.uid,
        meta.indicador,
        dataInicio: meta.dataCriacao,
        dataFim: meta.dataLimite,
      );

      final progresso = (valorAtual / meta.valorAlvo).clamp(0.0, 1.0);
      return {
        'progresso': progresso,
        'valorAtual': valorAtual,
      };
    } catch (e) {
      return {'progresso': 0.0, 'valorAtual': 0.0};
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'concluida':
        return Colors.green;
      case 'expirada':
        return Colors.red;
      case 'ativa':
      default:
        return Colors.blue;
    }
  }

  String _getStatusTexto(String status) {
    switch (status) {
      case 'concluida':
        return 'Concluída';
      case 'expirada':
        return 'Expirada';
      case 'ativa':
      default:
        return 'Ativa';
    }
  }

  IconData _getIconeIndicador(String indicador) {
    switch (indicador) {
      case 'numero_servicos':
        return Icons.event;
      case 'numero_clientes_planos':
        return Icons.card_giftcard;
      case 'valor_clientes_unicos':
        return Icons.attach_money;
      case 'valor_planos':
        return Icons.account_balance_wallet;
      default:
        return Icons.track_changes;
    }
  }

  String _formatarValor(double valor, String indicador) {
    if (indicador == 'numero_servicos' || indicador == 'numero_clientes_planos') {
      return valor.toInt().toString();
    } else {
      return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
    }
  }

  String _getMensagemSucesso(Meta meta, double valorAtual) {
    final valorAtualFormatado = _formatarValor(valorAtual, meta.indicador);
    final valorAlvoFormatado = _formatarValor(meta.valorAlvo, meta.indicador);
    final dataInicioFormatada = DateFormat('dd/MM/yyyy', 'pt_BR').format(meta.dataCriacao);
    final dataFimFormatada = DateFormat('dd/MM/yyyy', 'pt_BR').format(meta.dataLimite);
    
    switch (meta.indicador) {
    case 'numero_servicos':
      return '🎉 Meta alcançada com sucesso! 🎉\n'
          'Você realizou $valorAtualFormatado de $valorAlvoFormatado serviços previstos '
          'no período de $dataInicioFormatada a $dataFimFormatada.';

    case 'numero_clientes_planos':
      return '🎉 Meta alcançada com sucesso! 🎉\n'
          'Você cadastrou $valorAtualFormatado de $valorAlvoFormatado novos clientes em planos '
          'no período de $dataInicioFormatada a $dataFimFormatada.';

    case 'valor_clientes_unicos':
      return '🎉 Meta alcançada com sucesso! 🎉\n'
          'Você atingiu $valorAtualFormatado de $valorAlvoFormatado em clientes únicos '
          'no período de $dataInicioFormatada a $dataFimFormatada.';

    case 'valor_planos':
      return '🎉 Meta alcançada com sucesso! 🎉\n'
          'Você faturou $valorAtualFormatado de $valorAlvoFormatado em planos pagos '
          'no período de $dataInicioFormatada a $dataFimFormatada.';

    default:
      return '🎉 Meta alcançada com sucesso! 🎉\n'
          'Você atingiu $valorAtualFormatado de $valorAlvoFormatado '
          'no período de $dataInicioFormatada a $dataFimFormatada.';
    }
  }

  List<Meta> _getMetasAtivas() {
    return _metas.where((meta) => meta.status == 'ativa').toList();
  }

  List<Meta> _getMetasFinalizadas() {
    return _metas.where((meta) => meta.status == 'concluida' || meta.status == 'expirada').toList();
  }

  Future<void> _navegarParaCriarMeta() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CriarMetaScreen(),
      ),
    );

    if (resultado == true && mounted) {
      _carregarMetas();
    }
  }

  Future<void> _navegarParaEditarMeta(Meta meta) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarMetaScreen(meta: meta),
      ),
    );

    if (resultado == true && mounted) {
      _carregarMetas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final metasAtivas = _getMetasAtivas();
    final metasFinalizadas = _getMetasFinalizadas();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _metas.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _carregarMetas,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Metas ativas
                      ...metasAtivas.map((meta) => _buildMetaCard(meta)),
                      
                      // Dropdown de metas finalizadas
                      if (metasFinalizadas.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              'Metas Finalizadas (${metasFinalizadas.length})',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            leading: const Icon(
                              Icons.expand_more,
                              color: Colors.orange,
                            ),
                            collapsedIconColor: Colors.orange,
                            iconColor: Colors.orange,
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            collapsedBackgroundColor: Colors.orange.withOpacity(0.05),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            collapsedShape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            childrenPadding: EdgeInsets.zero,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                child: Column(
                                  children: [
                                    ...metasFinalizadas.map((meta) => _buildMetaCard(meta)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarParaCriarMeta,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma meta criada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crie sua primeira meta para começar a acompanhar seus objetivos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navegarParaCriarMeta,
            icon: const Icon(Icons.add),
            label: const Text('Criar Meta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard(Meta meta) {
    final isFinalizada = meta.status == 'concluida' || meta.status == 'expirada';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone, título e status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconeIndicador(meta.indicador),
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.nomeIndicador,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Criada em ${DateFormat('dd/MM/yyyy', 'pt_BR').format(meta.dataCriacao)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(meta.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(meta.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusTexto(meta.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(meta.status),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informações da meta com card flutuante
            Builder(
              builder: (context) {
                return _MensagemFlutuante(
                  meta: meta,
                  isFinalizada: isFinalizada,
                  calcularProgressoEValorAtual: _calcularProgressoEValorAtual,
                  getMensagemSucesso: _getMensagemSucesso,
                  formatarValor: _formatarValor,
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Barra de progresso (carregada assincronamente)
            FutureBuilder<Map<String, double>>(
              future: _calcularProgressoEValorAtual(meta),
              builder: (context, snapshot) {
                final progresso = snapshot.data?['progresso'] ?? 0.0;
                final valorAtual = snapshot.data?['valorAtual'] ?? 0.0;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progresso',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '${(progresso * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progresso,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progresso >= 1.0 ? Colors.green : AppTheme.primaryColor,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatarValor(valorAtual, meta.indicador)} de ${_formatarValor(meta.valorAlvo, meta.indicador)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botão de editar (apenas para metas ativas)
                if (meta.status == 'ativa') ...[
                  TextButton.icon(
                    onPressed: () => _navegarParaEditarMeta(meta),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(
                  onPressed: () => _deletarMeta(meta),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Excluir'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MensagemFlutuante extends StatefulWidget {
  final Meta meta;
  final bool isFinalizada;
  final Future<Map<String, double>> Function(Meta) calcularProgressoEValorAtual;
  final String Function(Meta, double) getMensagemSucesso;
  final String Function(double, String) formatarValor;

  const _MensagemFlutuante({
    required this.meta,
    required this.isFinalizada,
    required this.calcularProgressoEValorAtual,
    required this.getMensagemSucesso,
    required this.formatarValor,
  });

  @override
  State<_MensagemFlutuante> createState() => _MensagemFlutuanteState();
}

class _MensagemFlutuanteState extends State<_MensagemFlutuante> {
  bool _mensagemFechada = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Conteúdo principal (Meta e Prazo)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meta',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.formatarValor(widget.meta.valorAlvo, widget.meta.indicador),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Prazo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy', 'pt_BR').format(widget.meta.dataLimite),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.meta.dataLimite.isBefore(DateTime.now()) && widget.meta.status != 'concluida'
                          ? Colors.red
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Card flutuante com mensagem (apenas para metas finalizadas e se não foi fechado)
        if (widget.isFinalizada && !_mensagemFechada)
          Positioned(
            left: -8,
            right: -8,
            top: -0,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.meta.status == 'concluida'
                      ? Colors.green.withOpacity(0.95)
                      : Colors.red.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.meta.status == 'concluida' ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    if (widget.meta.status == 'concluida')
                      FutureBuilder<Map<String, double>>(
                        future: widget.calcularProgressoEValorAtual(widget.meta),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 40,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          }
                          final valorAtual = snapshot.data?['valorAtual'] ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: Text(
                              widget.getMensagemSucesso(widget.meta, valorAtual),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(right: 24),
                        child: Text(
                          'Meta não alcançada 😕\nMas não desanime! Defina novas metas e continue evoluindo.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _mensagemFechada = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
