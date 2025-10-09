import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:vigilancia_app/models/cliente.dart';

class PdfService {
  static Future<void> gerarRelatorioMensal({
    required String mesAno,
    required String nomeMes,
    required Map<String, dynamic> relatorio,
    required List<Cliente> clientes,
    required String nomeEmpresa,
  }) async {
    final pdf = pw.Document();
    
    // Obter dados do mês
    final dataEmissao = DateTime.now();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // 1. Cabeçalho
            _buildHeader(nomeEmpresa, nomeMes, dataEmissao),
            pw.SizedBox(height: 30),
            
            // 2. Resumo do Mês
            _buildResumoMes(relatorio),
            pw.SizedBox(height: 20),
            
            // 3. Detalhamento dos Clientes
            _buildDetalhamentoClientes(clientes, mesAno),
            pw.SizedBox(height: 20),
            
            // 4. Movimentações Recentes
            _buildMovimentacoes(clientes, mesAno),
            pw.SizedBox(height: 20),
            
            // 5. Status Financeiro Geral
            _buildStatusFinanceiro(relatorio),
            pw.SizedBox(height: 20),
            
            // 6. Observações
            _buildObservacoes(relatorio),
            pw.SizedBox(height: 30),
            
            // 7. Rodapé
            _buildRodape(nomeEmpresa),
          ];
        },
      ),
    );
    
    // Salvar e abrir o PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatório_Mensal_${mesAno.replaceAll('-', '_')}.pdf',
    );
  }
  
  static pw.Widget _buildHeader(String nomeEmpresa, String nomeMes, DateTime dataEmissao) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          nomeEmpresa,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Relatório Mensal - $nomeMes',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Data de emissão: ${DateFormat('dd/MM/yyyy').format(dataEmissao)}',
          style: pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  
  static pw.Widget _buildResumoMes(Map<String, dynamic> relatorio) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Resumo do Mês',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildResumoItem('Clientes ativos', relatorio['totalClientesAtivos'].toString()),
                _buildResumoItem('Novos clientes', relatorio['novosClientes'].toString()),
                _buildResumoItem('Clientes pausados', relatorio['clientesQueSairam'].toString()),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildResumoItem('Valor total recebido', NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(relatorio['valorRecebido'])),
                _buildResumoItem('Valor pendente', NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(relatorio['valorPendente'])),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildResumoItem(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 10),
          pw.Text(value),
        ],
      ),
    );
  }
  
  static pw.Widget _buildDetalhamentoClientes(List<Cliente> clientes, String mesAno) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detalhamento dos Clientes',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FixedColumnWidth(100),
            1: const pw.FixedColumnWidth(80),
            2: const pw.FixedColumnWidth(90),
            3: const pw.FixedColumnWidth(90),
            4: const pw.FixedColumnWidth(90),
            5: const pw.FixedColumnWidth(90),
            6: const pw.FixedColumnWidth(90),
          },
          children: [
            // Cabeçalho da tabela
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Nome do Cliente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Data de Entrada', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Data de Pausa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Valor Mensal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Valor Pago', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Situação', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            // Dados dos clientes
            ...clientes.map((cliente) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(cliente.nome, style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(cliente.isAtivo ? 'Ativo' : 'Pausado', style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(DateFormat('dd/MM/yyyy').format(cliente.dataCadastro), style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('-', style: const pw.TextStyle(fontSize: 10)), // TODO: Implementar data de pausa
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(cliente.valor), style: const pw.TextStyle(fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    cliente.isAdimplente(mesAno) 
                        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(cliente.valor)
                        : 'R\$ 0,00',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    cliente.isAtivo 
                        ? (cliente.isAdimplente(mesAno) ? 'Adimplente' : 'Inadimplente')
                        : '-',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildMovimentacoes(List<Cliente> clientes, String mesAno) {
    final movimentacoes = <String>[];
    
    // Adicionar novos clientes do mês
    final novosClientes = clientes.where((c) => c.foiCadastradoNoMes(mesAno)).toList();
    for (final cliente in novosClientes) {
      movimentacoes.add('${DateFormat('dd/MM/yyyy').format(cliente.dataCadastro)} – Novo cliente cadastrado: ${cliente.nome}');
    }
    
    // Adicionar clientes pausados (simplificado)
    final clientesPausados = clientes.where((c) => c.isDesativado).toList();
    for (final cliente in clientesPausados) {
      movimentacoes.add('${DateFormat('dd/MM/yyyy').format(DateTime.now())} – Cliente pausado: ${cliente.nome}');
    }
    
    // Adicionar pagamentos recebidos
    final clientesAdimplentes = clientes.where((c) => c.isAtivo && c.isAdimplente(mesAno)).toList();
    for (final cliente in clientesAdimplentes) {
      movimentacoes.add('${DateFormat('dd/MM/yyyy').format(DateTime.now())} – Pagamento recebido: ${cliente.nome} (${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(cliente.valor)})');
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Movimentações Recentes',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        ...movimentacoes.map((mov) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Text(mov),
        )),
      ],
    );
  }
  
  static pw.Widget _buildStatusFinanceiro(Map<String, dynamic> relatorio) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Status Financeiro Geral',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildResumoItem('Valor total esperado', NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(relatorio['valorTotal'])),
                _buildResumoItem('Valor recebido', NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(relatorio['valorRecebido'])),
                _buildResumoItem('Valor pendente', NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(relatorio['valorPendente'])),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildResumoItem('Clientes adimplentes', relatorio['clientesAdimplentes'].toString()),
                _buildResumoItem('Clientes inadimplentes', relatorio['clientesInadimplentes'].toString()),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  static pw.Widget _buildObservacoes(Map<String, dynamic> relatorio) {
    String observacao = '';
    
    if (relatorio['clientesInadimplentes'] == 0) {
      observacao = 'Nenhum cliente inadimplente no mês. Todos os serviços ativos foram pagos corretamente.';
    } else {
      observacao = '${relatorio['clientesInadimplentes']} cliente(s) inadimplente(s) no mês.';
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Observações',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(observacao),
      ],
    );
  }
  
  static pw.Widget _buildRodape(String nomeEmpresa) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          nomeEmpresa,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Telefone: (xx) xxxx-xxxx | E-mail: contato@seguranca.com',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          'Endereço: Rua Exemplo, 123 – Cidade/UF',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
