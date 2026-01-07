import 'package:flutter/material.dart';
import 'package:clisync/theme/app_theme.dart';

class EditorTextoDescricaoScreen extends StatefulWidget {
  final String textoInicial;

  const EditorTextoDescricaoScreen({
    super.key,
    required this.textoInicial,
  });

  @override
  State<EditorTextoDescricaoScreen> createState() =>
      _EditorTextoDescricaoScreenState();
}

class _EditorTextoDescricaoScreenState
    extends State<EditorTextoDescricaoScreen> {
  late TextEditingController _controller;
  int _contadorCaracteres = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.textoInicial);
    _contadorCaracteres = widget.textoInicial.length;
    _controller.addListener(_atualizarContador);
  }

  void _atualizarContador() {
    setState(() {
      _contadorCaracteres = _controller.text.length;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_atualizarContador);
    _controller.dispose();
    super.dispose();
  }

  void _salvar() {
    Navigator.pop(context, _controller.text);
  }

  void _cancelar() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final linhas = _controller.text.split('\n').length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Descrição'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _salvar,
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de informações
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surfaceColor,
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  '$linhas linha${linhas != 1 ? 's' : ''} • $_contadorCaracteres caractere${_contadorCaracteres != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    _controller.clear();
                  },
                  icon: Icon(
                    Icons.clear,
                    size: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  label: Text(
                    'Limpar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Editor de texto
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Digite a descrição do plano aqui...\n\nVocê pode usar múltiplas linhas e parágrafos.\n\nExemplo:\n• Benefício 1\n• Benefício 2\n• Benefício 3',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    height: 1.5,
                  ),
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          
          // Dicas de formatação
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Dicas de formatação',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildDica('• Para nova linha, pressione Enter'),
                    _buildDica('• Use múltiplas linhas para listas'),
                    _buildDica('• Você pode copiar e colar texto'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelar,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Salvar Descrição',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDica(String texto) {
    return Text(
      texto,
      style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 11,
      ),
    );
  }
}

