import 'package:flutter/material.dart';
import 'package:clisync/screens/clientes/cadastro_cliente_screen.dart';
import 'package:clisync/screens/clientes/cadastro_cliente_unico_screen.dart';
import 'package:clisync/screens/clientes/lista_clientes_screen.dart';
import 'package:clisync/screens/clientes/lista_clientes_unicos_screen.dart';
import 'package:clisync/screens/relatorios/fechamento_mes_screen.dart';
import 'package:clisync/screens/relatorios/fechamento_mes_unicos_screen.dart';
import 'package:clisync/screens/relatorios/pendencias_screen.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/services/version_service.dart';
import 'package:clisync/models/usuario.dart';
import 'package:clisync/theme/app_theme.dart';

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
  bool _isToggling = false; // Previne cliques múltiplos

  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadVersionMode();
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
        HomeContent(key: ValueKey('recorrentes')),
        const ListaClientesScreen(),
        const FechamentoMesScreen(),
      ];
    } else {
      _screens = [
        HomeContent(key: ValueKey('unicos')),
        const ListaClientesUnicosScreen(),
        const FechamentoMesUnicosScreen(),
      ];
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
          _currentIndex = 0; // Volta para a home ao trocar de versão
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
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null) {
      final databaseService = DatabaseService();
      final userData = await databaseService.getUser(user.uid);
      if (userData != null) {
        setState(() {
          _currentUser = Usuario.fromMap(user.uid, userData);
        });
      }
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Conteúdo principal
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          
          // Overlay para fechar sidebar ao tocar fora
          if (_currentIndex == 0 && _isSidebarOpen)
            GestureDetector(
              onTap: _toggleSidebar,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
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
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Home'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people), 
            label: _currentVersion == VersionMode.recorrentes ? 'Clientes' : 'Clientes Únicos',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Relatórios'),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _currentVersion == VersionMode.recorrentes
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    _buildMenuItem(Icons.home, 'Home', () {
                      setState(() {
                        _currentIndex = 0;
                        _isSidebarOpen = false;
                      });
                    }),
                    _buildMenuItem(Icons.person, 'Perfil', () {
                      // TODO: Implementar tela de perfil
                      _toggleSidebar();
                    }),
                    _buildMenuItem(Icons.history, 'Histórico', () {
                      // TODO: Implementar tela de histórico
                      _toggleSidebar();
                    }),
                    _buildMenuItem(Icons.edit, 'Autor', () {
                      // TODO: Implementar tela de autor
                      _toggleSidebar();
                    }),
                    _buildMenuItem(Icons.notifications, 'Notificações', () {
                      // TODO: Implementar tela de notificações
                      _toggleSidebar();
                    }),
                    _buildMenuItem(Icons.help, 'Ajuda', () {
                      // TODO: Implementar tela de ajuda
                      _toggleSidebar();
                    }),
                    _buildMenuItem(Icons.settings, 'Configurações', () {
                      // TODO: Implementar tela de configurações
                      _toggleSidebar();
                    }),
                    
                    // Espaço flexível para empurrar o botão para baixo
                    const Spacer(),
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
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
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

}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Header com ícone de hambúrguer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    // Acessa o estado da HomeScreen através do contexto
                    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                    homeState?._toggleSidebar();
                  },
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 28,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            Center(
              child: SizedBox(
                width: 180,
                height: 120,
                child: ClipOval(
                  child: Image.asset(
                    "lib/image/logo-completa-clisync.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),

            // Card de ações rápidas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Modo do Sistema',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Botão para alternar versão
                    const _HomeVersionToggleButton(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Seção de Próximos Serviços / Ações Rápidas
            const _ServicosEAcoesSection(),
          ],
          ),
        ),
      ),
    );
  }
}

class _HomeVersionToggleButton extends StatefulWidget {
  const _HomeVersionToggleButton();

  @override
  State<_HomeVersionToggleButton> createState() => _HomeVersionToggleButtonState();
}

class _HomeVersionToggleButtonState extends State<_HomeVersionToggleButton> {
  void _handleToggle() async {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    await homeState?._toggleVersion();
    // Força reconstrução depois que o toggle terminar
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = context.findAncestorStateOfType<_HomeScreenState>();
    final currentVersion = homeState?._currentVersion ?? VersionMode.unicos;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleToggle,
        style: ElevatedButton.styleFrom(
          backgroundColor: currentVersion == VersionMode.recorrentes
              ? AppTheme.primaryColor
              : Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              currentVersion == VersionMode.recorrentes
                  ? Icons.repeat
                  : Icons.person_outline,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentVersion == VersionMode.recorrentes
                        ? 'Clientes Recorrentes'
                        : 'Clientes Únicos',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentVersion == VersionMode.recorrentes
                        ? 'Clientes com pagamento recorrente'
                        : 'Clientes ou serviços únicos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicosEAcoesSection extends StatefulWidget {
  const _ServicosEAcoesSection();

  @override
  State<_ServicosEAcoesSection> createState() => _ServicosEAcoesSectionState();
}

class _ServicosEAcoesSectionState extends State<_ServicosEAcoesSection> {
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
              const _ProximosServicosList(),
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

  Widget _buildAcoesRapidasRecorrentes() {
    return Row(
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
    );
  }
}

class _ProximosServicosList extends StatefulWidget {
  const _ProximosServicosList();

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

  Future<void> _carregarProximosServicos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final servicos = await _databaseService.getProximosServicosAgendados(user.uid, limite: 4);
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
      children: _proximosServicos.map((servico) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
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
                        servico['nomeCliente'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${servico['data']} - ${servico['horario']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
