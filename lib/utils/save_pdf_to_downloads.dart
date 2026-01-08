import 'dart:io';

Future<File> savePdfToDownloads(File pdf) async {
  final dir = Directory('/storage/emulated/0/Download');

  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final file = File('${dir.path}/${pdf.path.split('/').last}');
  return pdf.copy(file.path);
}
