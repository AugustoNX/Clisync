import 'package:firebase_database/firebase_database.dart';
import 'package:clisync/models/cliente.dart';
import 'package:clisync/models/cliente_unico.dart';
import 'package:clisync/models/usuario.dart';
import 'package:clisync/models/plano.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Usuário
  Future<void> createUser(Usuario usuario) async {
    await _database.child('usuarios').child(usuario.uid).set(usuario.toMap());
  }

  Future<void> updateUser(Usuario usuario) async {
    await _database.child('usuarios').child(usuario.uid).update(usuario.toMap());
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

  /// Obtém a chave do período atual para um cliente baseado no plano
  Future<String> obterChavePeriodoAtual(String uid, Cliente cliente, {DateTime? dataReferencia}) async {
    dataReferencia ??= DateTime.now();
    
    if (cliente.planoId != null) {
      final plano = await getPlanoPorId(uid, cliente.planoId!);
      if (plano != null) {
        return _calcularChavePeriodo(plano.frequencia, cliente.dataCadastro, dataReferencia);
      }
    }
    
    // Se não tem plano, usa formato mensal
    return DateFormat('yyyy-MM').format(dataReferencia);
  }

  /// Marca o pagamento do período atual como pago
  Future<void> marcarPeriodoAtualComoPago(String uid, String clienteId, Cliente cliente, {DateTime? dataReferencia}) async {
    final chavePeriodo = await obterChavePeriodoAtual(uid, cliente, dataReferencia: dataReferencia);
    await updateStatusPagamento(uid, clienteId, chavePeriodo, true);
  }

  /// Marca o pagamento de um mês específico como pago, considerando a frequência do plano
  Future<void> marcarPeriodoMesComoPago(String uid, String clienteId, Cliente cliente, String mesAno) async {
    final planos = await getPlanos(uid);
    final planosMap = {for (var p in planos) p.id!: p};
    
    // Se o cliente tem um plano, marca todas as chaves de período daquele mês
    if (cliente.planoId != null && planosMap.containsKey(cliente.planoId)) {
      final plano = planosMap[cliente.planoId]!;
      final chavesPeriodo = await _calcularChavesPeriodoDoMes(plano.frequencia, cliente.dataCadastro, mesAno);
      
      // Marca todas as chaves de período daquele mês como pagas
      final updates = <String, bool>{};
      for (final chave in chavesPeriodo) {
        updates[chave] = true;
      }
      
      if (updates.isNotEmpty) {
        await _database
            .child('usuarios')
            .child(uid)
            .child('clientes')
            .child(clienteId)
            .child('statusPagamento')
            .update(updates);
      }
    } else {
      // Se não tem plano, usa lógica mensal (compatibilidade)
      await updateStatusPagamento(uid, clienteId, mesAno, true);
    }
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

  // Planos
  Future<List<Plano>> getPlanos(String uid) async {
    final snapshot = await _database.child('usuarios').child(uid).child('planos').get();
    if (snapshot.exists) {
      final Map<dynamic, dynamic> planosMap = Map<dynamic, dynamic>.from(snapshot.value as Map);
      return planosMap.entries
          .map((entry) => Plano.fromMap(entry.key as String, Map<String, dynamic>.from(entry.value)))
          .toList();
    }
    return [];
  }

  Future<Plano?> getPlanoPorId(String uid, String planId) async {
    final planos = await getPlanos(uid);
    try {
      return planos.firstWhere((p) => p.id == planId);
    } catch (e) {
      return null;
    }
  }

  // Métodos auxiliares para calcular períodos baseados na frequência
  /// Calcula a chave do período atual baseado na frequência do plano e data de cadastro
  String _calcularChavePeriodo(String frequencia, DateTime dataCadastro, DateTime dataReferencia) {
    switch (frequencia.toLowerCase()) {
      case 'semanal':
        // Usa formato yyyy-WW (ano-semana)
        final diasDiferenca = dataReferencia.difference(dataCadastro).inDays;
        final semanaNumero = (diasDiferenca ~/ 7) + 1;
        final ano = dataReferencia.year;
        return '${ano}-W$semanaNumero';
      
      case 'quinzenal':
        // A cada 15 dias
        final diasDiferenca = dataReferencia.difference(dataCadastro).inDays;
        final quinzenaNumero = (diasDiferenca ~/ 15) + 1;
        final ano = dataReferencia.year;
        return '${ano}-Q$quinzenaNumero';
      
      case 'mensal':
        // Formato yyyy-MM (mantém compatibilidade)
        return DateFormat('yyyy-MM').format(dataReferencia);
      
      case 'trimestral':
        // A cada 3 meses
        final mesesDiferenca = (dataReferencia.year - dataCadastro.year) * 12 + 
                              (dataReferencia.month - dataCadastro.month);
        final trimestreNumero = (mesesDiferenca ~/ 3) + 1;
        final ano = dataReferencia.year;
        return '${ano}-T$trimestreNumero';
      
      case 'semestral':
        // A cada 6 meses
        final mesesDiferenca = (dataReferencia.year - dataCadastro.year) * 12 + 
                              (dataReferencia.month - dataCadastro.month);
        final semestreNumero = (mesesDiferenca ~/ 6) + 1;
        final ano = dataReferencia.year;
        return '${ano}-S$semestreNumero';
      
      case 'anual':
        // Uma vez por ano
        final ano = dataReferencia.year;
        return '$ano';
      
      default:
        // Default para mensal
        return DateFormat('yyyy-MM').format(dataReferencia);
    }
  }

  /// Verifica se o cliente está adimplente baseado na frequência do plano
  Future<bool> isClienteAdimplente(Cliente cliente, String uid, {DateTime? dataReferencia}) async {
    dataReferencia ??= DateTime.now();
    
    // Se o cliente tem um plano, usa a frequência do plano
    if (cliente.planoId != null) {
      final plano = await getPlanoPorId(uid, cliente.planoId!);
      if (plano != null) {
        final chavePeriodo = _calcularChavePeriodo(plano.frequencia, cliente.dataCadastro, dataReferencia);
        return cliente.statusPagamento[chavePeriodo] ?? false;
      }
    }
    
    // Se não tem plano ou plano não encontrado, usa lógica mensal (compatibilidade)
    final mesAno = DateFormat('yyyy-MM').format(dataReferencia);
    return cliente.statusPagamento[mesAno] ?? false;
  }

  List<Map<String, dynamic>> gerarPeriodosHistorico(String frequencia, DateTime dataCadastro, DateTime dataFinal) {
    final periodos = <Map<String, dynamic>>[];
    final hoje = DateTime.now();
    final dataReferencia = dataFinal.isAfter(hoje) ? hoje : dataFinal;
    
    switch (frequencia.toLowerCase()) {
      case 'semanal':
        // Gera semanas desde a data de cadastro
        var dataAtual = DateTime(dataCadastro.year, dataCadastro.month, dataCadastro.day);
        int sequencia = 1;
        
        while (dataAtual.isBefore(dataReferencia.add(const Duration(days: 7)))) {
          final diasDiferenca = dataAtual.difference(dataCadastro).inDays;
          if (diasDiferenca >= 0) {
            final semanaNumero = (diasDiferenca ~/ 7) + 1;
            final chave = '${dataAtual.year}-W$semanaNumero';
            final dataInicioPeriodo = dataCadastro.add(Duration(days: (semanaNumero - 1) * 7));
            final dataFimPeriodo = dataInicioPeriodo.add(const Duration(days: 6));
            
            periodos.add({
              'chave': chave,
              'sequencia': sequencia,
              'dataInicio': dataInicioPeriodo,
              'dataFim': dataFimPeriodo,
            });
            sequencia++;
          }
          dataAtual = dataAtual.add(const Duration(days: 7));
        }
        break;
      
      case 'quinzenal':
        var dataAtual = DateTime(dataCadastro.year, dataCadastro.month, dataCadastro.day);
        int sequencia = 1;
        
        while (dataAtual.isBefore(dataReferencia.add(const Duration(days: 15)))) {
          final diasDiferenca = dataAtual.difference(dataCadastro).inDays;
          if (diasDiferenca >= 0) {
            final quinzenaNumero = (diasDiferenca ~/ 15) + 1;
            final chave = '${dataAtual.year}-Q$quinzenaNumero';
            final dataInicioPeriodo = dataCadastro.add(Duration(days: (quinzenaNumero - 1) * 15));
            final dataFimPeriodo = dataInicioPeriodo.add(const Duration(days: 14));
            
            periodos.add({
              'chave': chave,
              'sequencia': sequencia,
              'dataInicio': dataInicioPeriodo,
              'dataFim': dataFimPeriodo,
            });
            sequencia++;
          }
          dataAtual = dataAtual.add(const Duration(days: 15));
        }
        break;
      
      case 'mensal':
        var mesAtual = DateTime(dataCadastro.year, dataCadastro.month, 1);
        int sequencia = 1;
        final mesFinal = DateTime(dataReferencia.year, dataReferencia.month, 1);
        
        while (mesAtual.isBefore(mesFinal) || mesAtual.isAtSameMomentAs(mesFinal)) {
          final chave = DateFormat('yyyy-MM').format(mesAtual);
          final dataInicioPeriodo = mesAtual;
          final dataFimPeriodo = DateTime(mesAtual.year, mesAtual.month + 1, 0);
          
          periodos.add({
            'chave': chave,
            'sequencia': sequencia,
            'dataInicio': dataInicioPeriodo,
            'dataFim': dataFimPeriodo,
          });
          sequencia++;
          mesAtual = DateTime(mesAtual.year, mesAtual.month + 1, 1);
        }
        break;
      
      case 'trimestral':
        var trimestreAtual = DateTime(dataCadastro.year, dataCadastro.month, 1);
        int sequencia = 1;
        
        while (trimestreAtual.isBefore(dataReferencia)) {
          final mesesDiferenca = (trimestreAtual.year - dataCadastro.year) * 12 + 
                                (trimestreAtual.month - dataCadastro.month);
          final trimestreNumero = (mesesDiferenca ~/ 3) + 1;
          final chave = '${trimestreAtual.year}-T$trimestreNumero';
          final dataInicioPeriodo = DateTime(
            dataCadastro.year, 
            dataCadastro.month + ((trimestreNumero - 1) * 3), 
            1
          );
          final dataFimPeriodo = DateTime(dataInicioPeriodo.year, dataInicioPeriodo.month + 3, 0);
          
          periodos.add({
            'chave': chave,
            'sequencia': sequencia,
            'dataInicio': dataInicioPeriodo,
            'dataFim': dataFimPeriodo,
          });
          sequencia++;
          trimestreAtual = DateTime(trimestreAtual.year, trimestreAtual.month + 3, 1);
        }
        break;
      
      case 'semestral':
        var semestreAtual = DateTime(dataCadastro.year, dataCadastro.month, 1);
        int sequencia = 1;
        
        while (semestreAtual.isBefore(dataReferencia)) {
          final mesesDiferenca = (semestreAtual.year - dataCadastro.year) * 12 + 
                                (semestreAtual.month - dataCadastro.month);
          final semestreNumero = (mesesDiferenca ~/ 6) + 1;
          final chave = '${semestreAtual.year}-S$semestreNumero';
          final dataInicioPeriodo = DateTime(
            dataCadastro.year, 
            dataCadastro.month + ((semestreNumero - 1) * 6), 
            1
          );
          final dataFimPeriodo = DateTime(dataInicioPeriodo.year, dataInicioPeriodo.month + 6, 0);
          
          periodos.add({
            'chave': chave,
            'sequencia': sequencia,
            'dataInicio': dataInicioPeriodo,
            'dataFim': dataFimPeriodo,
          });
          sequencia++;
          semestreAtual = DateTime(semestreAtual.year, semestreAtual.month + 6, 1);
        }
        break;
      
      case 'anual':
        var anoAtual = dataCadastro.year;
        int sequencia = 1;
        
        while (anoAtual <= dataReferencia.year) {
          final chave = '$anoAtual';
          final dataInicioPeriodo = DateTime(anoAtual, 1, 1);
          final dataFimPeriodo = DateTime(anoAtual, 12, 31);
          
          periodos.add({
            'chave': chave,
            'sequencia': sequencia,
            'dataInicio': dataInicioPeriodo,
            'dataFim': dataFimPeriodo,
          });
          sequencia++;
          anoAtual++;
        }
        break;
      
      default:
        // Default para mensal
        var mesAtual = DateTime(dataCadastro.year, dataCadastro.month, 1);
        int sequencia = 1;
        final mesFinal = DateTime(dataReferencia.year, dataReferencia.month, 1);
        
        while (mesAtual.isBefore(mesFinal) || mesAtual.isAtSameMomentAs(mesFinal)) {
          final chave = DateFormat('yyyy-MM').format(mesAtual);
          final dataInicioPeriodo = mesAtual;
          final dataFimPeriodo = DateTime(mesAtual.year, mesAtual.month + 1, 0);
          
          periodos.add({
            'chave': chave,
            'sequencia': sequencia,
            'dataInicio': dataInicioPeriodo,
            'dataFim': dataFimPeriodo,
          });
          sequencia++;
          mesAtual = DateTime(mesAtual.year, mesAtual.month + 1, 1);
        }
    }
    
    return periodos;
  }

  /// Calcula todas as chaves de período que devem ser verificadas para o mês atual
  /// (útil para a tela de pendências que mostra por mês)
  Future<List<String>> _calcularChavesPeriodoDoMes(String frequencia, DateTime dataCadastro, String mesAno) async {
    final partes = mesAno.split('-');
    final ano = int.parse(partes[0]);
    final mes = int.parse(partes[1]);
    final inicioMes = DateTime(ano, mes, 1);
    final fimMes = DateTime(ano, mes + 1, 0);
    
    final chaves = <String>[];
    
    switch (frequencia.toLowerCase()) {
      case 'semanal':
        // Calcula todas as semanas do mês
        var dataAtual = inicioMes;
        while (dataAtual.isBefore(fimMes.add(const Duration(days: 1)))) {
          final diasDiferenca = dataAtual.difference(dataCadastro).inDays;
          if (diasDiferenca >= 0) {
            final semanaNumero = (diasDiferenca ~/ 7) + 1;
            final chave = '${dataAtual.year}-W$semanaNumero';
            if (!chaves.contains(chave)) {
              chaves.add(chave);
            }
          }
          dataAtual = dataAtual.add(const Duration(days: 7));
        }
        break;
      
      case 'quinzenal':
        var dataAtual = inicioMes;
        while (dataAtual.isBefore(fimMes.add(const Duration(days: 1)))) {
          final diasDiferenca = dataAtual.difference(dataCadastro).inDays;
          if (diasDiferenca >= 0) {
            final quinzenaNumero = (diasDiferenca ~/ 15) + 1;
            final chave = '${dataAtual.year}-Q$quinzenaNumero';
            if (!chaves.contains(chave)) {
              chaves.add(chave);
            }
          }
          dataAtual = dataAtual.add(const Duration(days: 15));
        }
        break;
      
      case 'mensal':
        chaves.add(mesAno);
        break;
      
      case 'trimestral':
        final mesesDiferenca = (ano - dataCadastro.year) * 12 + (mes - dataCadastro.month);
        final trimestreNumero = (mesesDiferenca ~/ 3) + 1;
        chaves.add('$ano-T$trimestreNumero');
        break;
      
      case 'semestral':
        final mesesDiferenca = (ano - dataCadastro.year) * 12 + (mes - dataCadastro.month);
        final semestreNumero = (mesesDiferenca ~/ 6) + 1;
        chaves.add('$ano-S$semestreNumero');
        break;
      
      case 'anual':
        chaves.add('$ano');
        break;
      
      default:
        chaves.add(mesAno);
    }
    
    return chaves;
  }

  Future<List<Cliente>> getClientesInadimplentes(String uid, String mesAno) async {
    final clientes = await getClientes(uid);
    final planos = await getPlanos(uid);
    final planosMap = {for (var p in planos) p.id!: p};
    
    final clientesInadimplentes = <Cliente>[];
    
    for (final cliente in clientes) {
      if (!cliente.isAtivo) continue;
      
      bool estaAdimplente = false;
      
      // Se o cliente tem um plano, usa a frequência do plano
      if (cliente.planoId != null && planosMap.containsKey(cliente.planoId)) {
        final plano = planosMap[cliente.planoId]!;
        final chavesPeriodo = await _calcularChavesPeriodoDoMes(plano.frequencia, cliente.dataCadastro, mesAno);
        
        // Verifica se pelo menos uma das chaves do período está paga
        estaAdimplente = chavesPeriodo.any((chave) => cliente.statusPagamento[chave] == true);
      } else {
        // Se não tem plano, usa lógica mensal (compatibilidade)
        estaAdimplente = cliente.statusPagamento[mesAno] ?? false;
      }
      
      if (!estaAdimplente) {
        clientesInadimplentes.add(cliente);
      }
    }
    
    return clientesInadimplentes;
  }

  // Busca clientes recorrentes com pendências de pagamento agrupadas por mês
  Future<List<Map<String, dynamic>>> getClientesInadimplentesPorMes(String uid, {String? mesAnoFiltro}) async {
    final clientes = await getClientes(uid);
    final planos = await getPlanos(uid);
    final planosMap = {for (var p in planos) p.id!: p};
    final agora = DateTime.now();
    
    // Encontra a data do primeiro cliente (para começar a verificar desde lá)
    DateTime? primeiraData;
    for (final cliente in clientes) {
      if (cliente.isAtivo && (primeiraData == null || cliente.dataCadastro.isBefore(primeiraData))) {
        primeiraData = cliente.dataCadastro;
      }
    }
    
    if (primeiraData == null) {
      return [];
    }
    
    final pendenciasPorMes = <String, Map<String, dynamic>>{}; // Chave: "mes-ano", valor: {mesAno, clientes: []}
    
    // Itera por todos os meses desde o primeiro cliente até hoje
    var dataAtual = DateTime(primeiraData.year, primeiraData.month, 1);
    final dataFinal = DateTime(agora.year, agora.month, 1);
    
    while (dataAtual.isBefore(dataFinal) || dataAtual.isAtSameMomentAs(dataFinal)) {
      final mesAno = DateFormat('yyyy-MM').format(dataAtual);
      
      // Se há filtro por mês, pula meses diferentes
      if (mesAnoFiltro != null && mesAno != mesAnoFiltro) {
        dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
        continue;
      }
      
      final clientesInadimplentesNoMes = <Cliente>[];
      
      // Verifica quais clientes estão inadimplentes neste mês
      for (final cliente in clientes) {
        if (!cliente.isAtivo) continue;
        
        // Verifica se o cliente já existia neste mês
        if (cliente.dataCadastro.isAfter(DateTime(dataAtual.year, dataAtual.month + 1, 0))) {
          continue; // Cliente ainda não existia neste mês
        }
        
        bool estaAdimplente = false;
        
        // Se o cliente tem um plano, usa a frequência do plano
        if (cliente.planoId != null && planosMap.containsKey(cliente.planoId)) {
          final plano = planosMap[cliente.planoId]!;
          final chavesPeriodo = await _calcularChavesPeriodoDoMes(plano.frequencia, cliente.dataCadastro, mesAno);
          
          // Verifica se pelo menos uma das chaves do período está paga
          estaAdimplente = chavesPeriodo.any((chave) => cliente.statusPagamento[chave] == true);
        } else {
          // Se não tem plano, usa lógica mensal (compatibilidade)
          estaAdimplente = cliente.statusPagamento[mesAno] ?? false;
        }
        
        if (!estaAdimplente) {
          clientesInadimplentesNoMes.add(cliente);
        }
      }
      
      // Se há clientes inadimplentes neste mês, adiciona ao mapa
      if (clientesInadimplentesNoMes.isNotEmpty) {
        pendenciasPorMes[mesAno] = {
          'mesAno': mesAno,
          'clientes': clientesInadimplentesNoMes,
        };
      }
      
      // Avança para o próximo mês
      dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
    }
    
    // Se há filtro por mês, retorna apenas aquele mês
    if (mesAnoFiltro != null) {
      if (pendenciasPorMes.containsKey(mesAnoFiltro)) {
        return [pendenciasPorMes[mesAnoFiltro]!];
      } else {
        return [];
      }
    }
    
    // Converte para lista ordenada por mês (mais recente primeiro)
    final listaOrdenada = pendenciasPorMes.values.toList();
    listaOrdenada.sort((a, b) {
      final mesAnoA = a['mesAno'] as String;
      final mesAnoB = b['mesAno'] as String;
      return mesAnoB.compareTo(mesAnoA); // Ordem decrescente (mais recente primeiro)
    });
    
    return listaOrdenada;
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
    int totalCancelamentos = 0;
    double valorTotal = 0.0;
    double valorRecebido = 0.0;
    double valorPendente = 0.0;
    final Set<String> clientesNaoPagos = {}; // Usa Set para evitar duplicatas
    final Map<String, int> servicosPorTipo = {}; // Contador de serviços por tipo
    final Map<String, int> servicosPorDiaSemana = {}; // Contador de serviços por dia da semana
    final Map<String, int> servicosPorHorario = {}; // Contador de serviços por faixa de horário
    
    final agora = DateTime.now();
    
    // Nomes dos dias da semana
    final diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    
    // Função auxiliar para obter a primeira data do histórico de serviços
    DateTime? _obterPrimeiraDataServico(ClienteUnico cliente) {
      if (cliente.historicoServicos.isEmpty) {
        return null;
      }

      DateTime? primeiraData;
      
      for (final entry in cliente.historicoServicos.entries) {
        final dataKey = entry.key;
        final horario = entry.value['horario']?.toString();
        
        try {
          final partesData = dataKey.split('-');
          if (partesData.length == 3) {
            final dia = int.parse(partesData[0]);
            final mes = int.parse(partesData[1]);
            final anoData = int.parse(partesData[2]);

            int hora = 0;
            int minuto = 0;

            if (horario != null && horario.isNotEmpty) {
              final partesHorario = horario.split(':');
              if (partesHorario.length == 2) {
                hora = int.tryParse(partesHorario[0]) ?? 0;
                minuto = int.tryParse(partesHorario[1]) ?? 0;
              }
            }

            final dataHora = DateTime(anoData, mes, dia, hora, minuto);
            
            if (primeiraData == null || dataHora.isBefore(primeiraData)) {
              primeiraData = dataHora;
            }
          }
        } catch (_) {
          // Ignora erros de parsing
        }
      }
      
      return primeiraData;
    }

    // Percorre todos os clientes
    for (final cliente in clientesUnicos) {
      // Verifica se o cliente foi cadastrado neste mês (pela data do primeiro serviço)
      final primeiraData = _obterPrimeiraDataServico(cliente);
      if (primeiraData != null && primeiraData.year == ano && primeiraData.month == mes) {
        novosClientes++;
      }
      
      // Verifica os serviços prestados no mês (do histórico)
      if (cliente.historicoServicos.isNotEmpty) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataServico = entry.key; // Formato: "29-10-2025"
          final infoServico = entry.value; // Map com valor, horario e statusPagamento
          final valorServico = infoServico['valor'] as double? ?? 0.0;
          
          try {
            // Tenta parsear a data no formato "dd-MM-yyyy"
            final partesData = dataServico.split('-');
            if (partesData.length == 3) {
              final diaServico = int.parse(partesData[0]);
              final mesServico = int.parse(partesData[1]);
              final anoServico = int.parse(partesData[2]);
              
              // Verifica se o serviço foi prestado no mês especificado
              if (anoServico == ano && mesServico == mes) {
                // Tenta parsear a data completa com horário
                final horario = infoServico['horario']?.toString() ?? '';
                int hora = 0;
                int minuto = 0;
                
                if (horario.isNotEmpty) {
                  final partesHorario = horario.split(':');
                  if (partesHorario.length == 2) {
                    hora = int.tryParse(partesHorario[0]) ?? 0;
                    minuto = int.tryParse(partesHorario[1]) ?? 0;
                  }
                }
                
                final dataServicoCompleta = DateTime(anoServico, mesServico, diaServico, hora, minuto);
                
                // Verifica o status do pagamento
                final statusArmazenado = infoServico['statusPagamento']?.toString() ?? ClienteUnico.statusPago;
                
                // Conta cancelamentos separadamente (mesmo que não sejam incluídos no total de serviços)
                if (statusArmazenado == ClienteUnico.statusCancelado) {
                  totalCancelamentos++;
                  continue;
                }
                
                // Verifica se o serviço deve ser incluído no fechamento do mês:
                // - Status "pago" OU
                // - Status "agendado" mas a data já passou (pagamento pendente)
                // NÃO inclui: Status "agendado" com data futura
                bool deveIncluir = false;
                
                if (statusArmazenado == ClienteUnico.statusPago) {
                  // Serviço pago sempre inclui
                  deveIncluir = true;
                } else {
                  // Se não está pago, verifica se a data já passou
                  if (dataServicoCompleta.isBefore(agora) || dataServicoCompleta.isAtSameMomentAs(agora)) {
                    // Data já passou, então está pendente de pagamento - inclui
                    deveIncluir = true;
                  } else {
                    // Data ainda não passou, é um agendamento futuro - NÃO inclui
                    deveIncluir = false;
                  }
                }
                
                // Só processa se deve incluir no fechamento
                if (deveIncluir) {
                  totalServicos++;
                  valorTotal += valorServico;
                  
                  // Conta serviços por tipo
                  final tipoServico = infoServico['tipoServico']?.toString();
                  if (tipoServico != null && tipoServico.isNotEmpty) {
                    servicosPorTipo[tipoServico] = (servicosPorTipo[tipoServico] ?? 0) + 1;
                  } else {
                    // Se não tiver tipo, usa "Sem tipo" como padrão
                    servicosPorTipo['Sem tipo'] = (servicosPorTipo['Sem tipo'] ?? 0) + 1;
                  }
                  
                  // Conta serviços por dia da semana
                  // weekday retorna 1-7 (segunda=1, domingo=7), precisamos mapear para 0-6 (domingo=0)
                  final diaSemana = dataServicoCompleta.weekday == 7 ? 0 : dataServicoCompleta.weekday;
                  final nomeDiaSemana = diasSemana[diaSemana];
                  servicosPorDiaSemana[nomeDiaSemana] = (servicosPorDiaSemana[nomeDiaSemana] ?? 0) + 1;
                  
                  // Conta serviços por faixa de horário
                  String faixaHorario;
                  if (hora >= 6 && hora < 12) {
                    faixaHorario = 'Manhã\n(6h-12h)';
                  } else if (hora >= 12 && hora < 18) {
                    faixaHorario = 'Tarde\n(12h-18h)';
                  } else if (hora >= 18 && hora < 22) {
                    faixaHorario = 'Noite\n(18h-22h)';
                  } else {
                    faixaHorario = 'Madrugada\n(22h-6h)';
                  }
                  servicosPorHorario[faixaHorario] = (servicosPorHorario[faixaHorario] ?? 0) + 1;
                  
                  // Calcula valores recebidos e pendentes
                  if (statusArmazenado == ClienteUnico.statusPago) {
                    valorRecebido += valorServico;
                  } else {
                    // Se não está pago e a data já passou, está pendente
                    valorPendente += valorServico;
                    clientesNaoPagos.add(cliente.id);
                  }
                }
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
      'totalCancelamentos': totalCancelamentos,
      'valorTotal': valorTotal,
      'valorRecebido': valorRecebido,
      'valorPendente': valorPendente,
      'clientesNaoPagos': clientesNaoPagos.length,
      'servicosPorTipo': servicosPorTipo,
      'servicosPorDiaSemana': servicosPorDiaSemana,
      'servicosPorHorario': servicosPorHorario,
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
              
              // Verifica o status do serviço
              final statusArmazenado = infoServico['statusPagamento']?.toString() ?? ClienteUnico.statusPago;
              
              // Verifica se o serviço é futuro e não está cancelado
              if (dataServicoDateTime.isAfter(agora) && statusArmazenado != ClienteUnico.statusCancelado) {
                proximosServicos.add({
                  'nomeCliente': cliente.nome,
                  'telefone': cliente.telefone,
                  'data': dataServico.replaceAll('-', '/'), // Formato: "29/10/2025"
                  'horario': infoServico['horario']?.toString() ?? '',
                  'tipoServico': infoServico['tipoServico']?.toString(),
                  'dataServico': dataServicoDateTime,
                  'clienteId': cliente.id,
                  'clienteUnico': cliente,
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

  // Busca clientes únicos com pendências de pagamento agrupadas por mês
  Future<List<Map<String, dynamic>>> getClientesUnicosInadimplentes(String uid, {String? mesAnoFiltro}) async {
    final clientesUnicos = await getClientesUnicos(uid);
    final agora = DateTime.now();
    final pendenciasPorMes = <String, Map<String, dynamic>>{}; // Chave: "mes-ano", valor: {mesAno, clientes: []}
    
    for (final cliente in clientesUnicos) {
      if (cliente.historicoServicos.isNotEmpty) {
        // Agrupa pendências por mês
        final pendenciasDoCliente = <String, List<Map<String, dynamic>>>{}; // Chave: "mes-ano"
        
        for (final entry in cliente.historicoServicos.entries) {
          final dataServico = entry.key; // Formato: "29-10-2025"
          final infoServico = entry.value; // Map com valor, horario e statusPagamento
          
          try {
            // Tenta parsear a data no formato "dd-MM-yyyy"
            final partesData = dataServico.split('-');
            if (partesData.length == 3) {
              final diaServico = int.parse(partesData[0]);
              final mesServico = int.parse(partesData[1]);
              final anoServico = int.parse(partesData[2]);
              
              // Verifica se o serviço está pendente
              final statusArmazenado = infoServico['statusPagamento']?.toString() ?? ClienteUnico.statusPago;
              
              // Se o status não é "pago" e não é "cancelado", verifica se a data já passou
              if (statusArmazenado != ClienteUnico.statusPago && statusArmazenado != ClienteUnico.statusCancelado) {
                // Tenta parsear a data completa com horário
                final horario = infoServico['horario']?.toString() ?? '';
                int hora = 0;
                int minuto = 0;
                
                if (horario.isNotEmpty) {
                  final partesHorario = horario.split(':');
                  if (partesHorario.length == 2) {
                    hora = int.tryParse(partesHorario[0]) ?? 0;
                    minuto = int.tryParse(partesHorario[1]) ?? 0;
                  }
                }
                
                final dataServicoCompleta = DateTime(anoServico, mesServico, diaServico, hora, minuto);
                
                // Se a data do serviço já passou e o status não é "pago", então está aguardando pagamento
                if (dataServicoCompleta.isBefore(agora) || dataServicoCompleta.isAtSameMomentAs(agora)) {
                  final mesAno = '$anoServico-${mesServico.toString().padLeft(2, '0')}';
                  
                  if (!pendenciasDoCliente.containsKey(mesAno)) {
                    pendenciasDoCliente[mesAno] = [];
                  }
                  
                  pendenciasDoCliente[mesAno]!.add({
                    'dataServico': dataServico,
                    'valor': infoServico['valor'] as double? ?? 0.0,
                    'tipoServico': infoServico['tipoServico']?.toString(),
                  });
                }
              }
            }
          } catch (e) {
            // Ignora erros de parse
          }
        }
        
        // Adiciona cada serviço individualmente em cada mês que tem pendências
        for (final entry in pendenciasDoCliente.entries) {
          final mesAno = entry.key;
          final servicosPendentes = entry.value;
          
          if (!pendenciasPorMes.containsKey(mesAno)) {
            pendenciasPorMes[mesAno] = {
              'mesAno': mesAno,
              'servicos': <Map<String, dynamic>>[],
            };
          }
          
          // Adiciona cada serviço como um item separado
          for (final servico in servicosPendentes) {
            final dataServico = servico['dataServico'] as String;
            final partesData = dataServico.split('-');
            final diaServico = int.parse(partesData[0]);
            final mesServico = int.parse(partesData[1]);
            
            // Formata data para exibição (dd/MM)
            final dataFormatada = '${diaServico.toString().padLeft(2, '0')}/${mesServico.toString().padLeft(2, '0')}';
            
            // Busca o horário do serviço
            final infoServicoOriginal = cliente.historicoServicos[dataServico];
            final horario = infoServicoOriginal?['horario']?.toString() ?? '';
            
            pendenciasPorMes[mesAno]!['servicos'].add({
              'clienteId': cliente.id,
              'cliente': cliente,
              'dataServico': dataServico,
              'dataFormatada': dataFormatada,
              'horario': horario,
              'valor': servico['valor'] as double,
              'tipoServico': servico['tipoServico']?.toString() ?? 'Serviço',
            });
          }
        }
      }
    }
    
    // Ordena os serviços dentro de cada mês por data e horário (mais antigo primeiro)
    for (final mes in pendenciasPorMes.values) {
      final servicos = mes['servicos'] as List<Map<String, dynamic>>;
      servicos.sort((a, b) {
        final dataA = a['dataServico'] as String; // Formato: "29-10-2025"
        final dataB = b['dataServico'] as String;
        final horarioA = a['horario'] as String;
        final horarioB = b['horario'] as String;
        
        // Compara primeiro pela data
        final partesA = dataA.split('-');
        final partesB = dataB.split('-');
        
        if (partesA.length == 3 && partesB.length == 3) {
          final diaA = int.parse(partesA[0]);
          final mesA = int.parse(partesA[1]);
          final anoA = int.parse(partesA[2]);
          final diaB = int.parse(partesB[0]);
          final mesB = int.parse(partesB[1]);
          final anoB = int.parse(partesB[2]);
          
          // Compara ano
          if (anoA != anoB) {
            return anoA.compareTo(anoB);
          }
          
          // Compara mês
          if (mesA != mesB) {
            return mesA.compareTo(mesB);
          }
          
          // Compara dia
          if (diaA != diaB) {
            return diaA.compareTo(diaB);
          }
          
          // Se a data for igual, compara pelo horário
          if (horarioA.isNotEmpty && horarioB.isNotEmpty) {
            final partesHorarioA = horarioA.split(':');
            final partesHorarioB = horarioB.split(':');
            
            if (partesHorarioA.length == 2 && partesHorarioB.length == 2) {
              final horaA = int.tryParse(partesHorarioA[0]) ?? 0;
              final minutoA = int.tryParse(partesHorarioA[1]) ?? 0;
              final horaB = int.tryParse(partesHorarioB[0]) ?? 0;
              final minutoB = int.tryParse(partesHorarioB[1]) ?? 0;
              
              if (horaA != horaB) {
                return horaA.compareTo(horaB);
              }
              
              return minutoA.compareTo(minutoB);
            }
          }
          
          // Se não tiver horário, mantém a ordem
          return 0;
        }
        
        return dataA.compareTo(dataB);
      });
    }
    
    // Se há filtro por mês, retorna apenas aquele mês
    if (mesAnoFiltro != null) {
      if (pendenciasPorMes.containsKey(mesAnoFiltro)) {
        return [pendenciasPorMes[mesAnoFiltro]!];
      } else {
        // Se o mês não tem pendências, retorna lista vazia
        return [];
      }
    }
    
    // Converte para lista ordenada por mês (mais recente primeiro)
    final listaOrdenada = pendenciasPorMes.values.toList();
    listaOrdenada.sort((a, b) {
      final mesAnoA = a['mesAno'] as String;
      final mesAnoB = b['mesAno'] as String;
      return mesAnoB.compareTo(mesAnoA); // Ordem decrescente (mais recente primeiro)
    });
    
    return listaOrdenada;
  }

  // Atualiza o status de pagamento de um serviço específico de um cliente único
  Future<void> updateStatusPagamentoServicoUnico(
    String uid,
    String clienteId,
    String dataServico, // Formato: "29-10-2025"
    String novoStatus, // "pago" ou "agendado"
  ) async {
    final clienteRef = _database
        .child('usuarios')
        .child(uid)
        .child('clientes_unicos')
        .child(clienteId)
        .child('historicoServicos')
        .child(dataServico);
    
    // Busca o serviço atual
    final snapshot = await clienteRef.get();
    if (snapshot.exists) {
      final servicoAtual = Map<String, dynamic>.from(snapshot.value as Map);
      
      // Atualiza apenas o statusPagamento, mantendo os outros campos
      await clienteRef.update({
        'statusPagamento': novoStatus,
        'valor': servicoAtual['valor'],
        'horario': servicoAtual['horario'] ?? '',
        if (servicoAtual['tipoServico'] != null) 'tipoServico': servicoAtual['tipoServico'],
      });
    }
  }

  // Busca dados de serviços por mês para gráfico de crescimento
  Future<Map<String, int>> getServicosPorMes(String uid, {int? ultimosMeses}) async {
    final clientesUnicos = await getClientesUnicos(uid);
    final agora = DateTime.now();
    final servicosPorMes = <String, int>{};
    
    // Define o período a ser analisado
    DateTime dataInicio;
    if (ultimosMeses != null) {
      dataInicio = DateTime(agora.year, agora.month - ultimosMeses + 1, 1);
    } else {
      // Se não especificado, busca desde o primeiro serviço
      DateTime? primeiraData;
      for (final cliente in clientesUnicos) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataKey = entry.key; // Formato: "29-10-2025"
          try {
            final partes = dataKey.split('-');
            if (partes.length == 3) {
              final dia = int.parse(partes[0]);
              final mes = int.parse(partes[1]);
              final ano = int.parse(partes[2]);
              final data = DateTime(ano, mes, dia);
              if (primeiraData == null || data.isBefore(primeiraData)) {
                primeiraData = data;
              }
            }
          } catch (e) {
            // Ignora erros de parse
          }
        }
      }
      dataInicio = primeiraData ?? DateTime(agora.year, agora.month - 11, 1);
    }
    
    // Inicializa todos os meses no período com 0
    DateTime dataAtual = DateTime(dataInicio.year, dataInicio.month, 1);
    while (dataAtual.isBefore(agora) || dataAtual.year == agora.year && dataAtual.month == agora.month) {
      final mesAno = '${dataAtual.year}-${dataAtual.month.toString().padLeft(2, '0')}';
      servicosPorMes[mesAno] = 0;
      dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
    }
    
    // Conta serviços por mês
    for (final cliente in clientesUnicos) {
      if (cliente.historicoServicos.isNotEmpty) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataServico = entry.key; // Formato: "29-10-2025"
          final infoServico = entry.value;
          
          try {
            final partesData = dataServico.split('-');
            if (partesData.length == 3) {
              final diaServico = int.parse(partesData[0]);
              final mesServico = int.parse(partesData[1]);
              final anoServico = int.parse(partesData[2]);
              
              // Verifica se está no período
              final dataServicoDateTime = DateTime(anoServico, mesServico, diaServico);
              if (dataServicoDateTime.isBefore(dataInicio)) {
                continue;
              }
              
              final mesAno = '$anoServico-${mesServico.toString().padLeft(2, '0')}';
              
              // Verifica o status do pagamento - conta APENAS serviços pagos
              final statusArmazenado = infoServico['statusPagamento']?.toString() ?? ClienteUnico.statusPago;
              
              // Conta apenas serviços com status "pago"
              if (statusArmazenado == ClienteUnico.statusPago && servicosPorMes.containsKey(mesAno)) {
                servicosPorMes[mesAno] = (servicosPorMes[mesAno] ?? 0) + 1;
              }
            }
          } catch (e) {
            // Ignora erros de parse
          }
        }
      }
    }
    
    return servicosPorMes;
  }

  // Busca contagem de serviços por mês para um período específico
  Future<Map<String, int>> getServicosPorMesPeriodo(String uid, DateTime dataInicio, DateTime dataFim) async {
    final clientesUnicos = await getClientesUnicos(uid);
    final servicosPorMes = <String, int>{};
    
    // Inicializa todos os meses no período com 0
    DateTime dataAtual = DateTime(dataInicio.year, dataInicio.month, 1);
    final dataFimMes = DateTime(dataFim.year, dataFim.month, 1);
    
    while (dataAtual.isBefore(dataFimMes) || dataAtual.year == dataFimMes.year && dataAtual.month == dataFimMes.month) {
      final mesAno = '${dataAtual.year}-${dataAtual.month.toString().padLeft(2, '0')}';
      servicosPorMes[mesAno] = 0;
      dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
    }
    
    // Conta serviços por mês
    for (final cliente in clientesUnicos) {
      if (cliente.historicoServicos.isNotEmpty) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataServico = entry.key; // Formato: "29-10-2025"
          final infoServico = entry.value;
          
          try {
            final partesData = dataServico.split('-');
            if (partesData.length == 3) {
              final diaServico = int.parse(partesData[0]);
              final mesServico = int.parse(partesData[1]);
              final anoServico = int.parse(partesData[2]);
              
              // Verifica se está no período
              final dataServicoDateTime = DateTime(anoServico, mesServico, diaServico);
              if (dataServicoDateTime.isBefore(dataInicio) || dataServicoDateTime.isAfter(dataFim)) {
                continue;
              }
              
              final mesAno = '$anoServico-${mesServico.toString().padLeft(2, '0')}';
              
              // Verifica o status do pagamento - conta APENAS serviços pagos
              final statusArmazenado = infoServico['statusPagamento']?.toString() ?? ClienteUnico.statusPago;
              
              // Conta apenas serviços com status "pago"
              if (statusArmazenado == ClienteUnico.statusPago && servicosPorMes.containsKey(mesAno)) {
                servicosPorMes[mesAno] = (servicosPorMes[mesAno] ?? 0) + 1;
              }
            }
          } catch (e) {
            // Ignora erros de parse
          }
        }
      }
    }
    
    return servicosPorMes;
  }

  // Busca valores (patrimonial) por mês para gráfico de evolução patrimonial
  Future<Map<String, double>> getValoresPorMes(String uid, {int? ultimosMeses}) async {
    final clientesUnicos = await getClientesUnicos(uid);
    final agora = DateTime.now();
    final valoresPorMes = <String, double>{};
    
    // Define o período a ser analisado
    DateTime dataInicio;
    if (ultimosMeses != null) {
      dataInicio = DateTime(agora.year, agora.month - ultimosMeses + 1, 1);
    } else {
      // Se não especificado, busca desde o primeiro serviço
      DateTime? primeiraData;
      for (final cliente in clientesUnicos) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataKey = entry.key; // Formato: "29-10-2025"
          try {
            final partes = dataKey.split('-');
            if (partes.length == 3) {
              final dia = int.parse(partes[0]);
              final mes = int.parse(partes[1]);
              final ano = int.parse(partes[2]);
              final data = DateTime(ano, mes, dia);
              if (primeiraData == null || data.isBefore(primeiraData)) {
                primeiraData = data;
              }
            }
          } catch (e) {
            // Ignora erros de parse
          }
        }
      }
      dataInicio = primeiraData ?? DateTime(agora.year, agora.month - 11, 1);
    }
    
    // Inicializa todos os meses no período com 0
    DateTime dataAtual = DateTime(dataInicio.year, dataInicio.month, 1);
    while (dataAtual.isBefore(agora) || dataAtual.year == agora.year && dataAtual.month == agora.month) {
      final mesAno = '${dataAtual.year}-${dataAtual.month.toString().padLeft(2, '0')}';
      valoresPorMes[mesAno] = 0.0;
      dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
    }
    
    // Soma valores por mês
    for (final cliente in clientesUnicos) {
      if (cliente.historicoServicos.isNotEmpty) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataServico = entry.key; // Formato: "29-10-2025"
          final infoServico = entry.value;
          final valorServico = (infoServico['valor'] as num?)?.toDouble() ?? 0.0;
          
          try {
            final partesData = dataServico.split('-');
            if (partesData.length == 3) {
              final diaServico = int.parse(partesData[0]);
              final mesServico = int.parse(partesData[1]);
              final anoServico = int.parse(partesData[2]);
              
              // Verifica se está no período
              final dataServicoDateTime = DateTime(anoServico, mesServico, diaServico);
              if (dataServicoDateTime.isBefore(dataInicio)) {
                continue;
              }
              
              final mesAno = '$anoServico-${mesServico.toString().padLeft(2, '0')}';
              
              // Verifica o status do pagamento - conta APENAS serviços pagos
              final statusArmazenado = infoServico['statusPagamento']?.toString() ?? ClienteUnico.statusPago;
              
              // Conta apenas serviços com status "pago"
              if (statusArmazenado == ClienteUnico.statusPago && valoresPorMes.containsKey(mesAno)) {
                valoresPorMes[mesAno] = (valoresPorMes[mesAno] ?? 0.0) + valorServico;
              }
            }
          } catch (e) {
            // Ignora erros de parse
          }
        }
      }
    }
    
    return valoresPorMes;
  }

  // Busca valores (patrimonial) por mês para um período específico
  Future<Map<String, double>> getValoresPorMesPeriodo(String uid, DateTime dataInicio, DateTime dataFim) async {
    final clientesUnicos = await getClientesUnicos(uid);
    final valoresPorMes = <String, double>{};
    
    // Inicializa todos os meses no período com 0
    DateTime dataAtual = DateTime(dataInicio.year, dataInicio.month, 1);
    final dataFimMes = DateTime(dataFim.year, dataFim.month, 1);
    
    while (dataAtual.isBefore(dataFimMes) || dataAtual.year == dataFimMes.year && dataAtual.month == dataFimMes.month) {
      final mesAno = '${dataAtual.year}-${dataAtual.month.toString().padLeft(2, '0')}';
      valoresPorMes[mesAno] = 0.0;
      dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
    }
    
    // Soma valores por mês
    for (final cliente in clientesUnicos) {
      if (cliente.historicoServicos.isNotEmpty) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataServico = entry.key; // Formato: "29-10-2025"
          final infoServico = entry.value;
          final valorServico = (infoServico['valor'] as num?)?.toDouble() ?? 0.0;
          
          try {
            final partesData = dataServico.split('-');
            if (partesData.length == 3) {
              final diaServico = int.parse(partesData[0]);
              final mesServico = int.parse(partesData[1]);
              final anoServico = int.parse(partesData[2]);
              
              // Verifica se está no período
              final dataServicoDateTime = DateTime(anoServico, mesServico, diaServico);
              if (dataServicoDateTime.isBefore(dataInicio) || dataServicoDateTime.isAfter(dataFim)) {
                continue;
              }
              
              final mesAno = '$anoServico-${mesServico.toString().padLeft(2, '0')}';
              
              // Verifica o status do pagamento - conta APENAS serviços pagos
              final statusArmazenado = infoServico['statusPagamento']?.toString() ?? ClienteUnico.statusPago;
              
              // Conta apenas serviços com status "pago"
              if (statusArmazenado == ClienteUnico.statusPago && valoresPorMes.containsKey(mesAno)) {
                valoresPorMes[mesAno] = (valoresPorMes[mesAno] ?? 0.0) + valorServico;
              }
            }
          } catch (e) {
            // Ignora erros de parse
          }
        }
      }
    }
    
    return valoresPorMes;
  }

  // Busca contagem de serviços por tipo (apenas pagos)
  Future<Map<String, int>> getServicosPorTipo(String uid, {int? ultimosMeses}) async {
    final clientesUnicos = await getClientesUnicos(uid);
    final agora = DateTime.now();
    final servicosPorTipo = <String, int>{};
    
    // Define o período a ser analisado
    DateTime? dataInicio;
    if (ultimosMeses != null) {
      dataInicio = DateTime(agora.year, agora.month - ultimosMeses + 1, 1);
    }
    
    for (final cliente in clientesUnicos) {
      if (cliente.historicoServicos.isNotEmpty) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataServico = entry.key; // Formato: "29-10-2025"
          final infoServico = entry.value;
          
          // Verifica o status do pagamento - conta APENAS serviços pagos
          final statusArmazenado = infoServico['statusPagamento']?.toString() ?? ClienteUnico.statusPago;
          
          if (statusArmazenado == ClienteUnico.statusPago) {
            // Se há filtro de período, verifica se o serviço está no período
            if (dataInicio != null) {
              try {
                final partesData = dataServico.split('-');
                if (partesData.length == 3) {
                  final diaServico = int.parse(partesData[0]);
                  final mesServico = int.parse(partesData[1]);
                  final anoServico = int.parse(partesData[2]);
                  
                  final dataServicoDateTime = DateTime(anoServico, mesServico, diaServico);
                  if (dataServicoDateTime.isBefore(dataInicio)) {
                    continue; // Ignora serviços fora do período
                  }
                }
              } catch (e) {
                // Ignora erros de parse
                continue;
              }
            }
            
            // Obtém o tipo do serviço
            final tipoServico = infoServico['tipoServico']?.toString() ?? 'Sem tipo';
            
            // Incrementa a contagem
            servicosPorTipo[tipoServico] = (servicosPorTipo[tipoServico] ?? 0) + 1;
          }
        }
      }
    }
    
    return servicosPorTipo;
  }

  // Busca valores em reais por tipo de serviço (apenas pagos)
  Future<Map<String, double>> getValoresPorTipo(String uid, {int? ultimosMeses}) async {
    final clientesUnicos = await getClientesUnicos(uid);
    final agora = DateTime.now();
    final valoresPorTipo = <String, double>{};
    
    // Define o período a ser analisado
    DateTime? dataInicio;
    if (ultimosMeses != null) {
      dataInicio = DateTime(agora.year, agora.month - ultimosMeses + 1, 1);
    }
    
    for (final cliente in clientesUnicos) {
      if (cliente.historicoServicos.isNotEmpty) {
        for (final entry in cliente.historicoServicos.entries) {
          final dataServico = entry.key; // Formato: "29-10-2025"
          final infoServico = entry.value;
          final valorServico = (infoServico['valor'] as num?)?.toDouble() ?? 0.0;
          
          // Verifica o status do pagamento - conta APENAS serviços pagos
          final statusArmazenado = infoServico['statusPagamento']?.toString() ?? ClienteUnico.statusPago;
          
          if (statusArmazenado == ClienteUnico.statusPago) {
            // Se há filtro de período, verifica se o serviço está no período
            if (dataInicio != null) {
              try {
                final partesData = dataServico.split('-');
                if (partesData.length == 3) {
                  final diaServico = int.parse(partesData[0]);
                  final mesServico = int.parse(partesData[1]);
                  final anoServico = int.parse(partesData[2]);
                  
                  final dataServicoDateTime = DateTime(anoServico, mesServico, diaServico);
                  if (dataServicoDateTime.isBefore(dataInicio)) {
                    continue; // Ignora serviços fora do período
                  }
                }
              } catch (e) {
                // Ignora erros de parse
                continue;
              }
            }
            
            // Obtém o tipo do serviço
            final tipoServico = infoServico['tipoServico']?.toString() ?? 'Sem tipo';
            
            // Soma o valor
            valoresPorTipo[tipoServico] = (valoresPorTipo[tipoServico] ?? 0.0) + valorServico;
          }
        }
      }
    }
    
    return valoresPorTipo;
  }

  // ========== MÉTODOS PARA CLIENTES RECORRENTES ==========

  // Busca valores por mês para clientes recorrentes
  Future<Map<String, double>> getValoresPorMesRecorrentes(String uid, {int? ultimosMeses}) async {
    final clientes = await getClientes(uid);
    final agora = DateTime.now();
    final valoresPorMes = <String, double>{};
    
    // Define o período a ser analisado
    DateTime dataInicio;
    if (ultimosMeses != null) {
      dataInicio = DateTime(agora.year, agora.month - ultimosMeses + 1, 1);
    } else {
      // Se não especificado, busca desde o primeiro cliente cadastrado
      DateTime? primeiraData;
      for (final cliente in clientes) {
        if (cliente.dataCadastro.isBefore(primeiraData ?? DateTime(2100, 1, 1))) {
          primeiraData = cliente.dataCadastro;
        }
      }
      dataInicio = primeiraData ?? DateTime(agora.year, agora.month - 11, 1);
    }
    
    // Inicializa todos os meses no período com 0
    DateTime dataAtual = DateTime(dataInicio.year, dataInicio.month, 1);
    while (dataAtual.isBefore(agora) || dataAtual.year == agora.year && dataAtual.month == agora.month) {
      final mesAno = '${dataAtual.year}-${dataAtual.month.toString().padLeft(2, '0')}';
      valoresPorMes[mesAno] = 0.0;
      dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
    }
    
    // Soma valores por mês (apenas clientes ativos e pagos)
    for (final cliente in clientes) {
      if (!cliente.isAtivo) continue;
      
      // Itera pelos meses no período
      DateTime dataAtualLoop = DateTime(dataInicio.year, dataInicio.month, 1);
      while (dataAtualLoop.isBefore(agora) || dataAtualLoop.year == agora.year && dataAtualLoop.month == agora.month) {
        final mesAno = '${dataAtualLoop.year}-${dataAtualLoop.month.toString().padLeft(2, '0')}';
        
        // Verifica se o cliente estava ativo no mês (cadastrado antes do final do mês)
        final fimDoMes = DateTime(dataAtualLoop.year, dataAtualLoop.month + 1, 0);
        if (cliente.dataCadastro.isBefore(fimDoMes) && cliente.isAdimplente(mesAno)) {
          valoresPorMes[mesAno] = (valoresPorMes[mesAno] ?? 0.0) + cliente.valor;
        }
        
        dataAtualLoop = DateTime(dataAtualLoop.year, dataAtualLoop.month + 1, 1);
      }
    }
    
    return valoresPorMes;
  }

  // Busca contagem de serviços por tipo para clientes recorrentes
  Future<Map<String, int>> getServicosPorTipoRecorrentes(String uid, {int? ultimosMeses}) async {
    final clientes = await getClientes(uid);
    final agora = DateTime.now();
    final servicosPorTipo = <String, int>{};
    
    // Define o período a ser analisado
    DateTime? dataInicio;
    if (ultimosMeses != null) {
      dataInicio = DateTime(agora.year, agora.month - ultimosMeses + 1, 1);
    }
    
    for (final cliente in clientes) {
      if (!cliente.isAtivo) continue;
      
      // Itera pelos meses no período
      DateTime dataAtual = dataInicio ?? DateTime(agora.year, agora.month - 11, 1);
      while (dataAtual.isBefore(agora) || dataAtual.year == agora.year && dataAtual.month == agora.month) {
        final mesAno = '${dataAtual.year}-${dataAtual.month.toString().padLeft(2, '0')}';
        
        // Verifica se o cliente estava ativo no mês e se está pago
        final fimDoMes = DateTime(dataAtual.year, dataAtual.month + 1, 0);
        if (cliente.dataCadastro.isBefore(fimDoMes) && cliente.isAdimplente(mesAno)) {
          final tipoServico = cliente.tipoServico ?? 'Sem tipo';
          servicosPorTipo[tipoServico] = (servicosPorTipo[tipoServico] ?? 0) + 1;
        }
        
        dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
      }
    }
    
    return servicosPorTipo;
  }

  // Busca valores em reais por tipo de serviço para clientes recorrentes
  Future<Map<String, double>> getValoresPorTipoRecorrentes(String uid, {int? ultimosMeses}) async {
    final clientes = await getClientes(uid);
    final agora = DateTime.now();
    final valoresPorTipo = <String, double>{};
    
    // Define o período a ser analisado
    DateTime? dataInicio;
    if (ultimosMeses != null) {
      dataInicio = DateTime(agora.year, agora.month - ultimosMeses + 1, 1);
    }
    
    for (final cliente in clientes) {
      if (!cliente.isAtivo) continue;
      
      // Itera pelos meses no período
      DateTime dataAtual = dataInicio ?? DateTime(agora.year, agora.month - 11, 1);
      while (dataAtual.isBefore(agora) || dataAtual.year == agora.year && dataAtual.month == agora.month) {
        final mesAno = '${dataAtual.year}-${dataAtual.month.toString().padLeft(2, '0')}';
        
        // Verifica se o cliente estava ativo no mês e se está pago
        final fimDoMes = DateTime(dataAtual.year, dataAtual.month + 1, 0);
        if (cliente.dataCadastro.isBefore(fimDoMes) && cliente.isAdimplente(mesAno)) {
          final tipoServico = cliente.tipoServico ?? 'Sem tipo';
          valoresPorTipo[tipoServico] = (valoresPorTipo[tipoServico] ?? 0.0) + cliente.valor;
        }
        
        dataAtual = DateTime(dataAtual.year, dataAtual.month + 1, 1);
      }
    }
    
    return valoresPorTipo;
  }
}
