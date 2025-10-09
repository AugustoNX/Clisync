import 'package:flutter/material.dart';
import 'package:vigilancia_app/models/cliente.dart';
import 'package:vigilancia_app/screens/clientes/cadastro_cliente_screen.dart';
import 'package:vigilancia_app/services/auth_service.dart';
import 'package:vigilancia_app/services/database_service.dart';
import 'package:intl/intl.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class ListaClientesScreen extends StatefulWidget {
  const ListaClientesScreen({super.key});

  @override
  State<ListaClientesScreen> createState() => _ListaClientesScreenState();
}

class _ListaClientesScreenState extends State<ListaClientesScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  List<Cliente> _clientes = [];
  List<Cliente> _clientesFiltrados = [];
  bool _isLoading = true;
  String? _modalidadeFiltro;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarClientes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Processa virada de mês automaticamente
        await _databaseService.processarViradaMes(user.uid);
        
        final clientes = await _databaseService.getClientes(user.uid);
        setState(() {
          _clientes = clientes;
          _clientesFiltrados = clientes;
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
            content: Text('Erro ao carregar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filtrarClientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _clientesFiltrados = _clientes.where((cliente) {
        // Filtro por busca de endereço
        bool buscaMatch =
            query.isEmpty ||
            cliente.nome.toLowerCase().contains(query) ||
            cliente.enderecoCompleto.toLowerCase().contains(query) ||
            cliente.rua.toLowerCase().contains(query) ||
            cliente.bairro.toLowerCase().contains(query) ||
            cliente.cidade.toLowerCase().contains(query);

        // Filtro por modalidade
        bool modalidadeMatch =
            _modalidadeFiltro == null ||
            cliente.modalidade.toLowerCase() ==
                _modalidadeFiltro!.toLowerCase();

        return buscaMatch && modalidadeMatch;
      }).toList();
    });
  }

  Future<void> _alterarStatusCliente(Cliente cliente) async {
    final novoStatus = cliente.isAtivo ? 'desativado' : 'ativo';
    final acao = cliente.isAtivo ? 'pausar' : 'reativar';

    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar $acao'),
        content: Text('Deseja realmente $acao o cliente ${cliente.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              acao.capitalize(),
              style: TextStyle(
                color: cliente.isAtivo ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      try {
        final user = _authService.currentUser;
        if (user != null) {
          final clienteAtualizado = cliente.copyWith(status: novoStatus);
          await _databaseService.updateCliente(
            user.uid,
            cliente.id,
            clienteAtualizado,
          );
          _carregarClientes();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cliente ${acao}do com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao $acao cliente: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletarCliente(Cliente cliente) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o cliente ${cliente.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      try {
        final user = _authService.currentUser;
        if (user != null) {
          await _databaseService.deleteCliente(user.uid, cliente.id);
          _carregarClientes();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cliente excluído com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir cliente: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarClientes,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Filtro por modalidade
                DropdownButtonFormField<String>(
                  value: _modalidadeFiltro,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por Modalidade',
                    prefixIcon: Icon(Icons.filter_list, color: Colors.white70),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas as modalidades'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'residencial',
                      child: Text('Residencial'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'comercial',
                      child: Text('Comercial'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'industrial',
                      child: Text('Industrial'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      _modalidadeFiltro = newValue;
                    });
                    _filtrarClientes();
                  },
                ),
                const SizedBox(height: 16),

                // Campo de busca por endereço
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar por nome ou endereço...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filtrarClientes();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => _filtrarClientes(),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clientesFiltrados.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum cliente encontrado',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: _clientesFiltrados.length,
                    itemBuilder: (context, index) {
                      final cliente = _clientesFiltrados[index];
                      final mesAtual = DateFormat(
                        'yyyy-MM',
                      ).format(DateTime.now());
                      final isAdimplente = cliente.isAdimplente(mesAtual);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
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
                                      color: Colors.green,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cliente.modalidade,
                                style: const TextStyle(color: Colors.white54),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAdimplente
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isAdimplente
                                          ? 'Adimplente'
                                          : 'Inadimplente',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cliente.isAtivo
                                          ? Colors.blue
                                          : Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      cliente.isAtivo ? 'Ativo' : 'Pausado',
                                      style: const TextStyle(
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
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: cliente.isAtivo ? 'pause' : 'activate',
                                child: Row(
                                  children: [
                                    Icon(
                                      cliente.isAtivo
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: cliente.isAtivo
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      cliente.isAtivo ? 'Pausar' : 'Reativar',
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Excluir'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CadastroClienteScreen(cliente: cliente),
                                  ),
                                );
                              } else if (value == 'pause' ||
                                  value == 'activate') {
                                _alterarStatusCliente(cliente);
                              } else if (value == 'delete') {
                                _deletarCliente(cliente);
                              }
                            },
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
