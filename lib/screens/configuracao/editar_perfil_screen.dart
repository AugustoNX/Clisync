import 'package:flutter/material.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/services/database_service.dart';
import 'package:clisync/models/usuario.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _nomeEmpresaController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _chavePixController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ruaController = TextEditingController();
  final _bairroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _horarioInicioController = TextEditingController();
  final _horarioFimController = TextEditingController();
  final _tempoServicoController = TextEditingController();
  
  TimeOfDay? _horarioInicio;
  TimeOfDay? _horarioFim;
  
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _mostrarErrosHorarios = false;
  Usuario? _usuarioAtual;

  // Máscara para telefone: +55 44999999999
  final _telefoneMaskFormatter = MaskTextInputFormatter(
    mask: '###########',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeEmpresaController.dispose();
    _telefoneController.dispose();
    _chavePixController.dispose();
    _cidadeController.dispose();
    _ruaController.dispose();
    _bairroController.dispose();
    _numeroController.dispose();
    _horarioInicioController.dispose();
    _horarioFimController.dispose();
    _tempoServicoController.dispose();
    super.dispose();
  }
  
  String _formatarHorario(TimeOfDay horario) {
    return '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
  }
  
  Future<void> _selecionarHorarioInicio() async {
    final TimeOfDay? selecionado = await showTimePicker(
      context: context,
      initialTime: _horarioInicio ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              surface: const Color(0xFF374151),
              onSurface: Colors.white,
              secondary: const Color(0xFF1E3A8A),
              onSecondary: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF374151),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    
    if (selecionado != null) {
      setState(() {
        _horarioInicio = selecionado;
        _horarioInicioController.text = _formatarHorario(selecionado);
        // Se ambos os horários estão preenchidos, não mostrar mais erros
        if (_horarioFim != null) {
          _mostrarErrosHorarios = false;
        }
      });
      // Força revalidação do formulário
      _formKey.currentState?.validate();
    }
  }
  
  Future<void> _selecionarHorarioFim() async {
    final TimeOfDay? selecionado = await showTimePicker(
      context: context,
      initialTime: _horarioFim ?? const TimeOfDay(hour: 18, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              surface: const Color(0xFF374151),
              onSurface: Colors.white,
              secondary: const Color(0xFF1E3A8A),
              onSecondary: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF374151),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    
    if (selecionado != null) {
      setState(() {
        _horarioFim = selecionado;
        _horarioFimController.text = _formatarHorario(selecionado);
        // Se ambos os horários estão preenchidos, não mostrar mais erros
        if (_horarioInicio != null) {
          _mostrarErrosHorarios = false;
        }
      });
      // Força revalidação do formulário
      _formKey.currentState?.validate();
    }
  }

  Future<void> _carregarDadosUsuario() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _databaseService.getUser(user.uid);
        if (userData != null) {
          _usuarioAtual = Usuario.fromMap(user.uid, userData);
          
                    _nomeController.text = _usuarioAtual!.nome;
          _nomeEmpresaController.text = _usuarioAtual!.nomeEmpresa ?? '';       
          _telefoneController.text = _usuarioAtual!.telefone ?? '';
          _chavePixController.text = _usuarioAtual!.chavePix ?? '';
          _cidadeController.text = _usuarioAtual!.cidade ?? '';
          _ruaController.text = _usuarioAtual!.rua ?? '';
          _bairroController.text = _usuarioAtual!.bairro ?? '';
          _numeroController.text = _usuarioAtual!.numero ?? '';
          
          // Inicializar horários
          if (_usuarioAtual!.horarioInicio != null && _usuarioAtual!.horarioInicio!.isNotEmpty) {
            try {
              final partes = _usuarioAtual!.horarioInicio!.split(':');
              if (partes.length == 2) {
                final hour = int.tryParse(partes[0]);
                final minute = int.tryParse(partes[1]);
                if (hour != null && minute != null) {
                  _horarioInicio = TimeOfDay(hour: hour, minute: minute);
                  _horarioInicioController.text = _formatarHorario(_horarioInicio!);
                }
              }
            } catch (e) {
              // Ignora erro de parsing
            }
          }
          if (_usuarioAtual!.horarioFim != null && _usuarioAtual!.horarioFim!.isNotEmpty) {
            try {
              final partes = _usuarioAtual!.horarioFim!.split(':');
              if (partes.length == 2) {
                final hour = int.tryParse(partes[0]);
                final minute = int.tryParse(partes[1]);
                if (hour != null && minute != null) {
                  _horarioFim = TimeOfDay(hour: hour, minute: minute);
                  _horarioFimController.text = _formatarHorario(_horarioFim!);
                }
              }
            } catch (e) {
              // Ignora erro de parsing
            }
          }
          
          // Carrega tempo do serviço
          if (_usuarioAtual!.tempoServico != null) {
            _tempoServicoController.text = _usuarioAtual!.tempoServico.toString();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _salvarPerfil() async {
    // Validar horários obrigatórios
    String? erroValidacao;
    
    if (_horarioInicio == null) {
      erroValidacao = 'Horário de início é obrigatório';
    } else if (_horarioFim == null) {
      erroValidacao = 'Horário de fim é obrigatório';
    }
    
    // Se houver erro de validação nos horários, mostrar mensagem
    if (erroValidacao != null) {
      setState(() {
        _mostrarErrosHorarios = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erroValidacao),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _authService.currentUser;
        if (user != null && _usuarioAtual != null) {
                    final usuarioAtualizado = Usuario(
            uid: _usuarioAtual!.uid,
            nome: _nomeController.text.trim(),
            email: _usuarioAtual!.email,
            nomeEmpresa: _nomeEmpresaController.text.trim().isEmpty
                ? null
                : _nomeEmpresaController.text.trim(),
            telefone: _telefoneController.text.trim().isEmpty
                ? null
                : _telefoneController.text.trim(),
            chavePix: _chavePixController.text.trim().isEmpty
                ? null
                : _chavePixController.text.trim(),
            cidade: _cidadeController.text.trim().isEmpty 
                ? null
                : _cidadeController.text.trim(),
            rua: _ruaController.text.trim().isEmpty
                ? null
                : _ruaController.text.trim(),
            bairro: _bairroController.text.trim().isEmpty
                ? null
                : _bairroController.text.trim(),
            numero: _numeroController.text.trim().isEmpty
                ? null
                : _numeroController.text.trim(),
            horarioInicio: _horarioInicio != null ? _formatarHorario(_horarioInicio!) : null,
            horarioFim: _horarioFim != null ? _formatarHorario(_horarioFim!) : null,
            tempoServico: _tempoServicoController.text.trim().isNotEmpty
                ? int.tryParse(_tempoServicoController.text.trim())
                : null,
            servicosUnicos: _usuarioAtual!.servicosUnicos,
            servicosRecorrentes: _usuarioAtual!.servicosRecorrentes,
          );

          await _databaseService.updateUser(usuarioAtualizado);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perfil atualizado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(true); // Retorna true para indicar que houve atualização
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        foregroundColor: Colors.white,
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card com informações pessoais
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informações Pessoais',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Nome
                              TextFormField(
                                controller: _nomeController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome *',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'O nome é obrigatório';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Nome da Empresa
                              TextFormField(
                                controller: _nomeEmpresaController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome da Empresa *',
                                  prefixIcon: Icon(Icons.business),
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'O nome da empresa é obrigatório';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _telefoneController,
                                inputFormatters: [_telefoneMaskFormatter],      
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Telefone *',
                                  prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder(),
                                  hintText: '44999999999',
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'O telefone é obrigatório';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Chave Pix
                              TextFormField(
                                controller: _chavePixController,
                                decoration: const InputDecoration(
                                  labelText: 'Chave Pix',
                                  prefixIcon: Icon(Icons.pix),
                                  border: OutlineInputBorder(),
                                  hintText: 'CPF, e-mail, telefone ou chave aleatória',
                                ),
                                style: const TextStyle(color: Colors.white),    
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Card com horário de atendimento
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Horário de Atendimento *',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: _selecionarHorarioInicio,
                                      borderRadius: BorderRadius.circular(4),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.access_time, color: Colors.white70),
                                          hintText: '08:00',
                                          border: const OutlineInputBorder(),
                                          errorText: (_mostrarErrosHorarios && _horarioInicio == null) ? 'Obrigatório' : null,
                                          errorStyle: const TextStyle(color: Colors.red),
                                        ),
                                        child: Text(
                                          _horarioInicioController.text.isEmpty
                                              ? 'Inicio'
                                              : _horarioInicioController.text,
                                          style: TextStyle(
                                            color: _horarioInicioController.text.isEmpty
                                                ? Colors.white54
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Padding(
                                    padding: EdgeInsets.only(top: 16),
                                    child: Text(
                                      'às',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: InkWell(
                                      onTap: _selecionarHorarioFim,
                                      borderRadius: BorderRadius.circular(4),
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.access_time, color: Colors.white70),
                                          hintText: '18:00',
                                          border: const OutlineInputBorder(),
                                          errorText: (_mostrarErrosHorarios && _horarioFim == null) ? 'Obrigatório' : null,
                                          errorStyle: const TextStyle(color: Colors.red),
                                        ),
                                        child: Text(
                                          _horarioFimController.text.isEmpty
                                              ? 'Fim'
                                              : _horarioFimController.text,
                                          style: TextStyle(
                                            color: _horarioFimController.text.isEmpty
                                                ? Colors.white54
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Tempo do serviço
                              TextFormField(
                                controller: _tempoServicoController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Tempo do serviço (minutos)',
                                  prefixIcon: Icon(Icons.timer),
                                  border: OutlineInputBorder(),
                                  hintText: 'Ex: 60 (para 1 hora)',
                                  helperText: 'Tempo médio gasto em cada serviço',
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (value != null && value.trim().isNotEmpty) {
                                    final tempo = int.tryParse(value.trim());
                                    if (tempo == null || tempo <= 0) {
                                      return 'Digite um número válido maior que zero';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Card com localização
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Localização',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Cidade
                              TextFormField(
                                controller: _cidadeController,
                                decoration: const InputDecoration(
                                  labelText: 'Cidade',
                                  prefixIcon: Icon(Icons.location_city),
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              
                              // Rua
                              TextFormField(
                                controller: _ruaController,
                                decoration: const InputDecoration(
                                  labelText: 'Rua',
                                  prefixIcon: Icon(Icons.streetview),
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              
                              // Bairro e Número lado a lado
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _bairroController,
                                      decoration: const InputDecoration(
                                        labelText: 'Bairro',
                                        prefixIcon: Icon(Icons.location_on),
                                        border: OutlineInputBorder(),
                                      ),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _numeroController,
                                      decoration: const InputDecoration(
                                        labelText: 'Número',
                                        prefixIcon: Icon(Icons.numbers),
                                        border: OutlineInputBorder(),
                                      ),
                                      style: const TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Botão Salvar
                      ElevatedButton(
                        onPressed: _isLoading ? null : _salvarPerfil,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
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
