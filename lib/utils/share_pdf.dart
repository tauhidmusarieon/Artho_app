import 'dart:io';
import 'package:share_plus/share_plus.dart';

Future<void> sharePdf(File file) async {
  await Share.shareXFiles([XFile(file.path)], text: 'Expense Report');
}
