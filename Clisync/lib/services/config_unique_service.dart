import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfigUniqueService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Map<String, bool> _configuracaoPadrao = {
    'Nome': true,
    'Data do serviço': true,
    'Horário do serviço': true,
    'Telefone': true, 
    'Cidade': false,
    'Bairro': false,
    'Rua': false,
    'Número': false,
    'Frequência': false,
    'Data de vencimento do pagamento': false,
    'Prioridade': false,
  };

  /// Salva a configuração de campos do usuário no Firebase para clientes únicos
  static Future<void> salvarConfiguracaoCampos({
    required Map<String, bool> camposConfiguracao,
    required Map<String, bool> camposPersonalizados,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final configRef = _database.ref('usuarios/${user.uid}/configuracao_unicos');
    
    // Salva os campos diretamente no nível raiz, junto com camposPersonalizados
    final dadosParaSalvar = <String, dynamic>{
      ...camposConfiguracao,
      'camposPersonalizados': camposPersonalizados,
    };
    
    await configRef.set(dadosParaSalvar);
  }

  /// Carrega a configuração de campos do usuário do Firebase para clientes únicos
  static Future<Map<String, dynamic>> carregarConfiguracaoCampos() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final configRef = _database.ref('usuarios/${user.uid}/configuracao_unicos');
    final snapshot = await configRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
      
      // Formato novo: campos diretamente no raiz
      final camposConfiguracao = <String, bool>{};
      final camposPersonalizados = <String, bool>{};
      
      for (final entry in data.entries) {
        if (entry.key == 'camposPersonalizados') {
          if (entry.value is Map) {
            camposPersonalizados.addAll(Map<String, bool>.from(entry.value));
          }
        } else if (entry.value is bool) {
          // Campos de configuração (valores booleanos)
          camposConfiguracao[entry.key] = entry.value as bool;
        }
      }
      
      return {
        'camposConfiguracao': camposConfiguracao,
        'camposPersonalizados': camposPersonalizados,
      };
    } else {
      // Retorna configuração padrão se não existir
      return {
        'camposConfiguracao': Map<String, bool>.from(_configuracaoPadrao),
        'camposPersonalizados': <String, bool>{},
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
      'Telefone', 
      'Cidade',
      'Bairro',
      'Rua',
      'Número',
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

  /// Verifica se um campo específico está ativo para clientes únicos
  static Future<bool> isCampoAtivo(String nomeCampo) async {
    final camposAtivos = await obterCamposAtivos();
    return camposAtivos.contains(nomeCampo);
  }

  /// Obtém a configuração padrão para clientes únicos
  static Map<String, bool> get configuracaoPadrao => Map<String, bool>.from(_configuracaoPadrao);
}
