class Meta {
  final String? id;
  final String indicador; // 'numero_clientes', 'numero_clientes_planos', 'valor_clientes_unicos', 'valor_planos'
  final double valorAlvo;
  final DateTime dataLimite;
  final DateTime dataCriacao;
  final String status; // 'ativa', 'concluida', 'expirada'

  Meta({
    this.id,
    required this.indicador,
    required this.valorAlvo,
    required this.dataLimite,
    DateTime? dataCriacao,
    this.status = 'ativa',
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'indicador': indicador,
      'valorAlvo': valorAlvo,
      'dataLimite': dataLimite.millisecondsSinceEpoch,
      'dataCriacao': dataCriacao.millisecondsSinceEpoch,
      'status': status,
    };
  }

  factory Meta.fromMap(String id, Map<String, dynamic> map) {
    return Meta(
      id: id,
      indicador: map['indicador'] ?? '',
      valorAlvo: (map['valorAlvo'] ?? 0.0).toDouble(),
      dataLimite: map['dataLimite'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dataLimite'])
          : DateTime.now(),
      dataCriacao: map['dataCriacao'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dataCriacao'])
          : DateTime.now(),
      status: map['status'] ?? 'ativa',
    );
  }

  Meta copyWith({
    String? id,
    String? indicador,
    double? valorAlvo,
    DateTime? dataLimite,
    DateTime? dataCriacao,
    String? status,
  }) {
    return Meta(
      id: id ?? this.id,
      indicador: indicador ?? this.indicador,
      valorAlvo: valorAlvo ?? this.valorAlvo,
      dataLimite: dataLimite ?? this.dataLimite,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      status: status ?? this.status,
    );
  }

  // Métodos auxiliares para obter o nome do indicador
  String get nomeIndicador {
    switch (indicador) {
      case 'numero_servicos':
        return 'Número de serviços';
      case 'numero_clientes_planos':
        return 'Número de clientes cadastrados em planos';
      case 'valor_clientes_unicos':
        return 'Valor dos clientes únicos';
      case 'valor_planos':
        return 'Valor dos Planos';
      default:
        return indicador;
    }
  }

  // Método auxiliar para obter a unidade do indicador
  String get unidade {
    switch (indicador) {
      case 'numero_servicos':
        return 'serviços';
      case 'numero_clientes_planos':
        return 'clientes';
      case 'valor_clientes_unicos':
      case 'valor_planos':
        return 'R\$';
      default:
        return '';
    }
  }
}
