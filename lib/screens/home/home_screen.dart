import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:clisync/screens/clientes/cadastro/cadastro_cliente_screen.dart';
import 'package:clisync/screens/clientes/cadastro/cadastro_cliente_unico_screen.dart';
import 'package:clisync/screens/clientes/listas/lista_clientes_screen.dart';
import 'package:clisync/screens/clientes/listas/lista_clientes_unicos_screen.dart';
import 'package:clisync/screens/clientes/proximos_servicos_screen.dart';
import 'package:clisync/screens/relatorios/pendencias/pendencias_screen.dart';
import 'package:clisync/screens/relatorios/dados_relatorios_menu_screen.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/services/version_service.dart';
import 'package:clisync/models/usuario.dart';
import 'package:clisync/theme/app_theme.dart';
import 'package:clisync/screens/configuracao/editar_perfil_screen.dart';
import 'package:clisync/screens/onboarding/configuracao_servicos_screen.dart';
import 'package:clisync/screens/configuracao/configuracao_clientes_unicos_screen.dart';
import 'package:clisync/screens/configuracao/configuracao_campos_screen.dart';
import 'package:clisync/screens/configuracao/faq_screen.dart';
import 'package:clisync/screens/clientes/Planos/planos_screen.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isSidebarOpen = false;
  Usuario? _currentUser;
  VersionMode _currentVersion = VersionMode.unicos;
  bool _isLoadingVersion = true;
  bool _isToggling = false; 
  bool _isLoadingUser = false;
  bool _hasInitialized = false;
  Key _homeContentKey = UniqueKey();

  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadVersionMode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        _refreshHome();
      }
    });
  }

  Future<void> _loadVersionMode() async {
    final version = await VersionService.getVersionMode();
    setState(() {
      _currentVersion = version;
      _updateScreens();
      _isLoadingVersion = false;
    });
  }

  void _updateScreens() {
    if (_currentVersion == VersionMode.recorrentes) {
      _screens = [
        HomeContent(key: _homeContentKey, onRefresh: _refreshHome),
        const ListaClientesScreen(),
        const DadosRelatoriosMenuScreen(),
      ];
    } else {
      _screens = [
        HomeContent(key: _homeContentKey, onRefresh: _refreshHome),
        const ListaClientesUnicosScreen(),
        const ProximosServicosScreen(),
        const DadosRelatoriosMenuScreen(),
      ];
    }
  }

  Future<void> _refreshHome() async {
    // Previne múltiplas chamadas simultâneas
    if (_isLoadingUser) return;
    
    await _loadCurrentUser();
    if (mounted) {
      setState(() {
        _homeContentKey = UniqueKey();
        _updateScreens();
      });
    }
  }

  Future<void> _toggleVersion() async {
    // Previne cliques múltiplos
    if (_isToggling) return;

    setState(() {
      _isToggling = true;
    });

    try {
      final newVersion = _currentVersion == VersionMode.recorrentes
          ? VersionMode.unicos
          : VersionMode.recorrentes;

      await VersionService.setVersionMode(newVersion);

      if (mounted) {
        setState(() {
          _currentVersion = newVersion;
          _currentIndex = 0; 
          _updateScreens();
          _isToggling = false;
        });

        // Força reconstrução da seção de ações rápidas
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    // Previne múltiplas chamadas simultâneas
    if (_isLoadingUser) return;
    
    _isLoadingUser = true;
    
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user != null) {
        final databaseService = DatabaseService();
        final userData = await databaseService.getUser(user.uid);
        if (userData != null) {
          final usuario = Usuario.fromMap(user.uid, userData);
          if (mounted) {
            setState(() {
              _currentUser = usuario;
            });
          }
        }
      }
    } finally {
      _isLoadingUser = false;
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingVersion || _screens.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Conteúdo principal com tratamento de erro
          Builder(
            builder: (context) {
              try {
                return IndexedStack(index: _currentIndex, children: _screens);
              } catch (e) {
                // Se houver erro, mostra uma tela de erro ao invés de tela em branco
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Erro ao carregar a tela',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.toString(),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _homeContentKey = UniqueKey();
                              _updateScreens();
                            });
                          },
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),

          // Overlay para fechar sidebar ao tocar fora
          if (_currentIndex == 0 && _isSidebarOpen)
            GestureDetector(
              onTap: _toggleSidebar,
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),

          // Sidebar (apenas na tela home) - por último para ficar acima de tudo
          if (_currentIndex == 0) _buildSidebar(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _isSidebarOpen = false; // Fecha sidebar ao trocar de aba
          });
        },
        items: _currentVersion == VersionMode.recorrentes
            ? [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Clientes',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.info),
                  
                  label: 'Relatórios',
                ),
              ]
            : [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Clientes',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Agendamento',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.info),
                  label: 'Relatórios',
                ),
              ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        _currentVersion == VersionMode.recorrentes
                        ? const CadastroClienteScreen()
                        : const CadastroClienteUnicoScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildSidebar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      left: _isSidebarOpen ? 0 : -300,
      top: 0,
      bottom: 0,
      width: 280,
      child: Material(
        elevation: 10,
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // Área do perfil do usuário
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Foto do usuário
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Nome do usuário
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá,',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentUser?.nome ?? 'Usuário',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Links de navegação
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.person, 'Conta', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditarPerfilScreen(),
                          ),
                        );
                      }),
                      _buildMenuItem(Icons.help_outline, 'FAQs', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FAQScreen(),
                          ),
                        );
                      }),
                      const Spacer(),
                      
                      // Redes Sociais
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      const Text(
                        'Redes Sociais',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialIcon(
                            Icons.camera_alt,
                            'Instagram',
                            'https://www.instagram.com/clisync.app/',
                            Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          _buildSocialIcon(
                            Icons.language,
                            'Site',
                            'https://clisync.com.br/',
                            Colors.blue,
                          ),
                          const SizedBox(width: 16),
                          _buildSocialIcon(
                            Icons.tiktok,
                            'TikTok',
                            'https://www.tiktok.com/@clisync.app',
                            Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Botão de logout
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                      _toggleSidebar();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String tooltip, String url, Color color) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!await launchUrlString(url, mode: LaunchMode.externalApplication)) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Não foi possível abrir o link.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final Future<void> Function()? onRefresh;

  const HomeContent({super.key, this.onRefresh});

  @override
  State<HomeContent> createState() => _HomeContentState();
}


