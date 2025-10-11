import 'package:flutter/material.dart';
import 'package:vigilancia_app/models/cliente.dart';
import 'package:vigilancia_app/services/auth_service.dart';
import 'package:vigilancia_app/services/database_service.dart';
import 'package:vigilancia_app/utils/string_utils.dart';
import 'package:intl/intl.dart';

class PendenciasScreen extends StatefulWidget {
  final String? mesAno;

  const PendenciasScreen({super.key, this.mesAno});

  @override
  State<PendenciasScreen> createState() => _PendenciasScreenState();
}

class _PendenciasScreenState extends State<PendenciasScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final _buscaController = TextEditingController();
  List<Cliente> _clientesInadimplentes = [];
  List<Cliente> _clientesFiltrados = [];
  bool _isLoading = true;
  String _mesAno = '';
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
    _mesAno = widget.mesAno ?? DateFormat('yyyy-MM').format(DateTime.now());
    _carregarPendencias();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _filtrarClientes(String termo) {
    setState(() {
      _termoBusca = termo;
      if (_termoBusca.isEmpty) {
        _clientesFiltrados = List.from(_clientesInadimplentes);
      } else {
        final termoNormalizado = normalizarParaBusca(termo);
        _clientesFiltrados = _clientesInadimplentes.where((cliente) {
          final nomeNormalizado = normalizarParaBusca(cliente.nome);
          final ruaNormalizada = normalizarParaBusca(cliente.rua);
          
          final nomeMatch = nomeNormalizado.contains(termoNormalizado);
          final ruaMatch = ruaNormalizada.contains(termoNormalizado);
          return nomeMatch || ruaMatch;
        }).toList();
      }
    });
  }

  Future<void> _carregarPendencias() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final clientes = await _databaseService.getClientesInadimplentes(user.uid, _mesAno);
        
        setState(() {
          _clientesInadimplentes = clientes;
          _clientesFiltrados = List.from(clientes);
          _isLoading = false;
          _buscaController.clear();
          _termoBusca = '';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar pendências: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _marcarComoPago(Cliente cliente) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _databaseService.updateStatusPagamento(user.uid, cliente.id, _mesAno, true);
        _carregarPendencias();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pagamento registrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar pagamento: $e'),
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
        title: const Text('Pendências'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarPendencias,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumo das pendências
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Resumo das Pendências',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  _clientesInadimplentes.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const Text(
                                  'Clientes',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(
                                    _clientesInadimplentes.fold(0.0, (sum, c) => sum + c.valor)
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const Text(
                                  'Total',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Barra de busca
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _buscaController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou rua...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      suffixIcon: _termoBusca.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white70),
                              onPressed: () {
                                _buscaController.clear();
                                _filtrarClientes('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: _filtrarClientes,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Lista de clientes inadimplentes
                Expanded(
                  child: _clientesFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _termoBusca.isEmpty ? Icons.check_circle : Icons.search_off,
                                size: 64,
                                color: _termoBusca.isEmpty ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _termoBusca.isEmpty 
                                    ? 'Nenhuma pendência encontrada!'
                                    : 'Nenhum resultado encontrado',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                _termoBusca.isEmpty
                                    ? 'Todos os clientes estão em dia.'
                                    : 'Tente buscar por outro nome ou rua.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final cliente = _clientesFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                title: Text(
                                  cliente.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cliente.enderecoCompleto,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(cliente.valor)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Inadimplente',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _marcarComoPago(cliente),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(80, 32),
                                  ),
                                  child: const Text(
                                    'Pago',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
