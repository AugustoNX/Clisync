import 'package:flutter/material.dart';
import 'package:clisync/screens/relatorios/fechamento-mes/fechamento_mes_screen.dart';
import 'package:clisync/screens/relatorios/fechamento-mes/fechamento_mes_unicos_screen.dart';
import 'package:clisync/screens/relatorios/servicos_mensais.dart';
import 'package:clisync/screens/relatorios/financeiro/evolucao_patrimonial_screen.dart';
import 'package:clisync/screens/relatorios/ranking_clientes_unicos_screen.dart';
import 'package:clisync/screens/relatorios/financeiro/evolucao_patrimonial_recorrentes_screen.dart';
import 'package:clisync/screens/relatorios/relatorios_planos_screen.dart';
import 'package:clisync/services/version_service.dart';

class DadosRelatoriosMenuScreen extends StatefulWidget {
  const DadosRelatoriosMenuScreen({super.key});

  @override
  State<DadosRelatoriosMenuScreen> createState() => _DadosRelatoriosMenuScreenState();
}

class _DadosRelatoriosMenuScreenState extends State<DadosRelatoriosMenuScreen> {
  VersionMode _currentVersion = VersionMode.unicos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVersionMode();
  }

  Future<void> _loadVersionMode() async {
    final version = await VersionService.getVersionMode();
    setState(() {
      _currentVersion = version;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados e Relatórios'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Botão de Fechamento do Mês
                    _buildMenuButton(
                      title: 'Fechamento do Mês',
                      icon: Icons.calendar_month,
                      color: Colors.green,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _currentVersion == VersionMode.recorrentes
                                ? const FechamentoMesScreen()
                                : const FechamentoMesUnicosScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    // Botão de Evolução Patrimonial (apenas para versão recorrentes)           
                    _buildMenuButton(
                      title: 'Evolução patrimonial',
                      icon: Icons.account_balance_wallet,
                      color: Color(0xFF1E3A8A),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _currentVersion == VersionMode.recorrentes
                                ? const EvolucaoPatrimonialRecorrentesScreen()
                                : const EvolucaoPatrimonialScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    
                    // Botão de Crescimento Mensal (apenas para versão de únicos)
                    if (_currentVersion == VersionMode.unicos) ...[
                      _buildMenuButton(
                        title: 'Serviços mensais',
                        icon: Icons.trending_up,
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CrescimentoMensalScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        title: 'Ranking de Clientes',
                        icon: Icons.emoji_events,
                        color: Colors.amber,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RankingClientesUnicosScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Botão de Relatórios de Planos (apenas para versão recorrentes)
                    if (_currentVersion == VersionMode.recorrentes) ...[
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        title: 'Relatório dos planos',
                        icon: Icons.card_giftcard,
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RelatoriosPlanosScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Espaço para futuros botões
                    // Aqui podem ser adicionados mais botões no futuro
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

