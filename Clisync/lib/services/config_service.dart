import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfigService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Configuração padrão dos campos
  static const Map<String, bool> _configuracaoPadrao = {
    'Nome': true,           // Sempre obrigatório
    'Telefone': true,       // Sempre obrigatório
    'Cidade': false,
    'Bairro': false,
    'Rua': false,
    'Número': false,
    'Tipo do serviço': false,
    'Data do serviço': false,
    'Horário do serviço': false,
    'Frequência': false,
    'Data de vencimento do pagamento': false,
    'Prioridade': false,
  };

  // Tipos de serviço padrão
  static const List<String> _tiposServicoPadrao = [];

  /// Salva a configuração de campos do usuário no Firebase
  static Future<void> salvarConfiguracaoCampos({
    required Map<String, bool> camposConfiguracao,
    required Map<String, bool> camposPersonalizados,
    required List<String> tiposServico,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final configRef = _database.ref('usuarios/${user.uid}/configuracao_recorrentes');
    
    // Salva os campos diretamente no nível raiz, junto com camposPersonalizados e tiposServico
    final dadosParaSalvar = <String, dynamic>{
      ...camposConfiguracao,
      'camposPersonalizados': camposPersonalizados,
      'tiposServico': tiposServico,
    };
    
    await configRef.set(dadosParaSalvar);
  }

  /// Carrega a configuração de campos do usuário do Firebase
  static Future<Map<String, dynamic>> carregarConfiguracaoCampos() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final configRef = _database.ref('usuarios/${user.uid}/configuracao_recorrentes');
    final snapshot = await configRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      
      // Formato novo: campos diretamente no raiz
      final camposConfiguracao = <String, bool>{};
      final camposPersonalizados = <String, bool>{};
      final tiposServico = <String>[];
      
      for (final entry in data.entries) {
        if (entry.key == 'camposPersonalizados') {
          if (entry.value is Map) {
            camposPersonalizados.addAll(Map<String, bool>.from(entry.value));
          }
        } else if (entry.key == 'tiposServico') {
          if (entry.value is List) {
            tiposServico.addAll(List<String>.from(entry.value));
          }
        } else if (entry.value is bool) {
          // Campos de configuração (valores booleanos)
          camposConfiguracao[entry.key] = entry.value as bool;
        }
      }
      
      return {
        'camposConfiguracao': camposConfiguracao,
        'camposPersonalizados': camposPersonalizados,
        'tiposServico': tiposServico,
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

  /// Obtém apenas os campos ativos (habilitados) para exibição
  static Future<List<String>> obterCamposAtivos() async {
    final config = await carregarConfiguracaoCampos();
    final camposConfiguracao = config['camposConfiguracao'] as Map<String, bool>;
    final camposPersonalizados = config['camposPersonalizados'] as Map<String, bool>;

    // Ordem definida dos campos
    final ordemCampos = [
      'Nome',
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

  /// Obtém os tipos de serviço configurados
  static Future<List<String>> obterTiposServico() async {
    final config = await carregarConfiguracaoCampos();
    return List<String>.from(config['tiposServico'] ?? _tiposServicoPadrao);
  }

  /// Verifica se um campo específico está ativo
  static Future<bool> isCampoAtivo(String nomeCampo) async {
    final camposAtivos = await obterCamposAtivos();
    return camposAtivos.contains(nomeCampo);
  }

  /// Obtém a configuração padrão
  static Map<String, bool> get configuracaoPadrao => Map<String, bool>.from(_configuracaoPadrao);
  static List<String> get tiposServicoPadrao => List<String>.from(_tiposServicoPadrao);
}
