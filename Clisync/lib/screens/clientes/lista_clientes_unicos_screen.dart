import 'package:flutter/material.dart';
import 'package:clisync/models/cliente_unico.dart';
import 'package:clisync/screens/clientes/cadastro_cliente_unico_screen.dart';
import 'package:clisync/screens/clientes/detalhes_cliente_unico_screen.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/utils/string_utils.dart';
import 'package:intl/intl.dart';

class ListaClientesUnicosScreen extends StatefulWidget {
  const ListaClientesUnicosScreen({super.key});

  @override
  State<ListaClientesUnicosScreen> createState() => _ListaClientesUnicosScreenState();
}

class _ListaClientesUnicosScreenState extends State<ListaClientesUnicosScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<ClienteUnico> _clientes = [];
  List<ClienteUnico> _clientesFiltrados = [];
  List<ClienteUnico> _clientesExibidos = [];
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _ordenacao = 'a-z'; // a-z, z-a, maior-valor, menor-valor
  
  // Controle de paginação
  static const int _itensPorPagina = 20;
  int _paginaAtual = 0;

  @override
  void initState() {
    super.initState();
    _carregarClientes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getUltimoValorServico(ClienteUnico cliente) {
    // Pega o último valor do histórico de serviços
    if (cliente.historicoServicos.isNotEmpty) {
      final ultimaInfoServico = cliente.historicoServicos.values.last;
      final ultimoValor = ultimaInfoServico['valor'] as double? ?? 0.0;
      return 'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(ultimoValor)}';
    }
    // Se não tiver histórico, retorna valor padrão 0
    return 'R\$ 0,00';
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _carregarMaisItens();
    }
  }

  void _carregarMaisItens() {
    if (_isLoadingMore || _clientesExibidos.length >= _clientesFiltrados.length) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    // Simula delay de rede
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _paginaAtual++;
          final inicio = _paginaAtual * _itensPorPagina;
          final fim = (inicio + _itensPorPagina).clamp(0, _clientesFiltrados.length);
          _clientesExibidos.addAll(_clientesFiltrados.sublist(inicio, fim));
          _isLoadingMore = false;
        });
      }
    });
  }

  void _resetarPaginacao() {
    setState(() {
      _paginaAtual = 0;
      final fim = _itensPorPagina.clamp(0, _clientesFiltrados.length);
      _clientesExibidos = _clientesFiltrados.take(fim).toList();
    });
  }

  Future<void> _carregarClientes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final clientes = await _databaseService.getClientesUnicos(user.uid);
        setState(() {
          _clientes = clientes;
          _clientesFiltrados = List.from(clientes);
          _isLoading = false;
          // Aplica ordenação padrão A-Z
          _ordenarClientes();
          // Inicializa paginação
          _resetarPaginacao();
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
    final query = _searchController.text;
    final queryNormalizada = normalizarParaBusca(query);
    
    setState(() {
      _clientesFiltrados = _clientes.where((cliente) {
        // Filtro por busca de endereço (ignorando acentos)
        bool buscaMatch = query.isEmpty ||
            normalizarParaBusca(cliente.nome).contains(queryNormalizada) ||
            normalizarParaBusca(cliente.enderecoCompleto).contains(queryNormalizada) ||
            normalizarParaBusca(cliente.rua).contains(queryNormalizada) ||
            normalizarParaBusca(cliente.bairro).contains(queryNormalizada) ||
            normalizarParaBusca(cliente.cidade).contains(queryNormalizada);

        return buscaMatch;
      }).toList();
      
      // Aplicar ordenação
      _ordenarClientes();
      
      // Resetar paginação após filtrar
      _resetarPaginacao();
    });
  }
  
  void _ordenarClientes() {
    switch (_ordenacao) {
      case 'a-z':
        _clientesFiltrados.sort((a, b) => 
            normalizarParaBusca(a.nome).compareTo(normalizarParaBusca(b.nome)));
        break;
      case 'z-a':
        _clientesFiltrados.sort((a, b) => 
            normalizarParaBusca(b.nome).compareTo(normalizarParaBusca(a.nome)));
        break;
      case 'maior-valor':
        _clientesFiltrados.sort((a, b) => b.valor.compareTo(a.valor));
        break;
      case 'menor-valor':
        _clientesFiltrados.sort((a, b) => a.valor.compareTo(b.valor));
        break;
    }
  }

  Future<void> _deletarCliente(ClienteUnico cliente) async {
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
          await _databaseService.deleteClienteUnico(user.uid, cliente.id);
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
        title: const Text('Clientes Únicos'),
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
                // Filtro de ordenação
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _ordenacao,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Ordenar',
                          prefixIcon: Icon(Icons.sort, color: Colors.white70),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'a-z',
                            child: Text('A-Z', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'z-a',
                            child: Text('Z-A', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'maior-valor',
                            child: Text('Maior Valor', overflow: TextOverflow.ellipsis),
                          ),
                          DropdownMenuItem<String>(
                            value: 'menor-valor',
                            child: Text('Menor Valor', overflow: TextOverflow.ellipsis),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _ordenacao = newValue;
                            });
                            _filtrarClientes();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Campo de busca por endereço
                TextField(
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
                      'Nenhum cliente cadastrado, cadastre um cliente para ver a lista',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _clientesExibidos.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Indicador de loading no final
                      if (index == _clientesExibidos.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final cliente = _clientesExibidos[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetalhesClienteUnicoScreen(
                                  clienteUnico: cliente,
                                ),
                              ),
                            ).then((_) {
                              // Recarrega a lista quando volta dos detalhes
                              _carregarClientes();
                            });
                          },
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
                              Row(
                                children: [
                                  const SizedBox(height: 10),
                                  Text(
                                    _getUltimoValorServico(cliente),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (cliente.tipoServico != null)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        cliente.tipoServico!,
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
                                        CadastroClienteUnicoScreen(clienteUnico: cliente),
                                  ),
                                ).then((_) {
                                  // Recarrega a lista quando volta da edição
                                  _carregarClientes();
                                });
                              } else if (value == 'delete') {
                                _deletarCliente(cliente);
                              }
                            },
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

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

