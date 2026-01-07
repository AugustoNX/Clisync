import 'package:flutter/material.dart';
import 'package:clisync/models/cliente.dart';
import 'package:clisync/models/plano.dart';
import 'package:clisync/screens/clientes/cadastro/cadastro_cliente_screen.dart';
import 'package:clisync/screens/clientes/detalhes/detalhes_cliente_screen.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/utils/string_utils.dart';
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
  final _scrollController = ScrollController();
  
  List<Cliente> _clientes = [];
  List<Cliente> _clientesFiltrados = [];
  List<Cliente> _clientesExibidos = [];
  Map<String, Plano> _planosMap = {}; // Cache de planos (id -> plano)
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _ordenacao = 'a-z'; // a-z, z-a, maior-valor, menor-valor
  String? _planoFiltro; // null = todos os planos
  
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

    // Simula delay de rede (pode remover se preferir)
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
        // Processa virada de mês automaticamente
        await _databaseService.processarViradaMes(user.uid);
        
        final clientes = await _databaseService.getClientes(user.uid);
        
        // Carrega todos os planos e cria um mapa de planos
        final planos = await _databaseService.getPlanos(user.uid);
        final planosMap = <String, Plano>{};
        for (final plano in planos) {
          if (plano.id != null) {
            planosMap[plano.id!] = plano;
          }
        }
        
        setState(() {
          _clientes = clientes;
          _clientesFiltrados = List.from(clientes);
          _planosMap = planosMap;
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

        // Filtro por plano
        bool planoMatch = _planoFiltro == null || cliente.planoId == _planoFiltro;

        return buscaMatch && planoMatch;
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
            child: const Text('Cancelar', style: TextStyle(color:Colors.white),),
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

  String _obterNomeComPlano(Cliente cliente) {
    if (cliente.planoNome != null && cliente.planoNome!.isNotEmpty) {
      if (cliente.planoId == null) {
        return cliente.nome;
      }
      
      final plano = _planosMap[cliente.planoId];
      
      if (plano == null) {
        // Plano não existe (foi excluído)
        return '${cliente.nome} - *';
      } else if (plano.status == 'desativado') {
        // Plano existe mas está desativado
        return '${cliente.nome} - ${cliente.planoNome!} #';
      } else {
        // Plano existe e está ativo
        return '${cliente.nome} - ${cliente.planoNome!}';
      }
    }
    return cliente.nome;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de clientes dos planos'),
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
                // Filtros: Ordenação e Plano em uma linha
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _planoFiltro,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por Plano',
                          prefixIcon: Icon(Icons.card_giftcard, color: Colors.white70),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todos os planos', overflow: TextOverflow.ellipsis),
                          ),
                          // Adiciona todos os planos (ativos e desativados)
                          ..._planosMap.values.map((plano) {
                            final nomePlano = plano.status == 'desativado' 
                                ? '${plano.nome} (desativado)'
                                : plano.nome;
                            return DropdownMenuItem<String>(
                              value: plano.id,
                              child: Text(
                                nomePlano,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _planoFiltro = newValue;
                          });
                          _filtrarClientes();
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
                    labelText: 'Buscar...',
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
                : RefreshIndicator(
                    onRefresh: _carregarClientes,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
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
                        final mesAtual = DateFormat(
                          'yyyy-MM',
                        ).format(DateTime.now());
                        final isAdimplente = cliente.isAdimplente(mesAtual);

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
                                builder: (context) => DetalhesClienteScreen(cliente: cliente),
                              ),
                            ).then((_) {
                              // Recarrega a lista quando volta dos detalhes
                              _carregarClientes();
                            });
                          },
                          child: ListTile(
                          title: Text(
                            _obterNomeComPlano(cliente),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (cliente.enderecoCompleto.trim().isNotEmpty) ...[
                                Text(
                                  cliente.enderecoCompleto,
                                  style: const TextStyle(color: Colors.white70),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 4),
                              ],
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
                              const SizedBox(height: 8),
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
                      ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
