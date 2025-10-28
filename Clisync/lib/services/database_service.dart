import 'package:firebase_database/firebase_database.dart';
import 'package:clisync/models/cliente.dart';
import 'package:clisync/models/cliente_unico.dart';
import 'package:clisync/models/usuario.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Usuário
  Future<void> createUser(Usuario usuario) async {
    await _database.child('usuarios').child(usuario.uid).set(usuario.toMap());
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final snapshot = await _database.child('usuarios').child(uid).get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  // Clientes
  Future<String> createCliente(String uid, Cliente cliente) async {
    final clienteRef = _database.child('usuarios').child(uid).child('clientes').push();
    await clienteRef.set(cliente.toMap());
    return clienteRef.key!;
  }

  Future<void> updateCliente(String uid, String clienteId, Cliente cliente) async {
    await _database
        .child('usuarios')
        .child(uid)
        .child('clientes')
        .child(clienteId)
        .update(cliente.toMap());
  }

  Future<void> deleteCliente(String uid, String clienteId) async {
    await _database
        .child('usuarios')
        .child(uid)
        .child('clientes')
        .child(clienteId)
        .remove();
  }

  Future<List<Cliente>> getClientes(String uid) async {
    final snapshot = await _database.child('usuarios').child(uid).child('clientes').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> clientesMap = Map<dynamic, dynamic>.from(snapshot.value as Map);
      return clientesMap.entries
          .map((entry) => Cliente.fromMap(entry.key, Map<String, dynamic>.from(entry.value)))
          .toList();
    }
    return [];
  }

  // Busca clientes recorrentes por nome
  Future<List<Cliente>> buscarClientesPorNome(String uid, String nome) async {
    if (nome.isEmpty) return [];
    
    final todosClientes = await getClientes(uid);
    
    // Normaliza o nome para busca (remove acentos, converte para lowercase)
    final nomeNormalizado = _normalizarParaBusca(nome);
    
    return todosClientes.where((cliente) {
      final nomeClienteNormalizado = _normalizarParaBusca(cliente.nome);
      return nomeClienteNormalizado.contains(nomeNormalizado);
    }).toList();
  }

  // Verifica se já existe um cliente recorrente com o mesmo nome
  Future<bool> existeClientePorNome(String uid, String nome, {String? excluirId}) async {
    final todosClientes = await getClientes(uid);
    final nomeNormalizado = _normalizarParaBusca(nome);
    
    return todosClientes.any((cliente) {
      final nomeClienteNormalizado = _normalizarParaBusca(cliente.nome);
      final nomesIguais = nomeClienteNormalizado == nomeNormalizado;
      final diferenteId = excluirId == null || cliente.id != excluirId;
      return nomesIguais && diferenteId;
    });
  }

  Stream<List<Cliente>> getClientesStream(String uid) {
    return _database
        .child('usuarios')
        .child(uid)
        .child('clientes')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> clientesMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        return clientesMap.entries
            .map((entry) => Cliente.fromMap(entry.key, Map<String, dynamic>.from(entry.value)))
            .toList();
      }
      return <Cliente>[];
    });
  }

  // Pagamentos
  Future<void> updateStatusPagamento(String uid, String clienteId, String mesAno, bool pago) async {
    await _database
        .child('usuarios')
        .child(uid)
        .child('clientes')
        .child(clienteId)
        .child('statusPagamento')
        .child(mesAno)
        .set(pago);
  }

  // Marcar pagamentos futuros (múltiplos meses)
  Future<void> marcarPagamentosFuturos(String uid, String clienteId, String mesAnoInicial, int quantidadeMeses) async {
    final updates = <String, bool>{};
    
    for (int i = 0; i < quantidadeMeses; i++) {
      final data = DateTime.parse('$mesAnoInicial-01');
      final mesFuturo = DateTime(data.year, data.month + i, 1);
      final mesAnoFuturo = DateFormat('yyyy-MM').format(mesFuturo);
      updates[mesAnoFuturo] = true;
    }
    
    // Atualiza todos os meses de uma vez
    await _database
        .child('usuarios')
        .child(uid)
        .child('clientes')
        .child(clienteId)
        .child('statusPagamento')
        .update(updates);
  }

  // Relatórios
  Future<Map<String, dynamic>> getRelatorioMes(String uid, String mesAno) async {
    final clientes = await getClientes(uid);
    
    // Clientes que existiam no final do mês (todos os clientes cadastrados até o final do mês)
    final clientesExistentesNoMes = clientes.where((c) => c.dataCadastro.isBefore(_getFimDoMes(mesAno))).toList();
    
    // Clientes ativos no mês (existentes e com status ativo)
    final clientesAtivosNoMes = clientesExistentesNoMes.where((c) => c.isAtivo).toList();
    int totalClientesAtivos = clientesAtivosNoMes.length;
    
    // Novos clientes cadastrados no mês específico (apenas ativos)
    final novosClientes = clientesAtivosNoMes.where((c) => c.foiCadastradoNoMes(mesAno)).toList();
    int quantidadeNovosClientes = novosClientes.length;
    
    // Clientes desativados (simplificado - mostra total de desativados)
    int clientesQueSairam = clientes.where((c) => c.isDesativado).length;
    
    // Clientes adimplentes e inadimplentes no mês (apenas ativos)
    int clientesAdimplentes = clientesAtivosNoMes.where((c) => c.isAdimplente(mesAno)).length;
    int clientesInadimplentes = totalClientesAtivos - clientesAdimplentes;
    
    // Cálculos financeiros baseados apenas nos clientes ativos no mês
    double valorTotal = clientesAtivosNoMes.fold(0.0, (sum, c) => sum + c.valor);
    double valorRecebido = clientesAtivosNoMes
        .where((c) => c.isAdimplente(mesAno))
        .fold(0.0, (sum, c) => sum + c.valor);
    double valorPendente = valorTotal - valorRecebido;

    return {
      'totalClientesAtivos': totalClientesAtivos,
      'novosClientes': quantidadeNovosClientes,
      'clientesQueSairam': clientesQueSairam,
      'clientesAdimplentes': clientesAdimplentes,
      'clientesInadimplentes': clientesInadimplentes,
      'valorTotal': valorTotal,
      'valorRecebido': valorRecebido,
      'valorPendente': valorPendente,
    };
  }
  
  // Método auxiliar para obter o final do mês
  DateTime _getFimDoMes(String mesAno) {
    final partes = mesAno.split('-');
    final ano = int.parse(partes[0]);
    final mes = int.parse(partes[1]);
    return DateTime(ano, mes + 1, 0, 23, 59, 59);
  }

  // Método para gerenciar virada de mês
  Future<void> processarViradaMes(String uid) async {
    try {
      final clientes = await getClientes(uid);
      final mesAtual = DateFormat('yyyy-MM').format(DateTime.now());
      
      for (final cliente in clientes) {
        if (cliente.isAtivo) {
          // Verifica se o cliente já tem status de pagamento para o mês atual
          if (!cliente.statusPagamento.containsKey(mesAtual)) {
            // Se não tem, define como inadimplente (false) para o mês atual
            await updateStatusPagamento(uid, cliente.id, mesAtual, false);
          }
        }
      }
    } catch (e) {
      // Erro ao processar virada de mês: $e
    }
  }

  Future<List<Cliente>> getClientesInadimplentes(String uid, String mesAno) async {
    final clientes = await getClientes(uid);
    return clientes.where((c) => !c.isAdimplente(mesAno)).toList();
  }

  // Clientes Únicos
  Future<String> createClienteUnico(String uid, ClienteUnico clienteUnico) async {
    // Busca cliente existente com o mesmo nome (normalizado)
    final clientesUnicos = await getClientesUnicos(uid);
    final nomeNormalizado = _normalizarParaBusca(clienteUnico.nome);
    
    // Procura se já existe um cliente com o mesmo nome
    ClienteUnico? clienteExistente;
    String? clienteIdExistente;
    
    for (final cliente in clientesUnicos) {
      final nomeClienteNormalizado = _normalizarParaBusca(cliente.nome);
      if (nomeClienteNormalizado == nomeNormalizado) {
        clienteExistente = cliente;
        clienteIdExistente = cliente.id;
        break;
      }
    }
    
    if (clienteExistente != null && clienteIdExistente != null) {
      // Se o cliente já existe, preserva o histórico existente e adiciona o novo serviço
      final historicoExistente = clienteExistente.historicoServicos;
      
      // Combina o histórico existente com o novo histórico
      final historicoCompleto = Map<String, Map<String, dynamic>>.from(historicoExistente);
      historicoCompleto.addAll(clienteUnico.historicoServicos);
      
      // Cria um novo cliente com o histórico completo
      final clienteComHistorico = clienteUnico.copyWith(
        historicoServicos: historicoCompleto,
      );
      
      await updateClienteUnico(uid, clienteIdExistente, clienteComHistorico);
      return clienteIdExistente;
    } else {
      // Cria novo cliente
      final clienteRef = _database.child('usuarios').child(uid).child('clientes_unicos').push();
      await clienteRef.set(clienteUnico.toMap());
      return clienteRef.key!;
    }
  }

  Future<void> updateClienteUnico(String uid, String clienteId, ClienteUnico clienteUnico) async {
    await _database
        .child('usuarios')
        .child(uid)
        .child('clientes_unicos')
        .child(clienteId)
        .update(clienteUnico.toMap());
  }

  Future<void> deleteClienteUnico(String uid, String clienteId) async {
    await _database
        .child('usuarios')
        .child(uid)
        .child('clientes_unicos')
        .child(clienteId)
        .remove();
  }

  Future<List<ClienteUnico>> getClientesUnicos(String uid) async {
    final snapshot = await _database.child('usuarios').child(uid).child('clientes_unicos').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> clientesMap = Map<dynamic, dynamic>.from(snapshot.value as Map);
      return clientesMap.entries
          .map((entry) => ClienteUnico.fromMap(entry.key, Map<String, dynamic>.from(entry.value)))
          .toList();
    }
    return [];
  }

  Stream<List<ClienteUnico>> getClientesUnicosStream(String uid) {
    return _database
        .child('usuarios')
        .child(uid)
        .child('clientes_unicos')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> clientesMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        return clientesMap.entries
            .map((entry) => ClienteUnico.fromMap(entry.key, Map<String, dynamic>.from(entry.value)))
            .toList();
      }
      return <ClienteUnico>[];
    });
  }

  // Busca clientes únicos por nome
  Future<List<ClienteUnico>> buscarClientesUnicosPorNome(String uid, String nome) async {
    if (nome.isEmpty) return [];
    
    final todosClientes = await getClientesUnicos(uid);
    
    // Normaliza o nome para busca (remove acentos, converte para lowercase)
    final nomeNormalizado = _normalizarParaBusca(nome);
    
    return todosClientes.where((cliente) {
      final nomeClienteNormalizado = _normalizarParaBusca(cliente.nome);
      return nomeClienteNormalizado.contains(nomeNormalizado);
    }).toList();
  }

  // Verifica se já existe um cliente único com o mesmo nome
  Future<bool> existeClienteUnicoPorNome(String uid, String nome, {String? excluirId}) async {
    final todosClientes = await getClientesUnicos(uid);
    final nomeNormalizado = _normalizarParaBusca(nome);
    
    return todosClientes.any((cliente) {
      final nomeClienteNormalizado = _normalizarParaBusca(cliente.nome);
      final nomesIguais = nomeClienteNormalizado == nomeNormalizado;
      final diferenteId = excluirId == null || cliente.id != excluirId;
      return nomesIguais && diferenteId;
    });
  }

  // Método para normalizar strings para busca (remove acentos e converte para lowercase)
  String _normalizarParaBusca(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n');
  }

  /// Busca relatório mensal de clientes únicos
  /// Retorna: novos clientes, total de serviços prestados, valor total
  Future<Map<String, dynamic>> getRelatorioMesUnicos(String uid, String mesAno) async {
    final clientesUnicos = await getClientesUnicos(uid);
    
    // Parse do mês/ano (formato: "2025-10")
    final partes = mesAno.split('-');
    final ano = int.parse(partes[0]);
    final mes = int.parse(partes[1]);
    
    int novosClientes = 0;
    int totalServicos = 0;
    double valorTotal = 0.0;
    
    // Percorre todos os clientes
    for (final cliente in clientesUnicos) {
      // Verifica se o cliente foi cadastrado neste mês (pela data do primeiro serviço)
      if (cliente.dataCadastro.year == ano && cliente.dataCadastro.month == mes) {
        novosClientes++;
      }
      
      // Verifica os serviços prestados no mês (do histórico)
      if (cliente.historicoServicos.isNotEmpty) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataServico = entry.key; // Formato: "29-10-2025"
          final infoServico = entry.value; // Map com valor e horario
          final valorServico = infoServico['valor'] as double? ?? 0.0;
          
          try {
            // Tenta parsear a data no formato "dd-MM-yyyy"
            final partesData = dataServico.split('-');
            if (partesData.length == 3) {
              final mesServico = int.parse(partesData[1]);
              final anoServico = int.parse(partesData[2]);
              
              // Verifica se o serviço foi prestado no mês especificado
              if (anoServico == ano && mesServico == mes) {
                totalServicos++;
                valorTotal += valorServico;
              }
            }
          } catch (e) {
            // Ignora erros de parse
          }
        }
      }
    }
    
    return {
      'novosClientes': novosClientes,
      'totalServicos': totalServicos,
      'valorTotal': valorTotal,
    };
  }

  /// Busca os próximos serviços agendados de todos os clientes únicos
  Future<List<Map<String, dynamic>>> getProximosServicosAgendados(String uid, {int limite = 4}) async {
    final clientesUnicos = await getClientesUnicos(uid);
    final agora = DateTime.now();
    final proximosServicos = <Map<String, dynamic>>[];
    
    // Percorre todos os clientes
    for (final cliente in clientesUnicos) {
      if (cliente.historicoServicos.isNotEmpty) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataServico = entry.key; // Formato: "29-10-2025"
          final infoServico = entry.value; // Map com valor e horario
          
          try {
            // Tenta parsear a data no formato "dd-MM-yyyy"
            final partesData = dataServico.split('-');
            if (partesData.length == 3) {
              final dia = int.parse(partesData[0]);
              final mes = int.parse(partesData[1]);
              final ano = int.parse(partesData[2]);
              final dataServicoDateTime = DateTime(ano, mes, dia);
              
              // Verifica se o serviço é futuro
              if (dataServicoDateTime.isAfter(agora)) {
                proximosServicos.add({
                  'nomeCliente': cliente.nome,
                  'data': dataServico.replaceAll('-', '/'), // Formato: "29/10/2025"
                  'horario': infoServico['horario']?.toString() ?? '',
                  'dataServico': dataServicoDateTime,
                });
              }
            }
          } catch (e) {
            // Ignora erros de parse
          }
        }
      }
    }
    
    // Ordena por data (mais próximo primeiro)
    proximosServicos.sort((a, b) {
      final dataA = a['dataServico'] as DateTime;
      final dataB = b['dataServico'] as DateTime;
      return dataA.compareTo(dataB);
    });
    
    // Retorna apenas os primeiros 4
    return proximosServicos.take(limite).toList();
  }
}
