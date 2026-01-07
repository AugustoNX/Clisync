class ClienteUnico {
  static const String statusAgendado = 'agendado';
  static const String statusAguardandoPagamento = 'aguardando_pagamento';
  static const String statusPago = 'pago';
  static const String statusCancelado = 'cancelado';

  final String id;
  final String nome;
  final String telefone;
  final String cidade;
  final String rua;
  final String bairro;
  final String numero;
  final String status; // 'ativo' ou 'desativado'
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
    this.status = 'ativo',
    this.frequencia,
    this.horarioServico,
    this.prioridade,
    this.dataVencimento,
    this.camposPersonalizados = const {},
    this.historicoServicos = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'telefone': telefone,
      'cidade': cidade,
      'rua': rua,
      'bairro': bairro,
      'numero': numero,
      'status': status,
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
      status: map['status'] ?? 'ativo',
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
          'statusPagamento': statusPago,
        };
      } else if (value is Map) {
        // Formato novo com valor, horario, statusPagamento e tipoServico
        final servicoMap = <String, dynamic>{
          'valor': (value['valor'] as num?)?.toDouble() ?? 0.0,
          'horario': value['horario']?.toString() ?? '',
          'statusPagamento': value['statusPagamento']?.toString() ?? statusPago,
        };
        
        // Inclui tipoServico se existir
        if (value['tipoServico'] != null) {
          servicoMap['tipoServico'] = value['tipoServico']?.toString();
        }
        
        resultado[key] = servicoMap;
      }
    }
    
    return resultado;
  }

  String obterStatusPagamento(String dataKey, {DateTime? referencia}) {
    final info = historicoServicos[dataKey];
    if (info == null) return statusPago;
    return _statusEfetivo(dataKey, info, referencia ?? DateTime.now());
  }

  String get statusAtual {
    final agora = DateTime.now();
    var temAgendado = false;
    var temAguardando = false;

    for (final entry in historicoServicos.entries) {
      final status = _statusEfetivo(entry.key, entry.value, agora);
      // Ignora serviços cancelados no cálculo do status atual
      if (status == statusCancelado) {
        continue;
      }
      if (status == statusAgendado) {
        temAgendado = true;
        break;
      }
      if (status == statusAguardandoPagamento) {
        temAguardando = true;
      }
    }

    if (temAgendado) return statusAgendado;
    if (temAguardando) return statusAguardandoPagamento;
    return statusPago;
  }

  static String _statusEfetivo(
    String dataKey,
    Map<String, dynamic> info,
    DateTime referencia,
  ) {
    final statusArmazenado = info['statusPagamento']?.toString() ?? statusPago;
    
    // Se o status armazenado é cancelado, retorna cancelado independente da data
    if (statusArmazenado == statusCancelado) {
      return statusCancelado;
    }
    
    if (statusArmazenado == statusPago) {
      return statusPago;
    }

    final dataServico = _parseDataHora(dataKey, info['horario']?.toString());
    if (dataServico == null) {
      return statusArmazenado == statusPago ? statusPago : statusAguardandoPagamento;
    }

    if (dataServico.isAfter(referencia)) {
      return statusAgendado;
    }

    return statusAguardandoPagamento;
  }

  static DateTime? _parseDataHora(String dataKey, String? horario) {
    try {
      final partesData = dataKey.split('-');
      if (partesData.length != 3) return null;

      final dia = int.parse(partesData[0]);
      final mes = int.parse(partesData[1]);
      final ano = int.parse(partesData[2]);

      int hora = 0;
      int minuto = 0;

      if (horario != null && horario.isNotEmpty) {
        final partesHorario = horario.split(':');
        if (partesHorario.length == 2) {
          hora = int.tryParse(partesHorario[0]) ?? 0;
          minuto = int.tryParse(partesHorario[1]) ?? 0;
        }
      }

      return DateTime(ano, mes, dia, hora, minuto);
    } catch (_) {
      return null;
    }
  }

  ClienteUnico copyWith({
    String? id,
    String? nome,
    String? telefone,
    String? cidade,
    String? rua,
    String? bairro,
    String? numero,
    String? status,
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
      status: status ?? this.status,
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
