import 'package:flutter/material.dart';
import 'package:clisync/screens/relatorios/detalhes/detalhes_mes_unicos_screen.dart';
import 'package:clisync/screens/relatorios/pendencias/pendencias_unicos_screen.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';

class FechamentoMesUnicosScreen extends StatefulWidget {
  const FechamentoMesUnicosScreen({super.key});

  @override
  State<FechamentoMesUnicosScreen> createState() => _FechamentoMesUnicosScreenState();
}

class _FechamentoMesUnicosScreenState extends State<FechamentoMesUnicosScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  
  String _anoSelecionado = DateTime.now().year.toString();
  Set<String> _mesesComServicos = {}; // Set de meses no formato "2025-12"
  List<int> _anosDisponiveis = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    await _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final clientesUnicos = await _databaseService.getClientesUnicos(user.uid);
        final agora = DateTime.now();
        final mesesComServicos = <String>{};
        
        // Percorre todos os clientes e seus históricos de serviços
        for (final cliente in clientesUnicos) {
          if (cliente.historicoServicos.isNotEmpty) {
            for (final entry in cliente.historicoServicos.entries) {
              final dataServico = entry.key; // Formato: "29-10-2025"
              
              try {
                // Tenta parsear a data no formato "dd-MM-yyyy"
                final partesData = dataServico.split('-');
                if (partesData.length == 3) {
                  final mesServico = int.parse(partesData[1]);
                  final anoServico = int.parse(partesData[2]);
                  
                  // Verifica se o mês é passado ou atual (não futuro)
                  final mesAno = DateTime(anoServico, mesServico, 1);
                  final mesAtual = DateTime(agora.year, agora.month, 1);
                  
                  if (mesAno.isBefore(mesAtual) || mesAno.isAtSameMomentAs(mesAtual)) {
                    // Formato: "2025-10"
                    final mesAnoFormatado = '$anoServico-${mesServico.toString().padLeft(2, '0')}';
                    mesesComServicos.add(mesAnoFormatado);
                  }
                }
              } catch (e) {
                // Ignora erros de parse
              }
            }
          }
        }
        
        _mesesComServicos = mesesComServicos;
        
        // Gera lista de anos disponíveis baseada nos meses com serviços
        if (_mesesComServicos.isNotEmpty) {
          final anosSet = _mesesComServicos.map((mesAno) {
            return int.parse(mesAno.split('-')[0]);
          }).toSet();
          
          _anosDisponiveis = anosSet.toList()..sort((a, b) => b.compareTo(a)); // Mais recente primeiro
          
          // Define o ano selecionado como o ano atual (se disponível) ou o primeiro ano
          if (_anosDisponiveis.contains(DateTime.now().year)) {
            _anoSelecionado = DateTime.now().year.toString();
          } else {
            _anoSelecionado = _anosDisponiveis.first.toString();
          }
        } else {
          // Se não há serviços, mostra pelo menos o ano atual
          _anosDisponiveis = [DateTime.now().year];
          _anoSelecionado = DateTime.now().year.toString();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  List<Map<String, dynamic>> get _meses {
    final meses = [
      {'nome': 'Janeiro', 'numero': 1},
      {'nome': 'Fevereiro', 'numero': 2},
      {'nome': 'Março', 'numero': 3},
      {'nome': 'Abril', 'numero': 4},
      {'nome': 'Maio', 'numero': 5},
      {'nome': 'Junho', 'numero': 6},
      {'nome': 'Julho', 'numero': 7},
      {'nome': 'Agosto', 'numero': 8},
      {'nome': 'Setembro', 'numero': 9},
      {'nome': 'Outubro', 'numero': 10},
      {'nome': 'Novembro', 'numero': 11},
      {'nome': 'Dezembro', 'numero': 12},
    ];

    final anoSelecionado = int.parse(_anoSelecionado);
    final agora = DateTime.now();

    // Filtra apenas os meses que têm serviços cadastrados no ano selecionado
    return meses.where((mes) {
      final mesNumero = mes['numero'] as int;
      final mesAno = '$anoSelecionado-${mesNumero.toString().padLeft(2, '0')}';
      
      // Verifica se o mês tem serviços cadastrados
      if (!_mesesComServicos.contains(mesAno)) {
        return false;
      }
      
      // Para o ano atual, só mostra meses até o mês atual (não futuros)
      if (anoSelecionado == agora.year) {
        return mesNumero <= agora.month;
      }
      
      // Para anos anteriores, mostra todos os meses que têm serviços
      return true;
    }).map((mes) {
      final mesNumero = mes['numero'] as int;
      final mesAno = '$anoSelecionado-${mesNumero.toString().padLeft(2, '0')}';
      final isMesAtual = anoSelecionado == agora.year && mesNumero == agora.month;
      
      return {
        'nome': mes['nome'],
        'numero': mes['numero'],
        'mesAno': mesAno,
        'nomeCompleto': '${mes['nome']} $anoSelecionado${isMesAtual ? ' (Atual)' : ''}',
      };
    }).toList()
      ..sort((a, b) => (b['numero'] as int).compareTo(a['numero'] as int)); // Mais recente primeiro
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fechamento do mês'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
          DropdownButton<String>(
            value: _anoSelecionado,
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white),
            items: _anosDisponiveis.map((ano) {
              return DropdownMenuItem<String>(
                value: ano.toString(),
                child: Text(ano.toString()),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _anoSelecionado = newValue;
                });
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _anosDisponiveis.isEmpty || _meses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum cliente cadastrado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cadastre seu primeiro cliente para ver os relatórios',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Seletor de ano
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.green),
                              const SizedBox(width: 12),
                              const Text(
                                'Ano: ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _anoSelecionado,
                                style: const TextStyle(fontSize: 16, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Lista de meses
                      Expanded(
                        child: _meses.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhum mês disponível para este ano',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _meses.length,
                                itemBuilder: (context, index) {
                                  final mes = _meses[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      title: Text(
                                        mes['nomeCompleto'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetalhesMesUnicosScreen(
                                              mesAno: mes['mesAno'],
                                              nomeMes: mes['nomeCompleto'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PendenciasUnicosScreen(),
            ),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.payment),
      ),
    );
  }
}

