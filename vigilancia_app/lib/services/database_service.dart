import 'package:firebase_database/firebase_database.dart';
import 'package:vigilancia_app/models/cliente.dart';
import 'package:vigilancia_app/models/usuario.dart';
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
      print('Erro ao processar virada de mês: $e');
    }
  }

  Future<List<Cliente>> getClientesInadimplentes(String uid, String mesAno) async {
    final clientes = await getClientes(uid);
    return clientes.where((c) => !c.isAdimplente(mesAno)).toList();
  }
}
