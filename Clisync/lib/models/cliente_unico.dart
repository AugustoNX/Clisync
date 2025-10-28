class ClienteUnico {
  final String id;
  final String nome;
  final String telefone;
  final String cidade;
  final String rua;
  final String bairro;
  final String numero;
  final String modalidade;
  final double valor;
  final DateTime dataCadastro;
  final String status; // 'ativo' ou 'desativado'
  
  // Campos dinâmicos
  final String? tipoServico;
  final String? frequencia;
  final String? horarioServico;
  final String? prioridade;
  final String? dataVencimento;
  final Map<String, String> camposPersonalizados;
  
  // Histórico de serviços com data, valor e horário (formato: {"data": {"valor": 150.0, "horario": "14:30"}})
  final Map<String, Map<String, dynamic>> historicoServicos;

  ClienteUnico({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.cidade,
    required this.rua,
    required this.bairro,
    required this.numero,
    required this.modalidade,
    required this.valor,
    DateTime? dataCadastro,
    this.status = 'ativo',
    this.tipoServico,
    this.frequencia,
    this.horarioServico,
    this.prioridade,
    this.dataVencimento,
    this.camposPersonalizados = const {},
    this.historicoServicos = const {},
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'valor': valor,
      'telefone': telefone,
      'cidade': cidade,
      'rua': rua,
      'bairro': bairro,
      'numero': numero,
      'modalidade': modalidade,
      'dataCadastro': dataCadastro.millisecondsSinceEpoch,
      'status': status,
      'tipoServico': tipoServico,
      'frequencia': frequencia,
      'horarioServico': horarioServico,
      'prioridade': prioridade,
      'dataVencimento': dataVencimento,
      'camposPersonalizados': camposPersonalizados,
      'historicoServicos': historicoServicos,
    };
  }

  factory ClienteUnico.fromMap(String id, Map<String, dynamic> map) {
    return ClienteUnico(
      id: id,
      nome: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      cidade: map['cidade'] ?? '',
      rua: map['rua'] ?? '',
      bairro: map['bairro'] ?? '',
      numero: map['numero'] ?? '',
      modalidade: map['modalidade'] ?? '',
      valor: (map['valor'] ?? 0.0).toDouble(),
      dataCadastro: map['dataCadastro'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dataCadastro'])
          : DateTime.now(),
      status: map['status'] ?? 'ativo',
      tipoServico: map['tipoServico'],
      frequencia: map['frequencia'],
      horarioServico: map['horarioServico'],
      prioridade: map['prioridade'],
      dataVencimento: map['dataVencimento'],
      camposPersonalizados: Map<String, String>.from(map['camposPersonalizados'] ?? {}),
      historicoServicos: _parseHistoricoServicos(map['historicoServicos']),
    );
  }

  // Método auxiliar para fazer parse do histórico de serviços
  static Map<String, Map<String, dynamic>> _parseHistoricoServicos(dynamic data) {
    if (data == null) return {};
    
    final resultado = <String, Map<String, dynamic>>{};
    final historico = data as Map;
    
    for (final entry in historico.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      
      // Se o valor é um número (formato antigo), converte para o novo formato
      if (value is num) {
        resultado[key] = {
          'valor': value.toDouble(),
          'horario': '',
        };
      } else if (value is Map) {
        // Formato novo com valor e horario
        resultado[key] = {
          'valor': (value['valor'] as num?)?.toDouble() ?? 0.0,
          'horario': value['horario']?.toString() ?? '',
        };
      }
    }
    
    return resultado;
  }

  ClienteUnico copyWith({
    String? id,
    String? nome,
    String? telefone,
    String? cidade,
    String? rua,
    String? bairro,
    String? numero,
    String? modalidade,
    double? valor,
    DateTime? dataCadastro,
    String? status,
    String? tipoServico,
    String? frequencia,
    String? horarioServico,
    String? prioridade,
    String?     dataVencimento,
    Map<String, String>? camposPersonalizados,
    Map<String, Map<String, dynamic>>? historicoServicos,
  }) {
    return ClienteUnico(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      cidade: cidade ?? this.cidade,
      rua: rua ?? this.rua,
      bairro: bairro ?? this.bairro,
      numero: numero ?? this.numero,
      modalidade: modalidade ?? this.modalidade,
      valor: valor ?? this.valor,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      status: status ?? this.status,
      tipoServico: tipoServico ?? this.tipoServico,
      frequencia: frequencia ?? this.frequencia,
      horarioServico: horarioServico ?? this.horarioServico,
      prioridade: prioridade ?? this.prioridade,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      camposPersonalizados: camposPersonalizados ?? this.camposPersonalizados,
      historicoServicos: historicoServicos ?? this.historicoServicos,
    );
  }

  String get enderecoCompleto => '$rua, n°$numero - $bairro, $cidade';
  
  bool get isAtivo => status == 'ativo';
  bool get isDesativado => status == 'desativado';
}
