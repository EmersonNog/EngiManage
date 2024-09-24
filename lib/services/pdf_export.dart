// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class PDFExporter {
  static Future<bool> exportToPDF(
      List<QueryDocumentSnapshot> obras, BuildContext context) async {
    void showErrorSnackBar(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }

    try {
      final pdf = pw.Document();
      final NumberFormat currencyFormat = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      );

      final ByteData headerBytes =
          await rootBundle.load('assets/pdf/header.png');
      final Uint8List headerImageBytes = headerBytes.buffer.asUint8List();
      final pw.MemoryImage headerImage = pw.MemoryImage(headerImageBytes);

      final ByteData footerBytes =
          await rootBundle.load('assets/pdf/footer.png');
      final Uint8List footerImageBytes = footerBytes.buffer.asUint8List();
      final pw.MemoryImage footerImage = pw.MemoryImage(footerImageBytes);

      pw.Widget buildHeader() {
        return pw.Column(
          children: [
            pw.Image(
              headerImage,
            ),
            pw.SizedBox(height: 20)
          ],
        );
      }

      pw.Widget buildFooter() {
        return pw.Column(
          children: [
            pw.SizedBox(height: 5),
            pw.Image(
              footerImage,
            ),
          ],
        );
      }

      Future<Map<String, dynamic>> fetchWorkDetails(
          List<QueryDocumentSnapshot> obras) async {
        try {
          int totalDiasExecutados = 0;
          int totalDiasParalisados = 0;
          double totalRepercussao = 0.0;
          double totalPagamentos = 0.0;
          double totalReajustes = 0.0;
          DateTime? dataTerminoInicial;
          double valorContratual = 0.0;

          final dateFormat = DateFormat('dd/MM/yyyy');

          // Itera sobre cada obra
          for (var obra in obras) {
            final data = obra.data() as Map<String, dynamic>?;

            if (data != null) {
              final prazosAditados = data['prazos_aditados'] as List<dynamic>?;

              // Itera sobre cada aditivo de prazo
              prazosAditados?.forEach((item) {
                final diasExecutados =
                    int.tryParse(item['dias_executados']?.toString() ?? '0') ??
                        0;
                final diasParalisados =
                    int.tryParse(item['dias_paralisados']?.toString() ?? '0') ??
                        0;
                final repercussao =
                    double.tryParse(item['repercussao']?.toString() ?? '0') ??
                        0.0;

                totalDiasExecutados += diasExecutados;
                totalDiasParalisados += diasParalisados;
                totalRepercussao += repercussao;
              });

              // Somar valores de pagamentos
              final pagamentos = data['pagamentos'] as List<dynamic>?;

              if (pagamentos != null) {
                pagamentos.forEach((pagamento) {
                  final valorPagamento =
                      double.tryParse(pagamento['valor']?.toString() ?? '0') ??
                          0.0;
                  totalPagamentos += valorPagamento;
                });
              }

              // Somar valores de reajustes
              final reajustes = data['reajuste'] as List<dynamic>?;

              if (reajustes != null) {
                reajustes.forEach((reajuste) {
                  final valorReajuste =
                      double.tryParse(reajuste['valor']?.toString() ?? '0') ??
                          0.0;
                  totalReajustes += valorReajuste;
                });
              }

              final contrato = data['contrato'] as Map<String, dynamic>?;

              final valorContratualString =
                  contrato?['valor_inicial_contrato']?.toString();
              valorContratual =
                  double.tryParse(valorContratualString ?? '0') ?? 0.0;

              final dataTerminoString =
                  contrato?['data_termino_inicial']?.toString();
              if (dataTerminoString != null) {
                try {
                  dataTerminoInicial = dateFormat.parse(dataTerminoString);
                } catch (e) {
                  print('Error parsing date: $e');
                  dataTerminoInicial = null;
                }
              }
            }
          }

          final fimPrevisto = dataTerminoInicial != null
              ? dataTerminoInicial.add(
                  Duration(days: totalDiasExecutados + totalDiasParalisados))
              : null;

          final valorAtual = valorContratual + totalRepercussao;
          final valorMedido = totalPagamentos;
          final saldoObra = valorContratual + totalRepercussao - valorMedido;
          double porcentagemConcluida =
              valorAtual > 0 ? (totalPagamentos / valorAtual) * 100 : 0.0;

          if (porcentagemConcluida > 100) {
            porcentagemConcluida = 100;
          }

          return {
            'totalDiasExecutados': totalDiasExecutados,
            'totalDiasParalisados': totalDiasParalisados,
            'totalRepercussao': totalRepercussao.toStringAsFixed(2),
            'valorContratual': valorContratual.toStringAsFixed(2),
            'valorAtual': valorAtual.toStringAsFixed(2),
            'fimPrevisto': fimPrevisto != null
                ? DateFormat('dd/MM/yyyy').format(fimPrevisto)
                : 'Data não disponível',
            'totalPagamentos': totalPagamentos.toStringAsFixed(2),
            'totalReajustes': totalReajustes.toStringAsFixed(2),
            'valorMedido': valorMedido.toStringAsFixed(2),
            'saldoObra': saldoObra.toStringAsFixed(2),
            'porcentagemConcluida':
                '${porcentagemConcluida.toStringAsFixed(2)}%',
          };
        } catch (e) {
          print('Error fetching work details: $e');
          return {
            'totalDiasExecutados': 0,
            'totalDiasParalisados': 0,
            'totalRepercussao': '0.00',
            'valorContratual': '0.00',
            'valorAtual': '0.00',
            'fimPrevisto': 'Data não disponível',
            'totalPagamentos': '0.00',
            'totalReajustes': '0.00',
            'valorMedido': '0.00',
            'saldoObra': '0.00',
            'porcentagemConcluida': '0%',
          };
        }
      }

      // Obter a soma dos dias executados, paralisados e a data de fim previsto antes de adicionar a página
      final workDetails = await fetchWorkDetails(obras);

      // Página 0: Página inicial com texto, data de início real, soma dos dias executados, paralisados e fim previsto
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) => buildHeader(),
          footer: (pw.Context context) => buildFooter(),
          build: (pw.Context context) {
            final obra = obras.isNotEmpty ? obras[0] : null;
            final dataInicioReal =
                obra?['contrato']['data_inicio_real']?.toString() ??
                    'Data não disponível';
            final fiscalContrato =
                obra?['contrato']['fiscal_contrato']?.toString() ??
                    'Fiscal não disponível';
            final supervisor =
                obra?['contrato']['fiscal_consorcio']?.toString() ??
                    'Supervisor não disponível';
            final prazoInicial =
                obra?['contrato']['prazo_inicial_execucao']?.toString() ??
                    'Prazo inicial não disponível';
            final statusObra = obra?['contrato']['status_obra']?.toString() ??
                'Status não disponível';
            final objetoContrato =
                obra?['contrato']['objeto_contrato']?.toString() ??
                    'Objeto não disponível';
            final numContrato =
                obra?['num_contrato']?.toString() ?? 'Número não disponível';
            final ordemServico =
                obra?['contrato']['ordem_servico']?.toString() ??
                    'Ordem não disponível';
            final contratada = obra?['contrato']['contratada']?.toString() ??
                'Contratada não disponível';
            final valorContratual = workDetails['valorContratual'];
            final valorContratualFormatado =
                currencyFormat.format(double.tryParse(valorContratual) ?? 0);
            final valorAtual = workDetails['valorAtual'];
            final valorAtualFormatado =
                currencyFormat.format(double.tryParse(valorAtual) ?? 0);
            final valorMedido = workDetails['valorMedido'];
            final valorMedidoFormatado =
                currencyFormat.format(double.tryParse(valorMedido) ?? 0);
            final saldoObra = workDetails['saldoObra'];
            final saldoObraFormatado = (double.tryParse(saldoObra) ?? 0) < 0
                ? '0.00'
                : currencyFormat.format(double.tryParse(saldoObra) ?? 0);
            final diasAditados = workDetails['totalDiasExecutados'];
            final diasParalisados = workDetails['totalDiasParalisados'];
            final fimPrevisto = workDetails['fimPrevisto'];
            final porcentagemConcluida = workDetails['porcentagemConcluida'];
            final valorAditivado = workDetails['totalRepercussao'];
            final valorAditivadoFormatado =
                currencyFormat.format(double.tryParse(valorAditivado) ?? 0);
            final valorReajustado = workDetails['totalReajustes'];
            final valorReajustadoFormatado =
                currencyFormat.format(double.tryParse(valorReajustado) ?? 0);

            String formattedDate =
                DateFormat('dd/MM/yyyy').format(DateTime.now());

            return [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "Relatório de Contrato",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      formattedDate,
                      style: const pw.TextStyle(
                        fontSize: 15,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      children: [
                        pw.Text(
                          "INFORMAÇÕES GERAIS DO CONTRATO",
                        ),
                      ],
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(
                          width: 1.0, color: PdfColors.black),
                      children: [
                        pw.TableRow(
                          children: [
                            buildContratoTableCell(
                                'OBJETO DO CONTRATO', objetoContrato),
                          ],
                        ),
                      ],
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(
                          width: 1.0, color: PdfColors.black),
                      children: [
                        pw.TableRow(children: [
                          buildContratoTableCell(
                              'NÚM. DO CONTRATO', numContrato),
                          buildContratoTableCell(
                              'ORDEM DO SERVIÇO', ordemServico),
                          buildContratoTableCell(
                              'EMPRESA CONTRATADA', contratada),
                        ])
                      ],
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(
                          width: 1.0, color: PdfColors.black),
                      children: [
                        pw.TableRow(children: [
                          buildContratoTableCell(
                              'PERCENTUAL DE OBRA', porcentagemConcluida),
                        ])
                      ],
                    ),
                    pw.SizedBox(height: 15),
                    pw.Row(
                      children: [
                        pw.Text(
                          "RESUMO FINANCEIRO DA OBRA",
                        ),
                      ],
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(
                          width: 1.0, color: PdfColors.black),
                      children: [
                        pw.TableRow(
                          children: [
                            buildContratoTableCell(
                                'VALOR MEDIDO', valorMedidoFormatado),
                            buildContratoTableCell(
                                'SALDO DE OBRA', saldoObraFormatado),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 15),
                    pw.Row(
                      children: [
                        pw.Text(
                          "DATAS",
                        ),
                        pw.Padding(
                          padding:
                              const pw.EdgeInsets.only(left: 193, bottom: 2),
                          child: pw.Text(
                            "VALORES",
                          ),
                        )
                      ],
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(
                        width: 1.0,
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.TableRow(
                          children: [
                            buildContratoTableCell(
                                'INICIO REAL', dataInicioReal),
                            buildContratoTableCell(
                                'VALOR CONTRATUAL', valorContratualFormatado),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            buildContratoTableCell(
                                'PRAZO INICIAL', prazoInicial),
                            buildContratoTableCell(
                                'VALOR ADITIVADO', valorAditivadoFormatado),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            buildContratoTableCell(
                                'DIAS ADITADOS', '$diasAditados'),
                            buildContratoTableCell(
                                'VALOR REAJUSTADO', valorReajustadoFormatado),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            buildContratoTableCell(
                                'DIAS PARALISADOS', '$diasParalisados'),
                            buildContratoTableCell(
                                'VALOR ATUAL', valorAtualFormatado),
                          ],
                        ),
                        pw.TableRow(
                          children: [
                            buildContratoTableCell(
                                'FIM PREVISTO', '$fimPrevisto'),
                            buildContratoTableCell(
                                'STATUS DA OBRA', statusObra),
                          ],
                        ),
                      ],
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(
                        width: 1.0,
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.TableRow(
                          children: [
                            buildContratoTableCell(
                                'FISCAL DE OBRA', fiscalContrato),
                          ],
                        ),
                      ],
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(
                        width: 1.0,
                        color: PdfColors.black,
                      ),
                      children: [
                        pw.TableRow(
                          children: [
                            buildContratoTableCell('SUPERVISOR', supervisor),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );

      // Página 1: Tabela de prazos aditados
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) => buildHeader(),
          footer: (pw.Context context) => buildFooter(),
          build: (pw.Context context) {
            List<List<String>> prazoTableRows = [];

            obras.forEach((obra) {
              final prazosAditados = obra['prazos_aditados'] as List<dynamic>?;

              prazosAditados?.forEach((item) {
                prazoTableRows.add([
                  item['tipo']?.toString() ?? 'N/A',
                  item['data_assinatura']?.toString() ?? 'N/A',
                  item['data_publicacao']?.toString() ?? 'N/A',
                  currencyFormat.format(
                    double.tryParse(item['acrescimo']?.toString() ?? '0') ?? 0,
                  ),
                  currencyFormat.format(
                    double.tryParse(item['supressao']?.toString() ?? '0') ?? 0,
                  ),
                  currencyFormat.format(
                    double.tryParse(item['repercussao']?.toString() ?? '0') ??
                        0,
                  ),
                  item['dias_vigencia']?.toString() ?? '0',
                  item['dias_executados']?.toString() ?? '0',
                ]);
              });
            });

            return [
              pw.Header(level: 0, text: 'Aditivos do Contrato'),
              pw.Table.fromTextArray(
                headers: [
                  'TIPO',
                  'DT. DE ASS.',
                  'DT. DE PUB.',
                  'ACRÉSCIMO',
                  'SUPRESSÃO',
                  'REPERC.',
                  'VIGÊNCIA',
                  'EXECUÇÃO'
                ],
                data: prazoTableRows,
                cellAlignment: pw.Alignment.center,
                headerAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(35),
                  1: const pw.FlexColumnWidth(80),
                  2: const pw.FlexColumnWidth(80),
                  3: const pw.FlexColumnWidth(90),
                  4: const pw.FlexColumnWidth(100),
                  5: const pw.FlexColumnWidth(100),
                  6: const pw.FlexColumnWidth(80),
                  7: const pw.FlexColumnWidth(90),
                },
                headerCellDecoration:
                    pw.BoxDecoration(color: PdfColor.fromHex("D3D3D3")),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
              ),
            ];
          },
        ),
      );

      // Página 2: Tabela de histórico
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          header: (pw.Context context) => buildHeader(),
          footer: (pw.Context context) => buildFooter(),
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, text: 'Histórico de Medições'),
              pw.Table.fromTextArray(
                headers: ['Data', 'Cronograma', 'Pagamento'],
                data: obras
                    .map((obra) {
                      final cronograma = obra['cronograma'] as List<dynamic>?;
                      final pagamentos = obra['pagamentos'] as List<dynamic>?;

                      List<List<String>> tableRows = [];

                      double parseToDouble(String value) {
                        return double.tryParse(value) ?? 0;
                      }

                      cronograma?.forEach((itemCronograma) {
                        final dataCronograma =
                            itemCronograma['data']?.toString() ?? 'Sem data';
                        final cronogramaValor = currencyFormat.format(
                            parseToDouble(
                                itemCronograma['valor']?.toString() ?? '0'));

                        final matchingPagamento = pagamentos?.firstWhere(
                          (itemPagamento) =>
                              itemPagamento['data'] == dataCronograma,
                          orElse: () => null,
                        );

                        if (matchingPagamento != null) {
                          final pagamentoValor = currencyFormat.format(
                              parseToDouble(
                                  matchingPagamento['valor']?.toString() ??
                                      '0'));
                          tableRows.add([
                            dataCronograma,
                            cronogramaValor,
                            pagamentoValor
                          ]);
                        } else {
                          tableRows.add(
                              [dataCronograma, cronogramaValor, 'R\$ 0,00']);
                        }
                      });

                      pagamentos?.forEach((itemPagamento) {
                        final dataPagamento =
                            itemPagamento['data']?.toString() ?? 'Sem data';
                        final pagamentoValor = currencyFormat.format(
                            parseToDouble(
                                itemPagamento['valor']?.toString() ?? '0'));

                        final alreadyInTable =
                            tableRows.any((row) => row[0] == dataPagamento);

                        if (!alreadyInTable) {
                          tableRows
                              .add([dataPagamento, 'R\$ 0,00', pagamentoValor]);
                        }
                      });

                      return tableRows;
                    })
                    .expand((element) => element)
                    .toList(),
                cellAlignment: pw.Alignment.center,
                columnWidths: {
                  0: const pw.FixedColumnWidth(100),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FlexColumnWidth(),
                },
                headerCellDecoration:
                    pw.BoxDecoration(color: PdfColor.fromHex("D3D3D3")),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
              ),
            ];
          },
        ),
      );

      // Página 3: Tabela de quantitativos
      if (obras
          .any((obra) => obra['contrato']['tipo_obra'] != "CONSTRUÇÃO CIVIL")) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            header: (pw.Context context) => buildHeader(),
            footer: (pw.Context context) => buildFooter(),
            build: (pw.Context context) {
              List<List<String>> quantitativesTableRows = [];

              obras.forEach((obra) {
                final tipoObra = obra['contrato']['tipo_obra']?.toString();
                final quantitatives = obra['quantitatives'] as List<dynamic>?;

                if (tipoObra == "SISTEMA DE ESGOTAMENTO SANITÁRIO") {
                  double totalRamalPedrial = 0;
                  double totalImoveisLigados = 0;
                  double totalRedeEsgoto = 0;
                  double totalPisoIntertravado = 0;
                  double totalPisoPedraTosca = 0;
                  double totalPavimentacaoAsfaltica = 0;
                  double totalEstacaoElevatoria = 0;
                  double totalEstacaoTratamento = 0;

                  quantitatives?.forEach((quantitative) {
                    totalRamalPedrial += double.tryParse(
                            quantitative['ramal_pedrial']?.toString() ?? '0') ??
                        0;
                    totalImoveisLigados += double.tryParse(
                            quantitative['imoveis_ligados']?.toString() ??
                                '0') ??
                        0;
                    totalRedeEsgoto += double.tryParse(
                            quantitative['rede_esgoto']?.toString() ?? '0') ??
                        0;
                    totalPisoIntertravado += double.tryParse(
                            quantitative['piso_intertravado']?.toString() ??
                                '0') ??
                        0;
                    totalPisoPedraTosca += double.tryParse(
                            quantitative['piso_pedra_tosca']?.toString() ??
                                '0') ??
                        0;
                    totalPavimentacaoAsfaltica += double.tryParse(
                            quantitative['pavimentacao_asfaltica']
                                    ?.toString() ??
                                '0') ??
                        0;
                    totalEstacaoElevatoria += double.tryParse(
                            quantitative['estacao_elevatoria']?.toString() ??
                                '0') ??
                        0;
                    totalEstacaoTratamento += double.tryParse(
                            quantitative['estacao_tratamento']?.toString() ??
                                '0') ??
                        0;
                  });

                  if (totalRamalPedrial >= 0) {
                    quantitativesTableRows.add([
                      'Ramal Pedrial',
                      '${totalRamalPedrial.toStringAsFixed(0)} unid'
                    ]);
                  }
                  if (totalImoveisLigados >= 0) {
                    quantitativesTableRows.add([
                      'Imóveis Ligados',
                      '${totalImoveisLigados.toStringAsFixed(0)} unid'
                    ]);
                  }
                  if (totalEstacaoElevatoria >= 0) {
                    quantitativesTableRows.add([
                      'Estação Elevatória de Esgoto',
                      '${totalEstacaoElevatoria.toStringAsFixed(0)} unid'
                    ]);
                  }
                  if (totalEstacaoTratamento >= 0) {
                    quantitativesTableRows.add([
                      'Estação de Tratamento de Esgoto',
                      '${totalEstacaoTratamento.toStringAsFixed(0)} unid'
                    ]);
                  }
                  if (totalRedeEsgoto >= 0) {
                    quantitativesTableRows.add([
                      'Rede de Esgoto',
                      '${totalRedeEsgoto.toStringAsFixed(2)} m'
                    ]);
                  }
                  if (totalPisoIntertravado >= 0) {
                    quantitativesTableRows.add([
                      'Piso Intertravado',
                      '${totalPisoIntertravado.toStringAsFixed(2)} m²'
                    ]);
                  }
                  if (totalPisoPedraTosca >= 0) {
                    quantitativesTableRows.add([
                      'Piso de Pedra Tosca',
                      '${totalPisoPedraTosca.toStringAsFixed(2)} m²'
                    ]);
                  }
                  if (totalPavimentacaoAsfaltica >= 0) {
                    quantitativesTableRows.add([
                      'Pavimentação Asfáltica',
                      '${totalPavimentacaoAsfaltica.toStringAsFixed(2)} m²'
                    ]);
                  }
                } else if (tipoObra == "DRENAGEM PLUVIAL") {
                  double totalTubo = 0;
                  double totalGaleria = 0;
                  double totalPisoIntertravado = 0;
                  double totalPisoPedraTosca = 0;
                  double totalPavimentacaoAsfaltica = 0;

                  quantitatives?.forEach((quantitative) {
                    totalTubo += double.tryParse(
                            quantitative['tubo']?.toString() ?? '0') ??
                        0;
                    totalGaleria += double.tryParse(
                            quantitative['galeria']?.toString() ?? '0') ??
                        0;
                    totalPisoIntertravado += double.tryParse(
                            quantitative['piso_intertravado']?.toString() ??
                                '0') ??
                        0;
                    totalPisoPedraTosca += double.tryParse(
                            quantitative['piso_pedra_tosca']?.toString() ??
                                '0') ??
                        0;
                    totalPavimentacaoAsfaltica += double.tryParse(
                            quantitative['pavimentacao_asfaltica']
                                    ?.toString() ??
                                '0') ??
                        0;
                  });

                  if (totalTubo >= 0) {
                    quantitativesTableRows
                        .add(['Tubo', '${totalTubo.toStringAsFixed(2)} m']);
                  }
                  if (totalGaleria >= 0) {
                    quantitativesTableRows.add(
                        ['Galeria', '${totalGaleria.toStringAsFixed(2)} m']);
                  }
                  if (totalPisoIntertravado >= 0) {
                    quantitativesTableRows.add([
                      'Piso Intertravado',
                      '${totalPisoIntertravado.toStringAsFixed(2)} m²'
                    ]);
                  }
                  if (totalPisoPedraTosca >= 0) {
                    quantitativesTableRows.add([
                      'Piso de Pedra Tosca',
                      '${totalPisoPedraTosca.toStringAsFixed(2)} m²'
                    ]);
                  }
                  if (totalPavimentacaoAsfaltica >= 0) {
                    quantitativesTableRows.add([
                      'Pavimentação Asfáltica',
                      '${totalPavimentacaoAsfaltica.toStringAsFixed(2)} m²'
                    ]);
                  }
                }
              });

              return [
                pw.Header(level: 0, text: 'Quantitativos'),
                pw.Table.fromTextArray(
                  headers: ['ITEM', 'QUANTIDADE'],
                  data: quantitativesTableRows,
                  cellAlignment: pw.Alignment.center,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                  },
                  headerCellDecoration:
                      pw.BoxDecoration(color: PdfColor.fromHex("D3D3D3")),
                  headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                ),
              ];
            },
          ),
        );
      }

      final pdfBytes = await pdf.save();

      final outputFile = await _createTempFile();
      await outputFile.writeAsBytes(pdfBytes);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'document.pdf',
      );

      return true;
    } catch (e) {
      final errorString = e.toString();

      if (errorString
          .contains('Bad state: field "pagamentos" does not exist')) {
        showErrorSnackBar(context, 'Obra sem registro de pagamentos!');
      } else if (errorString
          .contains('Bad state: field "prazos_aditados" does not exist')) {
        showErrorSnackBar(context, 'Obra sem registro de prazos aditados!');
      } else {
        showErrorSnackBar(context, 'Erro ao exportar para PDF: $errorString');
      }
      return false;
    }
  }

  static Future<File> _createTempFile() async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/document.pdf';
    return File(path);
  }

  static pw.Widget buildContratoTableCell(String label, String objetoContrato) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label:\n',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: objetoContrato,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