class _HomeContentState extends State<HomeContent> {
  final GlobalKey<_ProximosServicosListState> _proximosServicosKey =
      GlobalKey<_ProximosServicosListState>();
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent - 120 &&
        !_isRefreshing) {
      _handleRefresh();
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
    await _proximosServicosKey.currentState?.recarregar();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Header com ícone de hambúrguer
                SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        child: IconButton(
                          onPressed: () {
                            final homeState =
                                context.findAncestorStateOfType<_HomeScreenState>();
                            homeState?._toggleSidebar();
                          },
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 28,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          width: 150,
                          height: 100,
                          child: ClipOval(
                            child: Image.asset(
                              "lib/image/logo-completa-clisync.png",
                              fit: BoxFit.fitWidth,
                              errorBuilder: (context, error, stackTrace) {
                                // Se a imagem não carregar, mostra um ícone alternativo
                                return const Icon(
                                  Icons.business,
                                  size: 80,
                                  color: Colors.white70,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Card de Ações Pendentes
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          'Selecione o modo:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _HomeVersionToggleButton(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ServicosEAcoesSection(
                  proximosServicosKey: _proximosServicosKey,
                ),
                // Card de Configuração (apenas no modo Únicos)
                Builder(
                  builder: (context) {
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    final currentVersion = homeState?._currentVersion ?? VersionMode.unicos;
                    if (currentVersion == VersionMode.unicos) {
                      return Column(
                        children: [
                          const SizedBox(height: 24),
                          _buildConfiguracaoCard(),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguracaoCard() {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final usuario = homeState?._currentUser;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Configurações do sistema',
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
                  child: ElevatedButton.icon(
                    onPressed: usuario != null
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConfiguracaoServicosScreen(usuario: usuario),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.wallet_travel),
                    label: const Text('Serviços'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConfiguracaoClientesUnicosScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Campos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
}

class _AcoesPendentesCard extends StatelessWidget {
  const _AcoesPendentesCard();

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final usuario = homeState?._currentUser;
    
    // Verifica se há ações pendentes
    if (usuario == null) {
      return const SizedBox.shrink();
    }
    
    final List<Map<String, dynamic>> acoesPendentes = [];
    
    // Verifica se nome da empresa está vazio
    if (usuario.nomeEmpresa == null || usuario.nomeEmpresa!.trim().isEmpty) {
      acoesPendentes.add({
        'titulo': 'Preencher dados da empresa',
        'icone': Icons.business,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditarPerfilScreen(),
            ),
          ).then((_) {
            // Recarrega o usuário após voltar da tela de editar perfil
            homeState?._refreshHome();
          });
        },
      });
    }
    
    // Verifica se há serviços cadastrados
    final temServicosUnicos = usuario.servicosUnicos.isNotEmpty;
    final temServicosRecorrentes = usuario.servicosRecorrentes.isNotEmpty;
    
    if (!temServicosUnicos && !temServicosRecorrentes) {
      acoesPendentes.add({
        'titulo': 'Adicionar um serviço',
        'icone': Icons.add_business,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfiguracaoServicosScreen(usuario: usuario),
            ),
          ).then((_) {
            // Recarrega o usuário após voltar da tela de configuração de serviços
            homeState?._refreshHome();
          });
        },
      });
    }
    
    // Se não houver ações pendentes, não mostra o card
    if (acoesPendentes.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        Card(
          color: Colors.orange.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Ações Pendentes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...acoesPendentes.map((acao) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: acao['onTap'] as VoidCallback,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              acao['icone'] as IconData,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                acao['titulo'] as String,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _HomeVersionToggleButton extends StatefulWidget {
  const _HomeVersionToggleButton();

  @override
  State<_HomeVersionToggleButton> createState() =>
      _HomeVersionToggleButtonState();
}

class _HomeVersionToggleButtonState extends State<_HomeVersionToggleButton> {
  void _handleModeChange(VersionMode newMode) async {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    // Só muda se o modo for diferente
    if (homeState?._currentVersion != newMode) {
      await homeState?._toggleVersion();
    }
    // Força reconstrução depois que o toggle terminar
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final currentVersion = homeState?._currentVersion ?? VersionMode.unicos;

    return Row(
      children: [
        // Botão de Clientes Únicos
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleModeChange(VersionMode.unicos),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentVersion == VersionMode.unicos
                  ? Colors.green
                  : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Únicos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Clientes únicos',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Botão de Clientes Recorrentes
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleModeChange(VersionMode.recorrentes),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentVersion == VersionMode.recorrentes
                  ? Colors.green
                  : AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.card_giftcard, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Planos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Clientes cadastrados',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ServicosEAcoesSection extends StatefulWidget {
  final GlobalKey<_ProximosServicosListState> proximosServicosKey;

  const _ServicosEAcoesSection({required this.proximosServicosKey});

  @override
  State<_ServicosEAcoesSection> createState() => _ServicosEAcoesSectionState();
}

class _ServicosEAcoesSectionState extends State<_ServicosEAcoesSection> {
  String? _linkFormulario;

  // Verifica se as informações necessárias estão preenchidas
  Future<bool> _verificarInformacoesPreenchidas(_HomeScreenState? homeState) async {
    final usuario = homeState?._currentUser;
    if (usuario == null) return false;
    
    // Verifica nome da empresa
    final temNomeEmpresa = usuario.nomeEmpresa != null && 
                           usuario.nomeEmpresa!.trim().isNotEmpty;
    
    // Verifica se há serviços cadastrados
    final temServicosUnicos = usuario.servicosUnicos.isNotEmpty;
    final temServicosRecorrentes = usuario.servicosRecorrentes.isNotEmpty;
    final temServicos = temServicosUnicos || temServicosRecorrentes;
    
    // Verifica se há configuração de campos para clientes únicos salva no Firebase
    bool temConfiguracaoCampos = false;
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user != null) {
        final database = FirebaseDatabase.instance;
        final configRef = database.ref('usuarios/${user.uid}/configuracao_unicos');
        final snapshot = await configRef.get();
        if (snapshot.exists && snapshot.value != null) {
          // Verifica se há pelo menos um campo configurado (mesmo que seja false)
          final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
          // Remove campos que não são de configuração (como camposPersonalizados)
          data.remove('camposPersonalizados');
          temConfiguracaoCampos = data.isNotEmpty;
        }
      }
    } catch (e) {
      temConfiguracaoCampos = false;
    }
    
    return temNomeEmpresa && temServicos && temConfiguracaoCampos;
  }

  // Obtém lista de ações pendentes
  Future<List<Map<String, dynamic>>> _obterAcoesPendentes(_HomeScreenState? homeState) async {
    final usuario = homeState?._currentUser;
    if (usuario == null) return [];
    
    final List<Map<String, dynamic>> acoesPendentes = [];
    
    // Verifica se nome da empresa está vazio
    if (usuario.nomeEmpresa == null || usuario.nomeEmpresa!.trim().isEmpty) {
      acoesPendentes.add({
        'titulo': 'Preencher dados da empresa',
        'icone': Icons.business,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditarPerfilScreen(),
            ),
          ).then((_) async {
            // Recarrega o usuário após voltar da tela de editar perfil
            await homeState?._refreshHome();
            // Fecha o dialog se ainda estiver aberto
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // Força atualização do botão após recarregar
            if (mounted) {
              setState(() {});
            }
          });
        },
      });
    }
    
    // Verifica se há serviços cadastrados
    final temServicosUnicos = usuario.servicosUnicos.isNotEmpty;
    final temServicosRecorrentes = usuario.servicosRecorrentes.isNotEmpty;
    
    if (!temServicosUnicos && !temServicosRecorrentes) {
      acoesPendentes.add({
        'titulo': 'Adicionar um serviço',
        'icone': Icons.add_business,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfiguracaoServicosScreen(usuario: usuario),
            ),
          ).then((_) async {
            // Recarrega o usuário após voltar da tela de configuração de serviços
            await homeState?._refreshHome();
            // Fecha o dialog se ainda estiver aberto
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // Força atualização do botão após recarregar
            if (mounted) {
              setState(() {});
            }
          });
        },
      });
    }
    
    // Verifica se há configuração de campos para clientes únicos salva no Firebase
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      if (user != null) {
        final database = FirebaseDatabase.instance;
        final configRef = database.ref('usuarios/${user.uid}/configuracao_unicos');
        final snapshot = await configRef.get();
        
        bool temConfiguracao = false;
        if (snapshot.exists && snapshot.value != null) {
          // Verifica se há pelo menos um campo configurado (mesmo que seja false)
          final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
          // Remove campos que não são de configuração (como camposPersonalizados)
          data.remove('camposPersonalizados');
          temConfiguracao = data.isNotEmpty;
        }
        
        if (!temConfiguracao) {
          acoesPendentes.add({
            'titulo': 'Configurar campos do formulario',
            'icone': Icons.settings,
            'onTap': () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfiguracaoClientesUnicosScreen(),
                ),
              ).then((_) async {
                // Recarrega após voltar da tela de configuração
                // Fecha o dialog se ainda estiver aberto
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                // Força atualização do botão após recarregar
                if (mounted) {
                  setState(() {});
                  await _verificarInformacoes();
                }
              });
            },
          });
        }
      }
    } catch (e) {
      // Se der erro ao carregar, adiciona como pendente
      acoesPendentes.add({
        'titulo': 'Configurar campos dos clientes únicos',
        'icone': Icons.settings,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ConfiguracaoClientesUnicosScreen(),
            ),
          ).then((_) async {
            // Fecha o dialog se ainda estiver aberto
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            // Força atualização do botão após recarregar
            if (mounted) {
              setState(() {});
              await _verificarInformacoes();
            }
          });
        },
      });
    }
    
    return acoesPendentes;
  }

  // Mostra dialog com ações pendentes
  void _mostrarDialogAcoesPendentes(_HomeScreenState? homeState) async {
    final acoesPendentes = await _obterAcoesPendentes(homeState);
    
    if (acoesPendentes.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF374151),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Ações Pendentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Para gerar o link do formulário, é necessário preencher as seguintes informações:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              ...acoesPendentes.map((acao) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: acao['onTap'] as VoidCallback,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            acao['icone'] as IconData,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              acao['titulo'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  bool _informacoesPreenchidas = false;

  @override
  void initState() {
    super.initState();
    _verificarInformacoes();
  }

  Future<void> _verificarInformacoes() async {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final preenchidas = await _verificarInformacoesPreenchidas(homeState);
    if (mounted) {
      setState(() {
        _informacoesPreenchidas = preenchidas;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final currentVersion = homeState?._currentVersion ?? VersionMode.unicos;

    if (currentVersion == VersionMode.unicos) {
      // Versão Únicos: Mostra Próximos Serviços
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                'Próximos Serviços',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _ProximosServicosList(key: widget.proximosServicosKey),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _informacoesPreenchidas
                      ? () => _mostrarLinkFormulario(homeState)
                      : () => _mostrarDialogAcoesPendentes(homeState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _informacoesPreenchidas
                        ? AppTheme.primaryColor
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _linkFormulario != null ? () => _abrirLink(_linkFormulario!) : null,
                          child: Text(
                            _linkFormulario ?? 'Gerar e copiar link do formulário',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              decoration: _linkFormulario != null ? TextDecoration.underline : TextDecoration.none,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.copy),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Versão Recorrentes: Mostra Ações Rápidas
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                'Ações Rápidas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildAcoesRapidasRecorrentes(),
            ],
          ),
        ),
      );
    }
  }

  void _mostrarLinkFormulario(_HomeScreenState? homeState) async {
    final usuario = homeState?._currentUser;
    if (usuario == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não identificado. Tente novamente em instantes.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verifica novamente se as informações estão preenchidas antes de gerar o link
    final informacoesPreenchidas = await _verificarInformacoesPreenchidas(homeState);
    if (!informacoesPreenchidas) {
      _mostrarDialogAcoesPendentes(homeState);
      return;
    }

    final link = 'https://clisync.com.br/agendamento/index.php?id=${usuario.uid}';

    setState(() {
      _linkFormulario = link;
    });

    Clipboard.setData(ClipboardData(text: link));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copiado para a área de transferência.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _abrirLink(String link) async {
    if (!await launchUrlString(link, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o link.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAcoesRapidasRecorrentes() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CadastroClienteScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Novo Cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendenciasScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.warning),
                label: const Text('Pendências'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlanosScreen(),
                ),
              );
            },
            icon: const Icon(Icons.card_giftcard),
            label: const Text('Criação dos planos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProximosServicosList extends StatefulWidget {
  const _ProximosServicosList({super.key});

  @override
  State<_ProximosServicosList> createState() => _ProximosServicosListState();
}

class _ProximosServicosListState extends State<_ProximosServicosList> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _proximosServicos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarProximosServicos();
  }

  Future<void> recarregar() async {
    await _carregarProximosServicos();
  }

  Future<void> _carregarProximosServicos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final servicos = await _databaseService.getProximosServicosAgendados(
          user.uid,
          limite: 3,
        );
        setState(() {
          _proximosServicos = servicos;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_proximosServicos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Nenhum serviço agendado',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final servico in _proximosServicos)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          servico['tipoServico'] != null && (servico['tipoServico'] as String).isNotEmpty
                              ? '${servico['nomeCliente']} - ${servico['tipoServico']}'
                              : servico['nomeCliente'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${servico['data']} - ${servico['horario']}',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
