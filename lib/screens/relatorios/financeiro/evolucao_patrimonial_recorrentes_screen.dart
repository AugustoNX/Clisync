import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:intl/intl.dart';

class EvolucaoPatrimonialRecorrentesScreen extends StatefulWidget {
  const EvolucaoPatrimonialRecorrentesScreen({super.key});

  @override
  State<EvolucaoPatrimonialRecorrentesScreen> createState() => _EvolucaoPatrimonialRecorrentesScreenState();
}

class _EvolucaoPatrimonialRecorrentesScreenState extends State<EvolucaoPatrimonialRecorrentesScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  
  Map<String, double> _valoresPorMes = {};
  bool _isLoading = true;
  int _ultimosMeses = 6;

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
        // Busca dados do período atual (apenas recorrentes)
        final valoresAtual = await _databaseService.getValoresPorMesRecorrentes(
          user.uid,
          ultimosMeses: _ultimosMeses,
        );

        setState(() {
          _valoresPorMes = valoresAtual;
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

  List<FlSpot> _buildSpots(Map<String, double> dados) {
    final spots = <FlSpot>[];
    final mesesOrdenados = dados.keys.toList()..sort();
    
    for (int i = 0; i < mesesOrdenados.length; i++) {
      final mesAno = mesesOrdenados[i];
      final valor = dados[mesAno] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), valor));
    }
    
    return spots;
  }

  List<String> _getLabels() {
    // Sempre usa os meses do período atual como referência
    final mesesOrdenados = _valoresPorMes.keys.toList()..sort();
    return mesesOrdenados.map((mesAno) {
      final partes = mesAno.split('-');
      if (partes.length == 2) {
        final ano = int.parse(partes[0]);
        final mes = int.parse(partes[1]);
        final data = DateTime(ano, mes, 1);
        return DateFormat('MMM/yy', 'pt_BR').format(data);
      }
      return mesAno;
    }).toList();
  }

  double _getMaxY() {
    if (_valoresPorMes.values.isEmpty) return 1000.0;
    
    final maxValor = _valoresPorMes.values.reduce((a, b) => a > b ? a : b);
    // Arredonda para cima para o próximo múltiplo de 100, mas máximo 1000000
    final maxY = ((maxValor / 100).ceil() * 100).toDouble().clamp(100.0, 1000000.0);
    return maxY;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evolução Patrimonial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _valoresPorMes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.trending_up, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum dado disponível',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card com informações
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Últimos $_ultimosMeses ${_ultimosMeses == 1 ? 'mês' : 'meses'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoCard(
                                'Valor Total',
                                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(
                                  _valoresPorMes.values.fold<double>(0.0, (a, b) => a + b),
                                ),
                                Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Gráfico
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Evolução Patrimonial',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildGraficoComScroll(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
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


  Widget _buildGraficoComScroll() {
    final numeroMeses = _valoresPorMes.length;
    final precisaScroll = numeroMeses > 6;
    
    // Largura mínima por mês (para não ficar apertado)
    const larguraMinimaPorMes = 60.0;
    final larguraNecessaria = numeroMeses * larguraMinimaPorMes;
    final larguraTela = MediaQuery.of(context).size.width;
    final larguraGrafico = precisaScroll 
        ? larguraNecessaria 
        : larguraTela - 32; // 32 = padding do card
    
    // Gráfico com eixo Y sempre integrado
    final grafico = SizedBox(
      height: 300,
      width: larguraGrafico,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxY() / 10,
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
                reservedSize: 40,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final labels = _getLabels();
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        labels[value.toInt()],
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
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
                interval: _getMaxY() / 10,
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
          minX: 0,
          maxX: (_valoresPorMes.length > 0 ? _valoresPorMes.length - 1 : 0).toDouble(),
          minY: 0,
          maxY: _getMaxY(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final labels = _getLabels();
                  final index = touchedSpot.x.toInt();
                  if (index >= 0 && index < labels.length) {
                    return LineTooltipItem(
                      '${labels[index]}\n${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(touchedSpot.y)}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
            ),
            handleBuiltInTouches: true,
            getTouchLineStart: (data, index) => 0,
            getTouchLineEnd: (data, index) => double.infinity,
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _buildSpots(_valoresPorMes),
              isCurved: false,
              color: Colors.green,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );

    if (precisaScroll) {
      // Se precisa scroll, mostra gráfico com scroll (eixo Y integrado)
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: grafico,
      );
    } else {
      // Se não precisa scroll, mostra apenas o gráfico
      return grafico;
    }
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // Últimos X meses
              const Text(
                'Últimos meses:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [6, 12, 18, 24].map((meses) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text('$meses'),
                        selected: _ultimosMeses == meses,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _ultimosMeses = meses;
                            });
                          }
                        },
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: _ultimosMeses == meses ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Botões
              Row(
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
                        Navigator.pop(context);
                        _carregarDados();
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
            ],
          ),
        ),
      ),
    );
  }
}

