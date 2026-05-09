import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clisync/models/meta.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/theme/app_theme.dart';

class EditarMetaScreen extends StatefulWidget {
  final Meta meta;

  const EditarMetaScreen({
    super.key,
    required this.meta,
  });

  @override
  State<EditarMetaScreen> createState() => _EditarMetaScreenState();
}

class _EditarMetaScreenState extends State<EditarMetaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _valorAlvoController;
  
  late DateTime _dataLimiteSelecionada;
  
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa com os valores atuais da meta
    _valorAlvoController = TextEditingController(
      text: _formatarValorParaInput(widget.meta.valorAlvo, widget.meta.indicador),
    );
    _dataLimiteSelecionada = widget.meta.dataLimite;
  }

  @override
  void dispose() {
    _valorAlvoController.dispose();
    super.dispose();
  }

  String _formatarValorParaInput(double valor, String indicador) {
    if (indicador == 'numero_servicos' || indicador == 'numero_clientes_planos') {
      return valor.toInt().toString();
    } else {
      return valor.toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  IconData _getIconeIndicador(String indicador) {
    switch (indicador) {
      case 'numero_servicos':
        return Icons.event;
      case 'numero_clientes_planos':
        return Icons.card_giftcard;
      case 'valor_clientes_unicos':
        return Icons.attach_money;
      case 'valor_planos':
        return Icons.account_balance_wallet;
      default:
        return Icons.track_changes;
    }
  }

  String _getNomeIndicador(String indicador) {
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

  Future<void> _selecionarDataLimite() async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataLimiteSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 anos
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (dataSelecionada != null) {
      setState(() {
        _dataLimiteSelecionada = dataSelecionada;
      });
    }
  }

  Future<void> _salvarMeta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      if (widget.meta.id == null) {
        throw Exception('ID da meta não encontrado');
      }

      // Remove formatação do valor (R$ e pontos/vírgulas)
      String valorTexto = _valorAlvoController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();

      final valorAlvo = double.tryParse(valorTexto) ?? 0.0;

      if (valorAlvo <= 0) {
        throw Exception('O valor alvo deve ser maior que zero');
      }

      // Atualiza apenas valor alvo e data limite, mantendo o resto
      final metaAtualizada = widget.meta.copyWith(
        valorAlvo: valorAlvo,
        dataLimite: _dataLimiteSelecionada,
      );

      await _databaseService.updateMeta(user.uid, widget.meta.id!, metaAtualizada);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta atualizada com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar meta: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getUnidadeIndicador(String indicador) {
    switch (indicador) {
      case 'numero_servicos':
        return 'Digite a quantidade de serviços que deseja atingir';
      case 'numero_clientes_planos':
        return 'Digite a quantidade de clientes que deseja atingir';
      case 'valor_clientes_unicos':
      case 'valor_planos':
        return 'Digite o valor em R\$ que deseja atingir';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Meta'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indicador (apenas informativo)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getIconeIndicador(widget.meta.indicador),
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Indicador',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getNomeIndicador(widget.meta.indicador),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Campo de valor alvo
                TextFormField(
                  controller: _valorAlvoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Valor alvo',
                    prefixIcon: const Icon(Icons.track_changes, color: Colors.white70),
                    helperText: _getUnidadeIndicador(widget.meta.indicador),
                    helperMaxLines: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite o valor alvo';
                    }
                    
                    // Remove formatação para validar
                    String valorTexto = value
                        .replaceAll('R\$', '')
                        .replaceAll('.', '')
                        .replaceAll(',', '.')
                        .trim();

                    final valor = double.tryParse(valorTexto);
                    if (valor == null || valor <= 0) {
                      return 'Digite um valor válido maior que zero';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Seletor de data limite
                InkWell(
                  onTap: _selecionarDataLimite,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white70, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data limite',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataLimiteSelecionada),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Botão de salvar
                ElevatedButton(
                  onPressed: _isLoading ? null : _salvarMeta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Salvar Alterações',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}