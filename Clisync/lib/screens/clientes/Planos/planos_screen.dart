import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:clisync/models/plano.dart';
import 'package:clisync/services/auth_service.dart';
import 'package:clisync/theme/app_theme.dart';
import 'package:clisync/screens/clientes/Planos/cadastro_plano_screen.dart';

class PlanosScreen extends StatefulWidget {
  const PlanosScreen({super.key});

  @override
  State<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends State<PlanosScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final AuthService _authService = AuthService();
  List<Plano> _planos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarPlanos();
  }

  Future<void> _carregarPlanos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final snapshot = await _database
            .child('usuarios')
            .child(user.uid)
            .child('planos')
            .get();

        if (snapshot.exists) {
          final Map<dynamic, dynamic> planosMap =
              Map<dynamic, dynamic>.from(snapshot.value as Map);
          setState(() {
            _planos = planosMap.entries
                .map((entry) => Plano.fromMap(
                    entry.key as String,
                    Map<String, dynamic>.from(entry.value)))
                .toList();
          });
        } else {
          setState(() {
            _planos = [];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar planos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _desativarPlano(Plano plano) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Confirmar Desativação',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja realmente desativar o plano "${plano.nome}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: const TextStyle(color: Colors.red),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmacao == true && plano.id != null) {
      try {
        final user = _authService.currentUser;
        if (user != null) {
          await _database
              .child('usuarios')
              .child(user.uid)
              .child('planos')
              .child(plano.id!)
              .child('status')
              .set('desativado');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Plano desativado com sucesso!'),
                backgroundColor: Colors.orange,
              ),
            );
            _carregarPlanos();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao desativar plano: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _ativarPlano(Plano plano) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Confirmar Ativação',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja realmente ativar o plano "${plano.nome}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: const TextStyle(color: Colors.red),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Ativar'),
          ),
        ],
      ),
    );

    if (confirmacao == true && plano.id != null) {
      try {
        final user = _authService.currentUser;
        if (user != null) {
          await _database
              .child('usuarios')
              .child(user.uid)
              .child('planos')
              .child(plano.id!)
              .child('status')
              .set('ativo');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Plano ativado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
            _carregarPlanos();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao ativar plano: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _excluirPlano(Plano plano) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Confirmar Exclusão',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deseja realmente excluir o plano "${plano.nome}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: const TextStyle(color: Colors.green),),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmacao == true && plano.id != null) {
      try {
        final user = _authService.currentUser;
        if (user != null) {
          await _database
              .child('usuarios')
              .child(user.uid)
              .child('planos')
              .child(plano.id!)
              .remove();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Plano excluído com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
            _carregarPlanos();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir plano: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planos atuais'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _planos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        size: 80,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum plano cadastrado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no botão + para adicionar um novo plano',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _buildPlanosList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CadastroPlanoScreen(),
            ),
          );
          if (resultado == true) {
            _carregarPlanos();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlanosList() {
    // Separa planos ativos e desativados
    final planosAtivos = _planos.where((p) => p.status == 'ativo').toList();
    final planosDesativados = _planos.where((p) => p.status == 'desativado').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Planos ativos
        ...planosAtivos.map((plano) => _buildPlanoCard(plano)),
        
        // Dropdown para planos desativados
        if (planosDesativados.isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(
                'Ver planos desativados (${planosDesativados.length})',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: const Icon(
                Icons.expand_more,
                color: Colors.orange,
              ),
              collapsedIconColor: Colors.orange,
              iconColor: Colors.orange,
              backgroundColor: Colors.orange.withOpacity(0.1),
              collapsedBackgroundColor: Colors.orange.withOpacity(0.05),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              collapsedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              childrenPadding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Column(
                    children: [
                      ...planosDesativados.map((plano) => _buildPlanoCard(plano)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanoCard(Plano plano) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          plano.nome,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (plano.status == 'desativado')
                        InkWell(
                          onTap: () => _ativarPlano(plano),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Desativado',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: AppTheme.accentColor,
                      ),
                      onPressed: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CadastroPlanoScreen(plano: plano),
                          ),
                        );
                        if (resultado == true) {
                          _carregarPlanos();
                        }
                      },
                    ),
                    // Mostra botão de desativar se o plano está ativo
                    if (plano.status == 'ativo')
                      IconButton(
                        icon: const Icon(
                          Icons.pause_circle,
                          color: Colors.orange,
                        ),
                        onPressed: () => _desativarPlano(plano),
                        tooltip: 'Desativar Plano',
                      ),
                    // Mostra botão de excluir apenas se o plano está desativado
                    if (plano.status == 'desativado')
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () => _excluirPlano(plano),
                        tooltip: 'Excluir Plano',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  size: 18,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'R\$ ${plano.valor.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.repeat,
                  size: 18,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _capitalizeFirst(plano.frequencia),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (plano.descricao.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.description,
                      size: 18,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plano.descricao,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

