import 'package:flutter/material.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
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
  State<DetalhesMesUnicosScreen> createState() => _DetalhesMesUnicosScreenState();
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
        final relatorio = await _databaseService.getRelatorioMesUnicos(user.uid, widget.mesAno);
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
                                      'Total de serviços',
                                      _relatorio!['totalServicos'].toString(),
                                      Icons.work,
                                      Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              _buildInfoCard(
                                'Valor total',
                                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(_relatorio!['valorTotal']),
                                Icons.attach_money,
                                Colors.green,
                                isFullWidth: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, {bool isFullWidth = false}) {
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
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

