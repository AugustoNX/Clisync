import 'package:flutter/material.dart';
import 'package:clisync/screens/relatorios/detalhes/detalhes_mes_screen.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class FechamentoMesScreen extends StatefulWidget {
  const FechamentoMesScreen({super.key});

  @override
  State<FechamentoMesScreen> createState() => _FechamentoMesScreenState();
}

class _FechamentoMesScreenState extends State<FechamentoMesScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  
  String _anoSelecionado = DateTime.now().year.toString();
  DateTime? _dataPrimeiroCliente;
  List<int> _anosDisponiveis = [];
  bool _isLoading = true;
  
  // AdMob Banner Ads
  static const String _adUnitId = 'ca-app-pub-9090801296043819/8708585799';
  static const int _mesesPorAnuncio = 5;
  Map<int, BannerAd?> _bannerAds = {};

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    // Dispose dos anúncios
    for (var ad in _bannerAds.values) {
      ad?.dispose();
    }
    _bannerAds.clear();
    super.dispose();
  }

  // Método para carregar um banner ad
  void _carregarBannerAd(int index) {
    if (_bannerAds[index] != null) return; // Já existe um anúncio para este índice
    
    final bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAds.remove(index);
            });
          }
        },
      ),
    );
    
    bannerAd.load();
    _bannerAds[index] = bannerAd;
  }

  // Método auxiliar para calcular o número total de itens (meses + anúncios)
  int _getTotalItems() {
    int totalMeses = _meses.length;
    if (totalMeses == 0) return 0;
    
    // Calcula quantos anúncios serão exibidos
    // A cada 5 meses, 1 anúncio
    int totalAnuncios = (totalMeses / _mesesPorAnuncio).floor();
    
    // Se tiver menos de 5 meses, adiciona 1 anúncio no final
    if (totalMeses < _mesesPorAnuncio) {
      totalAnuncios = 1;
    }
    
    return totalMeses + totalAnuncios;
  }

  // Método auxiliar para determinar se o índice é um anúncio e calcular o índice do mês
  Map<String, dynamic> _getItemType(int listIndex) {
    int totalMeses = _meses.length;
    if (totalMeses == 0) {
      return {'isAnuncio': false, 'mesIndex': -1};
    }
    
    // Se tiver menos de 5 meses, o último item é anúncio
    if (totalMeses < _mesesPorAnuncio && listIndex == totalMeses) {
      return {'isAnuncio': true, 'mesIndex': -1};
    }
    
    // Para 5 ou mais meses: anúncios aparecem a cada 5 meses
    int mesesMostrados = 0;
    
    for (int i = 0; i < listIndex; i++) {
      // Se já mostramos 5 meses, o próximo item é um anúncio
      if (mesesMostrados > 0 && mesesMostrados % _mesesPorAnuncio == 0) {
        // Este é um anúncio, não conta como mês
        continue;
      }
      // Caso contrário, é um mês
      mesesMostrados++;
    }
    
    // Verifica se este índice deve ser um anúncio
    if (mesesMostrados > 0 && mesesMostrados % _mesesPorAnuncio == 0) {
      return {'isAnuncio': true, 'mesIndex': -1};
    }
    
    // Não é anúncio, retorna o índice do mês
    return {'isAnuncio': false, 'mesIndex': mesesMostrados};
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
        // Processa virada de mês automaticamente
        await _databaseService.processarViradaMes(user.uid);
        
        final clientes = await _databaseService.getClientes(user.uid);
        
        if (clientes.isNotEmpty) {
          // Encontra a data do primeiro cliente cadastrado
          _dataPrimeiroCliente = clientes
              .map((c) => c.dataCadastro)
              .reduce((a, b) => a.isBefore(b) ? a : b);
          
          // Gera lista de anos disponíveis a partir do primeiro cliente
          _anosDisponiveis = _gerarAnosDisponiveis();
          
          // Define o ano selecionado como o ano atual (se disponível) ou o primeiro ano
          if (_anosDisponiveis.contains(DateTime.now().year)) {
            _anoSelecionado = DateTime.now().year.toString();
          } else {
            _anoSelecionado = _anosDisponiveis.first.toString();
          }
        } else {
          // Se não há clientes, mostra pelo menos o ano atual
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

  List<int> _gerarAnosDisponiveis() {
    if (_dataPrimeiroCliente == null) return [DateTime.now().year];
    
    final anos = <int>[];
    final anoAtual = DateTime.now().year;
    final anoPrimeiroCliente = _dataPrimeiroCliente!.year;
    
    for (int ano = anoPrimeiroCliente; ano <= anoAtual; ano++) {
      anos.add(ano);
    }
    
    return anos.reversed.toList(); // Mais recente primeiro
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

    // Lógica simplificada: sempre mostra o mês atual se estamos no ano atual
    if (anoSelecionado == agora.year) {
      return meses.where((mes) {
        final mesNumero = mes['numero'] as int;
        // Mostra apenas o mês atual se não há dados históricos
        if (_dataPrimeiroCliente == null) {
          return mesNumero == agora.month;
        }
        // Mostra meses a partir do primeiro cliente até o atual
        final primeiroMes = _dataPrimeiroCliente!.month;
        final primeiroAno = _dataPrimeiroCliente!.year;
        
        if (primeiroAno == agora.year) {
          return mesNumero >= primeiroMes && mesNumero <= agora.month;
        } else {
          return mesNumero <= agora.month;
        }
      }).map((mes) {
        final mesAno = '$_anoSelecionado-${mes['numero'].toString().padLeft(2, '0')}';
        final mesNumero = mes['numero'] as int;
        final isMesAtual = mesNumero == agora.month;
        
        return {
          'nome': mes['nome'],
          'numero': mes['numero'],
          'mesAno': mesAno,
          'nomeCompleto': '${mes['nome']} $_anoSelecionado${isMesAtual ? ' (Atual)' : ''}',
        };
      }).toList();
    }
    
    // Para anos anteriores, mostra todos os meses do ano
    return meses.map((mes) {
      final mesAno = '$_anoSelecionado-${mes['numero'].toString().padLeft(2, '0')}';
      
      return {
        'nome': mes['nome'],
        'numero': mes['numero'],
        'mesAno': mesAno,
        'nomeCompleto': '${mes['nome']} $_anoSelecionado',
      };
    }).toList();
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
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 12),
                              const Text(
                                'Ano: ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _anoSelecionado,
                                style: const TextStyle(fontSize: 16, color: Colors.blue),
                              ),
                              const SizedBox(width: 8),
                              if (_dataPrimeiroCliente != null)
                                Flexible(
                                  child: Text(
                                    'Desde ${DateFormat('MMM/yyyy').format(_dataPrimeiroCliente!)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                                itemCount: _getTotalItems(),
                                itemBuilder: (context, index) {
                                  // Determina se é anúncio ou mês
                                  final itemInfo = _getItemType(index);
                                  
                                  // Se é anúncio
                                  if (itemInfo['isAnuncio'] == true) {
                                    // Carrega o anúncio se ainda não foi carregado
                                    if (_bannerAds[index] == null) {
                                      _carregarBannerAd(index);
                                    }
                                    
                                    final bannerAd = _bannerAds[index];
                                    if (bannerAd != null && bannerAd.size.height > 0) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        width: double.infinity,
                                        alignment: Alignment.center,
                                        child: AdWidget(ad: bannerAd),
                                        height: bannerAd.size.height.toDouble(),
                                      );
                                    } else {
                                      // Retorna um container vazio enquanto o anúncio carrega
                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        height: 50,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                  }
                                  
                                  // Se não é anúncio, exibe o mês
                                  final mesIndex = itemInfo['mesIndex'] as int;
                                  if (mesIndex < 0 || mesIndex >= _meses.length) {
                                    return const SizedBox.shrink();
                                  }
                                  
                                  final mes = _meses[mesIndex];
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
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetalhesMesScreen(
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
    );
  }
}
