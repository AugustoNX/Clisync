import 'package:flutter/material.dart';
import 'package:clisync/services/config_unique_service.dart';

class ConfiguracaoClientesUnicosScreen extends StatefulWidget {
  const ConfiguracaoClientesUnicosScreen({super.key});

  @override
  State<ConfiguracaoClientesUnicosScreen> createState() => _ConfiguracaoClientesUnicosScreenState();
}

class _ConfiguracaoClientesUnicosScreenState extends State<ConfiguracaoClientesUnicosScreen> {
  // Campos disponíveis para configuração
  Map<String, bool> _camposConfiguracao = {};
  
  // Campos personalizados adicionados pelo usuário
  Map<String, bool> _camposPersonalizados = {};
  
  // Controlador para o campo de texto do novo campo personalizado
  final TextEditingController _novoCampoController = TextEditingController();
  
  // Ordem definida dos campos
  final List<String> _ordemCampos = [
    'Nome',
    'Data do serviço',
    'Horário do serviço',
    'Telefone', 
    'Cidade',
    'Bairro',
    'Rua',
    'Número',
    'Frequência',
    'Data de vencimento do pagamento',
    'Prioridade',
  ];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracao();
  }

  Future<void> _carregarConfiguracao() async {
    try {
      final config = await ConfigUniqueService.carregarConfiguracaoCampos();
      setState(() {
        _camposConfiguracao = Map<String, bool>.from(config['camposConfiguracao']);
        // Garante que campos obrigatórios estão sempre ativos
        _camposConfiguracao['Nome'] = true;
        _camposConfiguracao['Data do serviço'] = true;
        _camposConfiguracao['Horário do serviço'] = true;
        _camposConfiguracao['Telefone'] = true;
        _camposPersonalizados = Map<String, bool>.from(config['camposPersonalizados']);
        _isLoading = false;
      });
    } catch (e) {
      // Em caso de erro, usa configuração padrão
      setState(() {
        _camposConfiguracao = Map<String, bool>.from(ConfigUniqueService.configuracaoPadrao);
        // Garante que campos obrigatórios estão sempre ativos
        _camposConfiguracao['Nome'] = true;
        _camposConfiguracao['Data do serviço'] = true;
        _camposConfiguracao['Horário do serviço'] = true;
        _camposConfiguracao['Telefone'] = true;
        _camposPersonalizados = <String, bool>{};
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _novoCampoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuração dos campos'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração dos campos'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lista de campos configuráveis
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Campos Disponíveis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'É possivel manter apenas os campos obrigatorios, basta clicar em salvar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 209, 209, 209),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Expanded(
                          child: ListView.builder(
                            itemCount: _ordemCampos.length + _camposPersonalizados.length + 1, // +1 para o botão de adicionar
                            itemBuilder: (context, index) {
                              // Botão para adicionar campo personalizado
                              if (index == _ordemCampos.length + _camposPersonalizados.length) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.green,
                                    ),
                                    title: const Text(
                                      'Adicionar Campo Personalizado',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: _mostrarDialogoNovoCampo,
                                      color: Colors.green,
                                    ),
                                  ),
                                );
                              }
                              
                              // Campos padrão na ordem definida
                              if (index < _ordemCampos.length) {
                                final campo = _ordemCampos[index];
                                final isEnabled = _camposConfiguracao[campo] ?? false;
                                final isObrigatorio = campo == 'Nome' || campo == 'Data do serviço' || campo == 'Horário do serviço' || campo == 'Telefone';
                              
                                // Campos padrão normais
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: Icon(
                                      _getIconForField(campo),
                                      color: isObrigatorio ? Colors.orange : Colors.blue,
                                    ),
                                    title: Text(
                                      campo,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: isObrigatorio ? 16 : 15,
                                      ),
                                    ),
                                    subtitle: isObrigatorio
                                        ? const Text(
                                            'Campo obrigatório',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 12,
                                            ),
                                          )
                                        : null,
                                    trailing: Switch(
                                      value: isEnabled,
                                      onChanged: isObrigatorio
                                          ? null // Não permite desabilitar campos obrigatórios
                                          : (value) {
                                              setState(() {
                                                _camposConfiguracao[campo] = value;
                                              });
                                            },
                                      activeThumbColor: Colors.green,
                                      inactiveThumbColor: Colors.grey,
                                    ),
                                  ),
                                );
                              }
                              
                              // Campos personalizados
                              final campoPersonalizadoIndex = index - _ordemCampos.length;
                              final campoPersonalizado = _camposPersonalizados.keys.elementAt(campoPersonalizadoIndex);
                              final isEnabledPersonalizado = _camposPersonalizados[campoPersonalizado]!;
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.edit,
                                    color: Colors.purple,
                                  ),
                                  title: Text(
                                    campoPersonalizado,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Campo personalizado',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: isEnabledPersonalizado,
                                        onChanged: (value) {
                                          setState(() {
                                            _camposPersonalizados[campoPersonalizado] = value;
                                          });
                                        },
                                        activeThumbColor: Colors.green,
                                        inactiveThumbColor: Colors.grey,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removerCampoPersonalizado(campoPersonalizado),
                                        tooltip: 'Remover campo',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetarParaPadrao,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Resetar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _salvarConfiguracao,
                      icon: const Icon(Icons.save),
                      label: const Text('Salvar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForField(String campo) {
    switch (campo) {
      case 'Nome':
        return Icons.person;
      case 'Telefone':
        return Icons.phone;
      case 'Cidade':
        return Icons.location_city;
      case 'Rua':
        return Icons.streetview;
      case 'Bairro':
        return Icons.location_on;
      case 'Número':
        return Icons.numbers;
      case 'Frequência':
        return Icons.schedule;
      case 'Horário do serviço':
        return Icons.access_time;
      case 'Data do serviço':
        return Icons.calendar_today;
      case 'Prioridade':
        return Icons.priority_high;
      case 'Data de vencimento do pagamento':
        return Icons.event;
      default:
        return Icons.label;
    }
  }

  void _mostrarDialogoNovoCampo() {
    _novoCampoController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Campo Personalizado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o nome do novo campo:'),
            const SizedBox(height: 16),
            TextField(
              controller: _novoCampoController,
              decoration: const InputDecoration(
                labelText: 'Nome do campo',
                hintText: 'Ex: Observações, Tipo de serviço, etc.',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: _adicionarCampoPersonalizado,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _adicionarCampoPersonalizado() {
    final nomeCampo = _novoCampoController.text.trim();
    
    if (nomeCampo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um nome para o campo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_camposConfiguracao.containsKey(nomeCampo) || _camposPersonalizados.containsKey(nomeCampo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este campo já existe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _camposPersonalizados[nomeCampo] = true; // Adiciona habilitado por padrão
    });
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Campo "$nomeCampo" adicionado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removerCampoPersonalizado(String campo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Campo'),
        content: Text('Deseja realmente remover o campo "$campo"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _camposPersonalizados.remove(campo);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Campo "$campo" removido com sucesso!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _salvarConfiguracao() async {
    try {
      // Cria uma cópia da configuração e garante que campos obrigatórios estão sempre ativos
      final configuracaoParaSalvar = Map<String, bool>.from(_camposConfiguracao);
      configuracaoParaSalvar['Nome'] = true;
      configuracaoParaSalvar['Data do serviço'] = true;
      configuracaoParaSalvar['Horário do serviço'] = true;
      configuracaoParaSalvar['Telefone'] = true;
      
      await ConfigUniqueService.salvarConfiguracaoCampos(
        camposConfiguracao: configuracaoParaSalvar,
        camposPersonalizados: _camposPersonalizados,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuração salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Mostrar resumo da configuração
        final camposAtivos = _camposConfiguracao.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();
        
        final camposPersonalizadosAtivos = _camposPersonalizados.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Configuração Salva'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Campos ativos no cadastro de clientes únicos:'),
                const SizedBox(height: 8),
                ...camposAtivos.map((campo) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(campo),
                    ],
                  ),
                )),
                if (camposPersonalizadosAtivos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Campos personalizados:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...camposPersonalizadosAtivos.map((campo) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, color: Colors.purple, size: 16),
                        const SizedBox(width: 8),
                        Text(campo),
                      ],
                    ),
                  )),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Fecha o diálogo
                  Navigator.pop(context); // Volta para a tela de cadastro
                },
                child: const Text('OK', style: TextStyle(color: Colors.green),),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar configuração: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetarParaPadrao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetar Configuração'),
        content: const Text(
          'Deseja resetar todos os campos para a configuração padrão? '
          'Isso irá habilitar todos os campos básicos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red),),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _camposConfiguracao = Map<String, bool>.from(ConfigUniqueService.configuracaoPadrao);
                _camposPersonalizados.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuração resetada para o padrão!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Resetar', style: TextStyle(color: Colors.green),),
          ),
        ],
      ),
    );
  }
}
