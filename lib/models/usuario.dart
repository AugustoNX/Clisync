class Usuario {
  final String uid;
  final String nome;
  final String email;
  final String? nomeEmpresa;
  final String? telefone;
  final String? chavePix;
  final String? cidade;
  final String? rua;
  final String? bairro;
  final String? numero;
  final String? horarioInicio;
  final String? horarioFim;
  final int? tempoServico; // Tempo médio do serviço em minutos
  final Map<String, double> servicosUnicos;
  final Map<String, double> servicosRecorrentes;

  Usuario({
    required this.uid,
    required this.nome,
    required this.email,
    this.nomeEmpresa,
    this.telefone,
    this.chavePix,
    this.cidade,
    this.rua,
    this.bairro,
    this.numero,
    this.horarioInicio,
    this.horarioFim,
    this.tempoServico,
    this.servicosUnicos = const {},
    this.servicosRecorrentes = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'nomeEmpresa': nomeEmpresa,
      'telefone': telefone,
      'chavePix': chavePix,
      'cidade': cidade,
      'rua': rua,
      'bairro': bairro,
      'numero': numero,
      'horarioInicio': horarioInicio,
      'horarioFim': horarioFim,
      'tempoServico': tempoServico,
      'servicosUnicos': servicosUnicos,
      'servicosRecorrentes': servicosRecorrentes,
    };
  }

  factory Usuario.fromMap(String uid, Map<String, dynamic> map) {
    return Usuario(
      uid: uid,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      nomeEmpresa: map['nomeEmpresa'],
      telefone: map['telefone'],
      chavePix: map['chavePix'],
      cidade: map['cidade'],
      rua: map['rua'],
      bairro: map['bairro'],
      numero: map['numero'],
      horarioInicio: map['horarioInicio'],
      horarioFim: map['horarioFim'],
      tempoServico: map['tempoServico'] != null ? (map['tempoServico'] as num).toInt() : null,
      servicosUnicos: map['servicosUnicos'] != null
          ? Map<String, double>.from(
              (map['servicosUnicos'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is double ? value : (value as num).toDouble(),
                ),
              ),
            )
          : {},
      servicosRecorrentes: map['servicosRecorrentes'] != null
          ? Map<String, double>.from(
              (map['servicosRecorrentes'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(),
                  value is double ? value : (value as num).toDouble(),
                ),
              ),
            )
          : {},
    );
  }

  Usuario copyWith({
    String? uid,
    String? nome,
    String? email,
    String? nomeEmpresa,
    String? telefone,
    String? chavePix,
    String? cidade,
    String? rua,
    String? bairro,
    String? numero,
    String? horarioInicio,
    String? horarioFim,
    int? tempoServico,
    bool? primeiroAcesso,
    Map<String, double>? servicos,
    Map<String, double>? servicosUnicos,
    Map<String, double>? servicosRecorrentes,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      nomeEmpresa: nomeEmpresa ?? this.nomeEmpresa,
      telefone: telefone ?? this.telefone,
      chavePix: chavePix ?? this.chavePix,
      cidade: cidade ?? this.cidade,
      rua: rua ?? this.rua,
      bairro: bairro ?? this.bairro,
      numero: numero ?? this.numero,
      horarioInicio: horarioInicio ?? this.horarioInicio,
      horarioFim: horarioFim ?? this.horarioFim,
      tempoServico: tempoServico ?? this.tempoServico,
      servicosUnicos: servicosUnicos ?? this.servicosUnicos,
      servicosRecorrentes: servicosRecorrentes ?? this.servicosRecorrentes,
    );
  }
}
