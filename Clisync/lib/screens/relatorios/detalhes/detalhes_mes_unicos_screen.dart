import 'package:flutter/material.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/screens/relatorios/pendencias/pendencias_unicos_screen.dart';
import 'package:intl/intl.dart';

class DetalhesMesUnicosScreen extends StatefulWidget {
  final String mesAno;
  final String nomeMes;

  const DetalhesMesUnicosScreen({
    super.key,
    required this.mesAno,
    required this.nomeMes,
  });

  @override
  State<DetalhesMesUnicosScreen> createState() =>
      _DetalhesMesUnicosScreenState();
}

class _DetalhesMesUnicosScreenState extends State<DetalhesMesUnicosScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  Map<String, dynamic>? _relatorio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarRelatorio();
  }

  Future<void> _carregarRelatorio() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final relatorio = await _databaseService.getRelatorioMesUnicos(
          user.uid,
          widget.mesAno,
        );
        setState(() {
          _relatorio = relatorio;
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
            content: Text('Erro ao carregar relatório: $e'),
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
        title: Text(widget.nomeMes),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _relatorio == null
          ? const Center(
              child: Text(
                'Erro ao carregar relatório',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cards de informações
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Resumo do Mês',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'Novos clientes',
                                  _relatorio!['novosClientes'].toString(),
                                  Icons.person_add,
                                  Colors.lightGreen,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoCard(
                                  'Clientes não pagos',
                                  _relatorio!['clientesNaoPagos']?.toString() ??
                                      '0',
                                  Icons.payment,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'Total de serviços',
                                  _relatorio!['totalServicos'].toString(),
                                  Icons.work,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoCard(
                                  'Cancelamentos',
                                  (_relatorio!['totalCancelamentos'] ?? 0)
                                      .toString(),
                                  Icons.cancel,
                                  Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Detalhes financeiros
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detalhes Financeiros',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildFinanceRow(
                            'Valor total',
                            _relatorio!['valorTotal'],
                            Colors.blue,
                          ),
                          _buildFinanceRow(
                            'Valor recebido',
                            _relatorio!['valorRecebido'] ?? 0.0,
                            Colors.green,
                          ),
                          _buildFinanceRow(
                            'Valor pendente',
                            _relatorio!['valorPendente'] ?? 0.0,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botão para ver pendências
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PendenciasUnicosScreen(mesAno: widget.mesAno),
                        ),
                      );
                    },
                    icon: const Icon(Icons.warning),
                    label: const Text('Ver Pendências'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Análises do mês
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Análises do Mês',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Serviços por tipo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),

                          // Gráfico de serviços por tipo
                          _buildServicosPorTipoChart(),

                          const SizedBox(height: 24),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 16),

                          const Text(
                            'Picos de Movimento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Gráfico de dias da semana
                          _buildDiasSemanaChart(),

                          const SizedBox(height: 24),

                          // Gráfico de horários
                          _buildHorariosChart(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFinanceRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              NumberFormat.currency(
                locale: 'pt_BR',
                symbol: 'R\$ ',
              ).format(value),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildServicosPorTipoChart() {
    final servicosPorTipo =
        _relatorio!['servicosPorTipo'] as Map<String, dynamic>? ?? {};

    if (servicosPorTipo.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'Nenhum serviço registrado neste mês',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    // Converte para lista e ordena por quantidade (maior primeiro)
    final listaTipos = servicosPorTipo.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    // Encontra o valor máximo para normalizar as barras
    final maxQuantidade = listaTipos.isNotEmpty
        ? listaTipos.map((e) => e.value as int).reduce((a, b) => a > b ? a : b)
        : 1;

    // Cores para as barras
    final cores = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: listaTipos.asMap().entries.map((entry) {
          final index = entry.key;
          final tipoEntry = entry.value;
          final tipo = tipoEntry.key;
          final quantidade = tipoEntry.value as int;
          final altura =
              (quantidade / maxQuantidade) * 160; // Altura máxima de 160
          final cor = cores[index % cores.length];

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barra
                  Flexible(
                    child: Container(
                      height: altura > 0 ? altura : 2,
                      decoration: BoxDecoration(
                        color: cor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Center(
                        child: quantidade > 0 && altura > 20
                            ? Text(
                                quantidade.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Label do tipo
                  Text(
                    tipo,
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDiasSemanaChart() {
    final servicosPorDia =
        _relatorio!['servicosPorDiaSemana'] as Map<String, dynamic>? ?? {};

    if (servicosPorDia.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ordem dos dias da semana
    final ordemDias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    final listaDias = ordemDias.map((dia) {
      return MapEntry(dia, servicosPorDia[dia] as int? ?? 0);
    }).toList();

    // Encontra o valor máximo
    final maxQuantidade = listaDias.isNotEmpty
        ? listaDias.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Serviços por Dia da Semana',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: listaDias.map((entry) {
              final dia = entry.key;
              final quantidade = entry.value;
              final altura = (quantidade / maxQuantidade) * 140;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          height: altura > 0 ? altura : 2,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                          child: Center(
                            child: quantidade > 0 && altura > 20
                                ? Text(
                                    quantidade.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dia,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHorariosChart() {
    final servicosPorHorario =
        _relatorio!['servicosPorHorario'] as Map<String, dynamic>? ?? {};

    if (servicosPorHorario.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ordem das faixas de horário
    final ordemHorarios = [
      'Manhã\n(6h-12h)',
      'Tarde\n(12h-18h)',
      'Noite\n(18h-22h)',
      'Madrugada\n(22h-6h)',
    ];
    final listaHorarios = ordemHorarios.map((horario) {
      return MapEntry(horario, servicosPorHorario[horario] as int? ?? 0);
    }).toList();

    // Encontra o valor máximo
    final maxQuantidade = listaHorarios.isNotEmpty
        ? listaHorarios.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 1;

    // Cores para cada faixa
    final cores = [Colors.orange, Colors.blue, Colors.purple, Colors.teal];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Serviços por Faixa de Horário',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: listaHorarios.asMap().entries.map((entry) {
              final index = entry.key;
              final horarioEntry = entry.value;
              final horario = horarioEntry.key;
              final quantidade = horarioEntry.value;
              final altura = (quantidade / maxQuantidade) * 140;
              final cor = cores[index % cores.length];

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Container(
                          height: altura > 0 ? altura : 2,
                          decoration: BoxDecoration(
                            color: cor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                          child: Center(
                            child: quantidade > 0 && altura > 20
                                ? Text(
                                    quantidade.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        horario,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
