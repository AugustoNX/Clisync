import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clisync/models/meta.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/theme/app_theme.dart';

class CriarMetaScreen extends StatefulWidget {
  const CriarMetaScreen({super.key});

  @override
  State<CriarMetaScreen> createState() => _CriarMetaScreenState();
}

class _CriarMetaScreenState extends State<CriarMetaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorAlvoController = TextEditingController();
  
  String? _indicadorSelecionado;
  DateTime? _dataLimiteSelecionada;
  
  final _databaseService = DatabaseService();
  final _authService = AuthService();
  bool _isLoading = false;

  // Opções de indicadores
  final List<Map<String, String>> _indicadores = [
    {
      'valor': 'numero_servicos',
      'nome': 'Número de serviços',
      'descricao': 'Defina uma meta para atingir um número total de serviços realizados (agendados e pagos) no período.',
      'icone': 'event',
    },
    {
      'valor': 'numero_clientes_planos',
      'nome': 'Número de clientes cadastrados em planos',
      'descricao': 'Estabeleça metas por quantidade de clientes vinculados a planos cadastrados no período.',
      'icone': 'card_giftcard',
    },
    {
      'valor': 'valor_clientes_unicos',
      'nome': 'Valor dos clientes únicos',
      'descricao': 'Estabeleça uma meta de valor total de serviços únicos (agendados e pagos) realizados no período.',
      'icone': 'attach_money',
    },
    {
      'valor': 'valor_planos',
      'nome': 'Valor dos Planos',
      'descricao': 'Defina uma meta de receita total proveniente dos pagamentos de planos realizados no período.',
      'icone': 'account_balance_wallet',
    },
  ];

  @override
  void dispose() {
    _valorAlvoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDataLimite() async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: _dataLimiteSelecionada ?? DateTime.now().add(const Duration(days: 30)),
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

  IconData _getIconePorNome(String nome) {
    switch (nome) {
      case 'event':
        return Icons.event;
      case 'people':
        return Icons.people;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'attach_money':
        return Icons.attach_money;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.track_changes;
    }
  }

  Future<void> _salvarMeta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_indicadorSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um indicador'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_dataLimiteSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data limite'),
          backgroundColor: Colors.orange,
        ),
      );
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

      final meta = Meta(
        indicador: _indicadorSelecionado!,
        valorAlvo: valorAlvo,
        dataLimite: _dataLimiteSelecionada!,
        status: 'ativa',
      );

      await _databaseService.createMeta(user.uid, meta);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta criada com sucesso!'),
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
            content: Text('Erro ao criar meta: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Meta'),
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
                const Text(
                  'Selecione o indicador',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Cards de seleção de indicador
                ..._indicadores.map((indicador) {
                  final isSelecionado = _indicadorSelecionado == indicador['valor'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _indicadorSelecionado = indicador['valor'];
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelecionado
                              ? AppTheme.primaryColor.withOpacity(0.3)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelecionado
                                ? AppTheme.primaryColor
                                : Colors.white.withOpacity(0.2),
                            width: isSelecionado ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelecionado
                                    ? AppTheme.primaryColor
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getIconePorNome(indicador['icone']!),
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    indicador['nome']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    indicador['descricao']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelecionado)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 32),

                // Campo de valor alvo
                TextFormField(
                  controller: _valorAlvoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Valor alvo',
                    prefixIcon: const Icon(Icons.track_changes, color: Colors.white70),
                    helperText: _indicadorSelecionado != null
                        ? _getUnidadeIndicador(_indicadorSelecionado!)
                        : 'Digite o valor que deseja atingir',
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
                                _dataLimiteSelecionada != null
                                    ? DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataLimiteSelecionada!)
                                    : 'Selecione até quando a meta vai',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _dataLimiteSelecionada != null
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.5),
                                  fontWeight: _dataLimiteSelecionada != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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

                if (_dataLimiteSelecionada != null && _indicadorSelecionado != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Atingir ${_formatarValorAlvo()} até ${DateFormat('dd/MM/yyyy', 'pt_BR').format(_dataLimiteSelecionada!)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
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
                          'Criar Meta',
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

  String _formatarValorAlvo() {
    if (_valorAlvoController.text.isEmpty) {
      return '';
    }

    final indicador = _indicadorSelecionado;
    if (indicador == null) {
      return '';
    }

    String valorTexto = _valorAlvoController.text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();

    final valor = double.tryParse(valorTexto);
    if (valor == null) {
      return '';
    }

    if (indicador == 'numero_servicos') {
      return '${valor.toInt()} serviços';
    } else if (indicador == 'numero_clientes_planos') {
      return '${valor.toInt()} clientes';
    } else {
      return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
    }
  }
}
