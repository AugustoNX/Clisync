class Plano {
  final String? id;
  final String nome;
  final double valor;
  final String frequencia; // mensal, semanal, anual, etc
  final String descricao;
  final String status; // 'ativo' ou 'desativado'

  Plano({
    this.id,
    required this.nome,
    required this.valor,
    required this.frequencia,
    required this.descricao,
    this.status = 'ativo',
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'valor': valor,
      'frequencia': frequencia,
      'descricao': descricao,
      'status': status,
    };
  }

  factory Plano.fromMap(String id, Map<String, dynamic> map) {
    return Plano(
      id: id,
      nome: map['nome'] ?? '',
      valor: (map['valor'] ?? 0.0).toDouble(),
      frequencia: map['frequencia'] ?? 'mensal',
      descricao: map['descricao'] ?? '',
      status: map['status'] ?? 'ativo',
    );
  }

  Plano copyWith({
    String? id,
    String? nome,
    double? valor,
    String? frequencia,
    String? descricao,
    String? status,
  }) {
    return Plano(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      valor: valor ?? this.valor,
      frequencia: frequencia ?? this.frequencia,
      descricao: descricao ?? this.descricao,
      status: status ?? this.status,
    );
  }
}

