import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfigUniqueService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Configuração padrão dos campos para clientes únicos
  static const Map<String, bool> _configuracaoPadrao = {
    'Nome': true,           // Sempre obrigatório
    'Valor': true,          // Sempre obrigatório
    'Data do serviço': true, // Sempre obrigatório
    'Horário do serviço': true,
    'Telefone': false,      
    'Cidade': false,
    'Bairro': false,
    'Rua': false,
    'Número': false,
    'Tipo do serviço': false,
    'Frequência': false,
    'Data de vencimento do pagamento': false,
    'Prioridade': false,
  };

  // Tipos de serviço padrão para clientes únicos
  static const List<String> _tiposServicoPadrao = [];

  /// Salva a configuração de campos do usuário no Firebase para clientes únicos
  static Future<void> salvarConfiguracaoCampos({
    required Map<String, bool> camposConfiguracao,
    required Map<String, bool> camposPersonalizados,
    required List<String> tiposServico,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final configRef = _database.ref('usuarios/${user.uid}/configuracao_clientes_unicos');
    
    await configRef.set({
      'camposConfiguracao': camposConfiguracao,
      'camposPersonalizados': camposPersonalizados,
      'tiposServico': tiposServico,
      'ultimaAtualizacao': ServerValue.timestamp,
    });
  }

  /// Carrega a configuração de campos do usuário do Firebase para clientes únicos
  static Future<Map<String, dynamic>> carregarConfiguracaoCampos() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final configRef = _database.ref('usuarios/${user.uid}/configuracao_clientes_unicos');
    final snapshot = await configRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return {
        'camposConfiguracao': Map<String, bool>.from(data['camposConfiguracao'] ?? {}),
        'camposPersonalizados': Map<String, bool>.from(data['camposPersonalizados'] ?? {}),
        'tiposServico': List<String>.from(data['tiposServico'] ?? []),
      };
    } else {
      // Retorna configuração padrão se não existir
      return {
        'camposConfiguracao': Map<String, bool>.from(_configuracaoPadrao),
        'camposPersonalizados': <String, bool>{},
        'tiposServico': List<String>.from(_tiposServicoPadrao),
      };
    }
  }

  /// Obtém apenas os campos ativos (habilitados) para exibição de clientes únicos
  static Future<List<String>> obterCamposAtivos() async {
    final config = await carregarConfiguracaoCampos();
    final camposConfiguracao = config['camposConfiguracao'] as Map<String, bool>;
    final camposPersonalizados = config['camposPersonalizados'] as Map<String, bool>;

    // Ordem definida dos campos
    final ordemCampos = [
      'Nome',
      'Valor',
      'Telefone', 
      'Cidade',
      'Bairro',
      'Rua',
      'Número',
      'Tipo do serviço',
      'Data do serviço',
      'Horário do serviço',
      'Frequência',
      'Data de vencimento do pagamento',
      'Prioridade',
    ];

    final camposAtivos = <String>[];

    // Adiciona campos padrão ativos na ordem definida
    for (final campo in ordemCampos) {
      if (camposConfiguracao[campo] == true) {
        camposAtivos.add(campo);
      }
    }

    // Adiciona campos personalizados ativos no final
    for (final entry in camposPersonalizados.entries) {
      final campo = entry.key;
      final ativo = entry.value;
      if (ativo && !ordemCampos.contains(campo)) {
        camposAtivos.add(campo);
      }
    }

    return camposAtivos;
  }

  /// Obtém os tipos de serviço configurados para clientes únicos
  static Future<List<String>> obterTiposServico() async {
    final config = await carregarConfiguracaoCampos();
    return List<String>.from(config['tiposServico'] ?? _tiposServicoPadrao);
  }

  /// Verifica se um campo específico está ativo para clientes únicos
  static Future<bool> isCampoAtivo(String nomeCampo) async {
    final camposAtivos = await obterCamposAtivos();
    return camposAtivos.contains(nomeCampo);
  }

  /// Obtém a configuração padrão para clientes únicos
  static Map<String, bool> get configuracaoPadrao => Map<String, bool>.from(_configuracaoPadrao);
  static List<String> get tiposServicoPadrao => List<String>.from(_tiposServicoPadrao);
}
