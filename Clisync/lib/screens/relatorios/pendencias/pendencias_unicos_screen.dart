import 'package:flutter/material.dart';
import 'package:clisync/models/cliente_unico.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/utils/string_utils.dart';
import 'package:intl/intl.dart';

class PendenciasUnicosScreen extends StatefulWidget {
  final String? mesAno; // Se fornecido, filtra apenas este mês
  
  const PendenciasUnicosScreen({super.key, this.mesAno});

  @override
  State<PendenciasUnicosScreen> createState() => _PendenciasUnicosScreenState();
}

class _PendenciasUnicosScreenState extends State<PendenciasUnicosScreen> {
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  final _buscaController = TextEditingController();
  List<Map<String, dynamic>> _pendenciasPorMes = [];
  List<Map<String, dynamic>> _pendenciasFiltradas = [];
  bool _isLoading = true;
  String _termoBusca = '';

  @override
  void initState() {
    super.initState();
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
        _pendenciasFiltradas = List.from(_pendenciasPorMes);
      } else {
        final termoNormalizado = normalizarParaBusca(termo);
        _pendenciasFiltradas = _pendenciasPorMes.map((mes) {
          final servicos = (mes['servicos'] as List<Map<String, dynamic>>).where((item) {
            final cliente = item['cliente'] as ClienteUnico;
            final nomeNormalizado = normalizarParaBusca(cliente.nome);
            final ruaNormalizada = normalizarParaBusca(cliente.rua);
            
            final nomeMatch = nomeNormalizado.contains(termoNormalizado);
            final ruaMatch = ruaNormalizada.contains(termoNormalizado);
            return nomeMatch || ruaMatch;
          }).toList();
          
          if (servicos.isEmpty) {
            return null;
          }
          
          return {
            'mesAno': mes['mesAno'],
            'servicos': servicos,
          };
        }).where((mes) => mes != null).cast<Map<String, dynamic>>().toList();
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
        final pendencias = await _databaseService.getClientesUnicosInadimplentes(
          user.uid,
          mesAnoFiltro: widget.mesAno,
        );
        
        setState(() {
          _pendenciasPorMes = pendencias;
          _pendenciasFiltradas = List.from(pendencias);
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

  Future<void> _mostrarDialogoConfirmacaoServico(ClienteUnico cliente, String dataServico, String mesAno) async {
    // Formata a data do serviço
    final partesData = dataServico.split('-');
    final dia = partesData[0];
    final mesNum = partesData[1];
    final dataFormatada = '$dia/$mesNum';
    
    // Busca o horário
    final infoServico = cliente.historicoServicos[dataServico];
    final horario = infoServico?['horario']?.toString() ?? '--:--';
    
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Pagamento'),
          content: Text(
            'Deseja realmente marcar o pagamento de ${cliente.nome} do serviço de $dataFormatada às $horario como pago?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    
    if (confirmado == true) {
      await _marcarServicoComoPago(cliente, dataServico);
    }
  }

  Future<void> _marcarServicoComoPago(ClienteUnico cliente, String dataServico) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _databaseService.updateStatusPagamentoServicoUnico(
          user.uid,
          cliente.id,
          dataServico,
          ClienteUnico.statusPago,
        );
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
    // Título dinâmico baseado se está filtrando por mês ou não
    String titulo = 'Pendências';
    if (widget.mesAno != null) {
      final partes = widget.mesAno!.split('-');
      final ano = int.parse(partes[0]);
      final mes = int.parse(partes[1]);
      final meses = [
        'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
        'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
      ];
      titulo = 'Pendências - ${meses[mes - 1]}';
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
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
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    _pendenciasPorMes.fold(0, (sum, mes) => sum + (mes['servicos'] as List).length).toString(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const Text(
                                    'Pendências',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(
                                      _pendenciasPorMes.fold(0.0, (sum, mes) {
                                        final servicos = mes['servicos'] as List<Map<String, dynamic>>;
                                        return sum + servicos.fold(0.0, (s, serv) => s + (serv['valor'] as double));
                                      })
                                    ),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Text(
                                    'Total',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
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
                
                // Lista de clientes inadimplentes agrupados por mês
                Expanded(
                  child: _pendenciasFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _termoBusca.isEmpty ? Icons.check_circle : Icons.search_off,
                                size: 64,
                                color: _termoBusca.isEmpty ? Colors.green : Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _termoBusca.isEmpty 
                                    ? (widget.mesAno != null 
                                        ? 'Nenhuma pendência neste mês!' 
                                        : 'Nenhuma pendência encontrada!')
                                    : 'Nenhum resultado encontrado',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                _termoBusca.isEmpty
                                    ? (widget.mesAno != null
                                        ? 'Todos os serviços deste mês estão pagos.'
                                        : 'Todos os clientes estão em dia.')
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
                          itemCount: _pendenciasFiltradas.length,
                          itemBuilder: (context, index) {
                            final mes = _pendenciasFiltradas[index];
                            final mesAno = mes['mesAno'] as String;
                            final servicos = mes['servicos'] as List<Map<String, dynamic>>;
                            
                            // Parse do mês/ano
                            final partes = mesAno.split('-');
                            final ano = int.parse(partes[0]);
                            final mesNumero = int.parse(partes[1]);
                            
                            // Nome do mês
                            final meses = [
                              'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
                              'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
                            ];
                            final nomeMes = meses[mesNumero - 1];
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabeçalho do mês (só mostra se não estiver filtrando por mês específico)
                                if (widget.mesAno == null) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      '$nomeMes - $ano',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Divider(
                                    color: Colors.white24,
                                    thickness: 1,
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                                ],
                                // Lista de serviços do mês
                                ...servicos.map((item) {
                                  final cliente = item['cliente'] as ClienteUnico;
                                  final dataFormatada = item['dataFormatada'] as String;
                                  final horario = item['horario'] as String;
                                  final valor = item['valor'] as double;
                                  final tipoServico = item['tipoServico'] as String;
                                  final dataServico = item['dataServico'] as String;
                                  
                                  // Formata nome com data e horário
                                  String horarioFormatado = horario.isNotEmpty ? horario : '--:--';
                                  final nomeCompleto = '${cliente.nome} - $dataFormatada - $horarioFormatado';
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: ListTile(
                                      title: Text(
                                        nomeCompleto,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '$tipoServico - R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(valor)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      trailing: ElevatedButton(
                                        onPressed: () => _mostrarDialogoConfirmacaoServico(cliente, dataServico, mesAno),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(70, 32),
                                        ),
                                        child: const Text(
                                          'Pago',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

