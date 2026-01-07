import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/models/plano.dart';
import 'package:clisync/models/cliente.dart';
import 'package:intl/intl.dart';

class RelatoriosPlanosScreen extends StatefulWidget {
  const RelatoriosPlanosScreen({super.key});

  @override
  State<RelatoriosPlanosScreen> createState() => _RelatoriosPlanosScreenState();
}

class _RelatoriosPlanosScreenState extends State<RelatoriosPlanosScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  
  List<Plano> _planos = [];
  List<Cliente> _clientes = [];
  Map<String, int> _clientesPorPlano = {};
  Map<String, double> _receitaPorPlano = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Busca planos e clientes
        final planos = await _databaseService.getPlanos(user.uid);
        final clientes = await _databaseService.getClientes(user.uid);
        
        // Filtra apenas clientes ativos
        final clientesAtivos = clientes.where((c) => c.isAtivo).toList();
        
        // Calcula quantidade de clientes por plano
        final clientesPorPlano = <String, int>{};
        final receitaPorPlano = <String, double>{};
        
        for (final plano in planos) {
          clientesPorPlano[plano.id!] = 0;
          receitaPorPlano[plano.id!] = 0.0;
        }
        
        // Conta clientes por plano
        for (final cliente in clientesAtivos) {
          if (cliente.planoId != null && clientesPorPlano.containsKey(cliente.planoId)) {
            clientesPorPlano[cliente.planoId!] = (clientesPorPlano[cliente.planoId!] ?? 0) + 1;
          }
        }
        
        // Calcula receita por plano (valor do plano * quantidade de clientes)
        for (final plano in planos) {
          if (plano.id != null && clientesPorPlano.containsKey(plano.id)) {
            final quantidade = clientesPorPlano[plano.id!]!;
            receitaPorPlano[plano.id!] = plano.valor * quantidade;
          }
        }

        setState(() {
          _planos = planos;
          _clientes = clientesAtivos;
          _clientesPorPlano = clientesPorPlano;
          _receitaPorPlano = receitaPorPlano;
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
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Planos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _planos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum plano cadastrado',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cadastre planos para visualizar os relatórios',
                        style: TextStyle(fontSize: 14, color: Colors.white54),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card com informações gerais
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Resumo Geral',
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
                                    child: _buildInfoCard(
                                      'Total de Planos',
                                      _planos.length.toString(),
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInfoCard(
                                      'Total de Clientes',
                                      _clientes.length.toString(),
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Gráfico de Pizza - Quantidade de Clientes por Plano
                      if (_temClientesNosPlanos())
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Distribuição de Clientes por Plano',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildGraficoPizzaClientes(),
                              ],
                            ),
                          ),
                        ),
                      
                      if (_temClientesNosPlanos()) const SizedBox(height: 16),
                      
                      // Gráfico de Receita por Plano
                      if (_temReceitaNosPlanos())
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Receita por Plano',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildGraficoReceita(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  bool _temClientesNosPlanos() {
    return _clientesPorPlano.values.any((count) => count > 0);
  }

  bool _temReceitaNosPlanos() {
    return _receitaPorPlano.values.any((valor) => valor > 0);
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoPizzaClientes() {
    final totalClientes = _clientesPorPlano.values.fold<int>(0, (sum, count) => sum + count);
    if (totalClientes == 0) {
      return const SizedBox.shrink();
    }

    // Cores para os diferentes planos
    final cores = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.indigo,
    ];

    // Ordena planos por quantidade de clientes (maior primeiro)
    final planosOrdenados = _planos.where((p) => _clientesPorPlano[p.id!]! > 0).toList()
      ..sort((a, b) => _clientesPorPlano[b.id!]!.compareTo(_clientesPorPlano[a.id!]!));

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < planosOrdenados.length; i++) {
      final plano = planosOrdenados[i];
      final quantidade = _clientesPorPlano[plano.id!]!;
      final porcentagem = (quantidade / totalClientes * 100);
      final cor = cores[i % cores.length];
      
      sections.add(
        PieChartSectionData(
          value: quantidade.toDouble(),
          title: '${porcentagem.toStringAsFixed(1)}%\n$quantidade',
          color: cor,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legenda
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: planosOrdenados.asMap().entries.map((entry) {
            final index = entry.key;
            final plano = entry.value;
            final quantidade = _clientesPorPlano[plano.id!]!;
            final porcentagem = (quantidade / totalClientes * 100);
            final cor = cores[index % cores.length];
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${plano.nome}: $quantidade (${porcentagem.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGraficoReceita() {
    final planosComReceita = _planos.where((p) => (_receitaPorPlano[p.id!] ?? 0.0) > 0).toList()
      ..sort((a, b) => (_receitaPorPlano[b.id!] ?? 0.0).compareTo(_receitaPorPlano[a.id!] ?? 0.0));
    
    if (planosComReceita.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxReceita = _receitaPorPlano.values.reduce((a, b) => a > b ? a : b);
    final maxY = ((maxReceita / 100).ceil() * 100).toDouble();

    // Cores para os diferentes planos
    final cores = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.indigo,
    ];

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 10,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < planosComReceita.length) {
                        final plano = planosComReceita[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            plano.nome,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: maxY / 10,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$').format(value),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              minY: 0,
              maxY: maxY,
              barGroups: planosComReceita.asMap().entries.map((entry) {
                final index = entry.key;
                final plano = entry.value;
                final receita = _receitaPorPlano[plano.id!] ?? 0.0;
                final cor = cores[index % cores.length];
                
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: receita,
                      color: cor,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final plano = planosComReceita[groupIndex];
                    final receita = _receitaPorPlano[plano.id!] ?? 0.0;
                    return BarTooltipItem(
                      '${plano.nome}\n${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(receita)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legenda com valores
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: planosComReceita.asMap().entries.map((entry) {
            final index = entry.key;
            final plano = entry.value;
            final receita = _receitaPorPlano[plano.id!] ?? 0.0;
            final cor = cores[index % cores.length];
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${plano.nome}: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0).format(receita)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

