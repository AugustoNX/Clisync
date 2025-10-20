import 'package:intl/intl.dart';

class Cliente {
  final String id;
  final String nome;
  final String telefone;
  final String cidade;
  final String rua;
  final String bairro;
  final String numero;
  final String modalidade;
  final double valor;
  final Map<String, bool> statusPagamento;
  final DateTime dataCadastro;
  final String status; // 'ativo' ou 'desativado'
  
  // Novos campos dinâmicos
  final String? tipoServico;
  final String? frequencia;
  final String? horarioServico;
  final String? dataServico;
  final String? prioridade;
  final String? dataVencimento;
  final Map<String, String> camposPersonalizados;

  Cliente({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.cidade,
    required this.rua,
    required this.bairro,
    required this.numero,
    required this.modalidade,
    required this.valor,
    this.statusPagamento = const {},
    DateTime? dataCadastro,
    this.status = 'ativo',
    this.tipoServico,
    this.frequencia,
    this.horarioServico,
    this.dataServico,
    this.prioridade,
    this.dataVencimento,
    this.camposPersonalizados = const {},
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'telefone': telefone,
      'cidade': cidade,
      'rua': rua,
      'bairro': bairro,
      'numero': numero,
      'modalidade': modalidade,
      'valor': valor,
      'statusPagamento': statusPagamento,
      'dataCadastro': dataCadastro.millisecondsSinceEpoch,
      'status': status,
      'tipoServico': tipoServico,
      'frequencia': frequencia,
      'horarioServico': horarioServico,
      'dataServico': dataServico,
      'prioridade': prioridade,
      'dataVencimento': dataVencimento,
      'camposPersonalizados': camposPersonalizados,
    };
  }

  factory Cliente.fromMap(String id, Map<String, dynamic> map) {
    return Cliente(
      id: id,
      nome: map['nome'] ?? '',
      telefone: map['telefone'] ?? '',
      cidade: map['cidade'] ?? '',
      rua: map['rua'] ?? '',
      bairro: map['bairro'] ?? '',
      numero: map['numero'] ?? '',
      modalidade: map['modalidade'] ?? '',
      valor: (map['valor'] ?? 0.0).toDouble(),
      statusPagamento: Map<String, bool>.from(map['statusPagamento'] ?? {}),
      dataCadastro: map['dataCadastro'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dataCadastro'])
          : DateTime.now(),
      status: map['status'] ?? 'ativo',
      tipoServico: map['tipoServico'],
      frequencia: map['frequencia'],
      horarioServico: map['horarioServico'],
      dataServico: map['dataServico'],
      prioridade: map['prioridade'],
      dataVencimento: map['dataVencimento'],
      camposPersonalizados: Map<String, String>.from(map['camposPersonalizados'] ?? {}),
    );
  }

  Cliente copyWith({
    String? id,
    String? nome,
    String? telefone,
    String? cidade,
    String? rua,
    String? bairro,
    String? numero,
    String? modalidade,
    double? valor,
    Map<String, bool>? statusPagamento,
    DateTime? dataCadastro,
    String? status,
    String? tipoServico,
    String? frequencia,
    String? horarioServico,
    String? dataServico,
    String? prioridade,
    String? dataVencimento,
    Map<String, String>? camposPersonalizados,
  }) {
    return Cliente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      cidade: cidade ?? this.cidade,
      rua: rua ?? this.rua,
      bairro: bairro ?? this.bairro,
      numero: numero ?? this.numero,
      modalidade: modalidade ?? this.modalidade,
      valor: valor ?? this.valor,
      statusPagamento: statusPagamento ?? this.statusPagamento,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      status: status ?? this.status,
      tipoServico: tipoServico ?? this.tipoServico,
      frequencia: frequencia ?? this.frequencia,
      horarioServico: horarioServico ?? this.horarioServico,
      dataServico: dataServico ?? this.dataServico,
      prioridade: prioridade ?? this.prioridade,
      dataVencimento: dataVencimento ?? this.dataVencimento,
      camposPersonalizados: camposPersonalizados ?? this.camposPersonalizados,
    );
  }

  String get enderecoCompleto => '$rua, n°$numero - $bairro, $cidade';
  
  bool isAdimplente(String mesAno) {
    return statusPagamento[mesAno] ?? false;
  }
  
  bool foiCadastradoNoMes(String mesAno) {
    final dataFormatada = DateFormat('yyyy-MM').format(dataCadastro);
    return dataFormatada == mesAno;
  }
  
  bool get isAtivo => status == 'ativo';
  bool get isDesativado => status == 'desativado';
}
