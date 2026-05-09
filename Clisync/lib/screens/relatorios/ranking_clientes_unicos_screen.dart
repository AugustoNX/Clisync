import 'package:flutter/material.dart';
import 'package:clisync/models/cliente_unico.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/screens/clientes/detalhes/detalhes_cliente_unico_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RankingClientesUnicosScreen extends StatefulWidget {
  const RankingClientesUnicosScreen({super.key});

  @override
  State<RankingClientesUnicosScreen> createState() =>
      _RankingClientesUnicosScreenState();
}

class _RankingClientesUnicosScreenState
    extends State<RankingClientesUnicosScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _ranking = [];
  
  // AdMob Banner Ads
  static const String _adUnitId = 'ca-app-pub-9090801296043819/8708585799';
  static const int _clientesPorAnuncio = 5;
  Map<int, BannerAd?> _bannerAds = {};

  @override
  void initState() {
    super.initState();
    _carregarRanking();
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

  // Método para obter a lista de itens da classificação completa (com anúncios)
  List<Map<String, dynamic>> _getListaClassificacaoCompleta() {
    // Pega apenas os itens da classificação completa (pula os 3 primeiros se houver pódio)
    final inicio = _ranking.length >= 3 ? 3 : 0;
    final classificacaoCompleta = _ranking.sublist(inicio);
    
    if (classificacaoCompleta.isEmpty) return [];
    
    final List<Map<String, dynamic>> itemsComAnuncios = [];
    int clientesContados = 0;
    
    for (int i = 0; i < classificacaoCompleta.length; i++) {
      // Adiciona o cliente
      itemsComAnuncios.add({
        'tipo': 'cliente',
        'index': inicio + i,
        'dados': classificacaoCompleta[i],
      });
      clientesContados++;
      
      // Se já contou 5 clientes, adiciona um anúncio
      if (clientesContados >= _clientesPorAnuncio) {
        itemsComAnuncios.add({
          'tipo': 'anuncio',
          'index': itemsComAnuncios.length,
        });
        clientesContados = 0;
      }
    }
    
    // Se tiver menos de 5 clientes, adiciona anúncio no final
    if (classificacaoCompleta.length < _clientesPorAnuncio && itemsComAnuncios.isNotEmpty) {
      itemsComAnuncios.add({
        'tipo': 'anuncio',
        'index': itemsComAnuncios.length,
      });
    }
    
    return itemsComAnuncios;
  }

  Future<void> _carregarRanking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final clientes = await _databaseService.getClientesUnicos(user.uid);

        // Cria uma lista com cliente e quantidade de serviços
        final rankingData = <Map<String, dynamic>>[];

        for (final cliente in clientes) {
          // Conta serviços válidos (excluindo cancelados)
          int quantidadeServicos = 0;
          for (final entry in cliente.historicoServicos.entries) {
            final infoServico = entry.value;
            final status = infoServico['statusPagamento']?.toString();
            // Conta apenas serviços que não foram cancelados
            if (status != ClienteUnico.statusCancelado) {
              quantidadeServicos++;
            }
          }

          if (quantidadeServicos > 0) {
            rankingData.add({
              'cliente': cliente,
              'quantidade': quantidadeServicos,
            });
          }
        }

        // Ordena por quantidade (maior para menor)
        rankingData.sort(
          (a, b) => (b['quantidade'] as int).compareTo(a['quantidade'] as int),
        );

        setState(() {
          _ranking = rankingData;
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
            content: Text('Erro ao carregar ranking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPodioItem({
    required ClienteUnico cliente,
    required int quantidade,
    required int posicao,
    required Color cor,
    required double altura,
  }) {
    String medalha = '';

    switch (posicao) {
      case 1:
        medalha = '🥇';
        break;
      case 2:
        medalha = '🥈';
        break;
      case 3:
        medalha = '🥉';
        break;
    }

    return Container(
      height: altura,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Medalha e posição
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cor.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(medalha, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 8),
            // Barra do ranking
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalhesClienteUnicoScreen(
                    clienteUnico: cliente,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: cor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    cliente.nome,
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$quantidade serviço${quantidade > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking de Clientes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ranking.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 80,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum cliente com serviços',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quando houver clientes com serviços realizados, eles aparecerão aqui',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _carregarRanking,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pódio dos 3 primeiros
                    if (_ranking.length >= 3) ...[
                      const Text(
                        'Pódio',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(
                        height: 180,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1º lugar
                            if (_ranking.length >= 2)
                              Expanded(
                                child: _buildPodioItem(
                                  cliente:
                                      _ranking[0]['cliente'] as ClienteUnico,
                                  quantidade: _ranking[0]['quantidade'] as int,
                                  posicao: 1,
                                  cor: const Color(0xFFFFD700), // Ouro
                                  altura: 220,
                                ),
                              ),
                            // 2º lugar
                            Expanded(
                              child: _buildPodioItem(
                                cliente: _ranking[1]['cliente'] as ClienteUnico,
                                quantidade: _ranking[1]['quantidade'] as int,
                                posicao: 2,
                                cor: const Color(0xFFC0C0C0), // Prata
                                altura: 180,
                              ),
                            ),
                            // 3º lugar
                            if (_ranking.length >= 3)
                              Expanded(
                                child: _buildPodioItem(
                                  cliente:
                                      _ranking[2]['cliente'] as ClienteUnico,
                                  quantidade: _ranking[2]['quantidade'] as int,
                                  posicao: 3,
                                  cor: const Color(0xFFCD7F32), // Bronze
                                  altura: 160,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],

                    // Lista do restante do ranking
                    const Text(
                      'Classificação Completa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._getListaClassificacaoCompleta().map((itemMap) {
                      // Se é anúncio
                      if (itemMap['tipo'] == 'anuncio') {
                        final adIndex = itemMap['index'] as int;
                        
                        // Carrega o anúncio se ainda não foi carregado
                        if (_bannerAds[adIndex] == null) {
                          _carregarBannerAd(adIndex);
                        }
                        
                        final bannerAd = _bannerAds[adIndex];
                        if (bannerAd != null && bannerAd.size.height > 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: AdWidget(ad: bannerAd),
                            height: bannerAd.size.height.toDouble(),
                          );
                        } else {
                          // Retorna um container vazio enquanto o anúncio carrega
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            height: 50,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                      }
                      
                      // Se é cliente
                      final index = itemMap['index'] as int;
                      final item = itemMap['dados'] as Map<String, dynamic>;
                      final cliente = item['cliente'] as ClienteUnico;
                      final quantidade = item['quantidade'] as int;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetalhesClienteUnicoScreen(
                                    clienteUnico: cliente,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              cliente.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          subtitle: Text(
                            '$quantidade serviço${quantidade > 1 ? 's' : ''} realizado${quantidade > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$quantidade',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}
