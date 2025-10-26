import 'package:flutter/material.dart';
import 'package:clisync/screens/clientes/cadastro_cliente_screen.dart';
import 'package:clisync/screens/clientes/cadastro_cliente_unico_screen.dart';
import 'package:clisync/screens/clientes/lista_clientes_screen.dart';
import 'package:clisync/screens/relatorios/fechamento_mes_screen.dart';
import 'package:clisync/screens/relatorios/pendencias_screen.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/models/usuario.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isSidebarOpen = false;
  Usuario? _currentUser;

  final List<Widget> _screens = [
    const HomeContent(),
    const ListaClientesScreen(),
    const FechamentoMesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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
    return Scaffold(
      body: Stack(
        children: [
          // Conteúdo principal
          _screens[_currentIndex],
          
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Relatórios'),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CadastroClienteScreen(),
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
                const Spacer(),
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
            const SizedBox(height: 100),

            // Card de ações rápidas
            Card(
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

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CadastroClienteScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Novo Cliente'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PendenciasScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.warning),
                            label: const Text('Pendências'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CadastroClienteUnicoScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_outline),
                            label: const Text('Cliente Único'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(), // Espaço vazio para manter o layout
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
