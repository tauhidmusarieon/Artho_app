import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

Future<File> generateAndSharePdf({
  required String title,
  required DateTime from,
  required DateTime to,
  required List<Map<String, dynamic>> rows,
  Uint8List? chartImage,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      build: (_) => [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          '${DateFormat('d MMM yyyy').format(from)} - '
          '${DateFormat('d MMM yyyy').format(to)}',
        ),
        pw.SizedBox(height: 12),

        if (chartImage != null)
          pw.Image(pw.MemoryImage(chartImage), height: 200),

        pw.SizedBox(height: 16),

        pw.Table.fromTextArray(
          headers: ['Title', 'Category', 'Amount', 'Type', 'Date'],
          data: rows.map((e) {
            return [
              e['title'],
              e['category'],
              e['amount'].toString(),
              e['type'],
              DateFormat('d MMM yyyy').format(e['date']),
            ];
          }).toList(),
        ),
      ],
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/${title.replaceAll(' ', '_')}.pdf');

  await file.writeAsBytes(await pdf.save());

  await Share.shareXFiles([XFile(file.path)], text: title);

  return file;
}


Future<File> generatePdfReport({
  required String title,
  required DateTime from,
  required DateTime to,
  required double income,
  required double expense,
  Uint8List? chartImage,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      build: (_) => [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          '${DateFormat('d MMM yyyy').format(from)}'
          ' - ${DateFormat('d MMM yyyy').format(to.subtract(const Duration(days: 1)))}',
        ),
        pw.SizedBox(height: 20),

        if (chartImage != null)
          pw.Image(pw.MemoryImage(chartImage), height: 220),

        pw.SizedBox(height: 20),
        pw.Text('Income: $income'),
        pw.Text('Expense: $expense'),
        pw.Text('Balance: ${income - expense}'),
      ],
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/${title.replaceAll(' ', '_')}.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}

Future<void> sharePdf(File file) async {
  await Share.shareXFiles([XFile(file.path)], text: 'Statistics Report');
}
