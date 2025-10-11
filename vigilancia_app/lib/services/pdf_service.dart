import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:vigilancia_app/models/cliente.dart';

class PdfService {
  // Cores do tema
  static final tituloCor = PdfColor.fromInt(0xFF1A237E); // Azul escuro
  static final subtituloCor = PdfColor.fromInt(0xFF3949AB); // Azul médio
  static final textoCor = PdfColor.fromInt(0xFF000000); // Preto

  static Future<void> gerarRelatorioMensal({
    required String mesAno,
    required String nomeMes,
    required Map<String, dynamic> relatorio,
    required List<Cliente> clientes,
    required String nomeEmpresa,
  }) async {
    final pdf = pw.Document();
    final dataEmissao = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Center(
                child: pw.Text(
                  'Relatório Mensal - $nomeMes',
                  style: pw.TextStyle(
                    color: tituloCor,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  nomeEmpresa,
                  style: pw.TextStyle(
                    color: subtituloCor,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  'Data de emissão: ${DateFormat('dd/MM/yyyy').format(dataEmissao)}',
                  style: pw.TextStyle(color: textoCor, fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Resumo do Mês',
                style: pw.TextStyle(
                  color: subtituloCor,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              _tabela([
                ['Clientes Ativos', 'Novos Clientes', 'Clientes Pausados'],
                [
                  relatorio['totalClientesAtivos'].toString(),
                  relatorio['novosClientes'].toString(),
                  relatorio['clientesQueSairam'].toString(),
                ],
              ]),
              pw.SizedBox(height: 20),

              // --- Informações Financeiras ---
              pw.Text(
                'Informações Financeiras',
                style: pw.TextStyle(
                  color: subtituloCor,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              _tabela([
                [
                  'Valor Total Esperado',
                  'Valor Recebido',
                  'Valor Pendente',
                  'Clientes Adimplentes',
                  'Clientes Inadimplentes',
                ],
                [
                  NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: 'R\$ ',
                  ).format(relatorio['valorTotal']),
                  NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: 'R\$ ',
                  ).format(relatorio['valorRecebido']),
                  NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: 'R\$ ',
                  ).format(relatorio['valorPendente']),
                  relatorio['clientesAdimplentes'].toString(),
                  relatorio['clientesInadimplentes'].toString(),
                ],
              ]),
              pw.SizedBox(height: 20),

              // --- Observações ---
              pw.Text(
                'Observações',
                style: pw.TextStyle(
                  color: subtituloCor,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                relatorio['clientesInadimplentes'] == 0
                    ? 'Nenhum cliente inadimplente no mês de $nomeMes. Todos os serviços ativos foram pagos corretamente.'
                    : '${relatorio['clientesInadimplentes']} cliente(s) inadimplente(s) no mês de $nomeMes.',
                style: pw.TextStyle(fontSize: 12),
              ),

              // Spacer para empurrar o rodapé para o final
              pw.Spacer(),

              // Rodapé
              pw.Divider(),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      nomeEmpresa,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: tituloCor,
                      ),
                    ),
                    pw.Text(
                      'Telefone: (xx) xxxx-xxxx | E-mail: contato@seguranca.com',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Endereço: Rua Exemplo, 123 – Cidade/UF',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Salvar e abrir o PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Relatorio_Mensal_${mesAno.replaceAll('-', '_')}.pdf',
    );
  }

  // Função auxiliar para criar tabelas estilizadas
  static pw.Widget _tabela(List<List<String>> dados) {
    return pw.Table.fromTextArray(
      headers: dados.first,
      data: dados.skip(1).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(color: subtituloCor),
      cellAlignment: pw.Alignment.center,
      cellStyle: const pw.TextStyle(fontSize: 10),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
    );
  }
}
