import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';

Future<File> generatePdfReport({
  required String title,
  required DateTime from,
  required DateTime to,
  required double income,
  required double expense,
  required List<TransactionModel> transactions,
  Uint8List? chartImage,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          '${DateFormat('d MMM yyyy').format(from)} - ${DateFormat('d MMM yyyy').format(to)}',
        ),

        pw.SizedBox(height: 12),
        pw.Text('Income: $income'),
        pw.Text('Expense: $expense'),
        pw.Text('Balance: ${income - expense}'),

        if (chartImage != null) ...[
          pw.SizedBox(height: 20),
          pw.Image(pw.MemoryImage(chartImage), height: 200),
        ],

        pw.SizedBox(height: 20),
        pw.Text(
          'Transactions',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),

        pw.Table.fromTextArray(
          headers: ['Title', 'Amount', 'Type', 'Date'],
          data: transactions
              .map(
                (t) => [
                  t.title,
                  t.amount.toString(),
                  t.type,
                  DateFormat('d MMM').format(t.date),
                ],
              )
              .toList(),
        ),
      ],
    ),
  );

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${title.replaceAll(' ', '_')}.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}
