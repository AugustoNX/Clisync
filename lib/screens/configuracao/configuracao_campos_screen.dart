import 'package:flutter/material.dart';
import 'package:clisync/services/config_service.dart';

class ConfiguracaoCamposScreen extends StatefulWidget {
  const ConfiguracaoCamposScreen({super.key});

  @override
  State<ConfiguracaoCamposScreen> createState() => _ConfiguracaoCamposScreenState();
}

class _ConfiguracaoCamposScreenState extends State<ConfiguracaoCamposScreen> {
  // Campos disponíveis para configuração
  Map<String, bool> _camposConfiguracao = {};
  
  // Campos personalizados adicionados pelo usuário
  Map<String, bool> _camposPersonalizados = {};
  
  // Controlador para o campo de texto do novo campo personalizado
  final TextEditingController _novoCampoController = TextEditingController();
  
  // Controlador para adicionar novos tipos de serviço
  final TextEditingController _novoTipoServicoController = TextEditingController();
  
  // Lista de tipos de serviço configuráveis
  List<String> _tiposServico = [];
  
  // Ordem definida dos campos
  final List<String> _ordemCampos = [
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
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracao();
  }

  Future<void> _carregarConfiguracao() async {
    try {
      final config = await ConfigService.carregarConfiguracaoCampos();
      final camposCarregados = Map<String, bool>.from(config['camposConfiguracao']);
      
      // Inicializa com a configuração padrão e mescla com os valores carregados
      setState(() {
        _camposConfiguracao = Map<String, bool>.from(ConfigService.configuracaoPadrao);
        _camposConfiguracao.addAll(camposCarregados);
        _camposPersonalizados = Map<String, bool>.from(config['camposPersonalizados']);
        _tiposServico = List<String>.from(config['tiposServico']);
        _isLoading = false;
      });
    } catch (e) {
      // Em caso de erro, usa configuração padrão
      setState(() {
        _camposConfiguracao = Map<String, bool>.from(ConfigService.configuracaoPadrao);
        _camposPersonalizados = <String, bool>{};
        _tiposServico = List<String>.from(ConfigService.tiposServicoPadrao);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _novoCampoController.dispose();
    _novoTipoServicoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuração de Campos'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Campos'),
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
                                final isObrigatorio = campo == 'Nome'; // Nome é sempre obrigatório
                              
                                // Campo especial "Tipo do serviço" com configuração de opções
                                if (campo == 'Tipo do serviço') {
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          leading: Icon(
                                            _getIconForField(campo),
                                            color: Colors.blue,
                                          ),
                                          title: Text(
                                            campo,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 15,
                                            ),
                                          ),
                                          trailing: Switch(
                                            value: isEnabled,
                                            onChanged: (value) {
                                              setState(() {
                                                _camposConfiguracao[campo] = value;
                                              });
                                            },
                                            activeThumbColor: Colors.green,
                                            inactiveThumbColor: Colors.grey,
                                          ),
                                        ),
                                        // Seção de configuração dos tipos de serviço (aparece quando habilitado)
                                        if (isEnabled) ...[
                                          const Divider(height: 1),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Tipos de Serviço Disponíveis:',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white70,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.add, color: Colors.green),
                                                      onPressed: _mostrarDialogoNovoTipoServico,
                                                      tooltip: 'Adicionar tipo de serviço',
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: _tiposServico.map((tipo) {
                                                    return Chip(
                                                      label: Text(tipo),
                                                      backgroundColor: Colors.blue.withValues(alpha: 0.2),
                                                      labelStyle: const TextStyle(color: Colors.white),
                                                      deleteIcon: const Icon(Icons.close, color: Colors.red, size: 18),
                                                      onDeleted: () => _removerTipoServico(tipo),
                                                    );
                                                  }).toList(),
                                                ),
                                                if (_tiposServico.isEmpty)
                                                  const Text(
                                                    'Nenhum tipo de serviço configurado',
                                                    style: TextStyle(
                                                      color: Colors.white54,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }
                                
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
      case 'Tipo do serviço':
        return Icons.category;
      default:
        return Icons.label;
    }
  }

  void _mostrarDialogoNovoTipoServico() {
    _novoTipoServicoController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Tipo de Serviço'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o nome do novo tipo de serviço:'),
            const SizedBox(height: 16),
            TextField(
              controller: _novoTipoServicoController,
              decoration: const InputDecoration(
                labelText: 'Nome do tipo',
                hintText: 'Ex: Limpeza, Manutenção, etc.',
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
            onPressed: _adicionarTipoServico,
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

  void _adicionarTipoServico() {
    final nomeTipo = _novoTipoServicoController.text.trim();
    
    if (nomeTipo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um nome para o tipo de serviço'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_tiposServico.contains(nomeTipo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este tipo de serviço já existe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _tiposServico.add(nomeTipo);
    });
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tipo de serviço "$nomeTipo" adicionado com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removerTipoServico(String tipo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Tipo de Serviço'),
        content: Text('Deseja realmente remover o tipo "$tipo"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tiposServico.remove(tipo);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tipo de serviço "$tipo" removido com sucesso!'),
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
      await ConfigService.salvarConfiguracaoCampos(
        camposConfiguracao: _camposConfiguracao,
        camposPersonalizados: _camposPersonalizados,
        tiposServico: _tiposServico,
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
                const Text('Campos ativos no cadastro:'),
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
                if (_camposConfiguracao['Tipo do serviço'] == true && _tiposServico.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Tipos de serviço configurados:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._tiposServico.map((tipo) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.category, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Text(tipo),
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
                _camposConfiguracao = Map<String, bool>.from(ConfigService.configuracaoPadrao);
                _camposPersonalizados.clear();
                _tiposServico = List<String>.from(ConfigService.tiposServicoPadrao);
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
