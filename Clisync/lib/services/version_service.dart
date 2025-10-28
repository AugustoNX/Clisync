import 'package:shared_preferences/shared_preferences.dart';

enum VersionMode { recorrentes, unicos }

class VersionService {
  static const String _key = 'version_mode';
  
  /// Salva o modo de versão
  static Future<void> setVersionMode(VersionMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.toString());
  }
  
  /// Obtém o modo de versão atual
  static Future<VersionMode> getVersionMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_key);
    
    if (modeString == null) {
      // Retorna 'unicos' como padrão
      await setVersionMode(VersionMode.unicos);
      return VersionMode.unicos;
    }
    
    return VersionMode.values.firstWhere(
      (mode) => mode.toString() == modeString,
      orElse: () => VersionMode.unicos,
    );
  }
  
  /// Verifica se está no modo recorrentes
  static Future<bool> isRecorrentes() async {
    final mode = await getVersionMode();
    return mode == VersionMode.recorrentes;
  }
  
  /// Verifica se está no modo unicos
  static Future<bool> isUnicos() async {
    final mode = await getVersionMode();
    return mode == VersionMode.unicos;
  }
}

