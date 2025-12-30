import 'package:artho_app/models/transaction_model.dart';
import 'package:artho_app/services/firestore_service.dart';
import 'package:artho_app/utils/pdf_report.dart';
import 'package:share_plus/share_plus.dart';

Future<void> generateAutoMonthlyReport(FirestoreService service) async {
  final now = DateTime.now();

  // last month range
  final from = DateTime(now.year, now.month - 1, 1);
  final to = DateTime(now.year, now.month, 1);

  // income & expense
  final summary = await service.getIncomeExpenseInRange(from, to);
  final income = summary['income'] ?? 0.0;
  final expense = summary['expense'] ?? 0.0;

  if (income == 0 && expense == 0) return;

  // RAW TRANSACTIONS
  final rawTx = await service.getTransactionsInRange(from, to);

  // CONVERT → TransactionModel
  final transactions = rawTx
      .map((e) => TransactionModel.fromMap(e['data'], e['id']))
      .toList();

  // GENERATE PDF
  final pdf = await generatePdfReport(
    title: 'Monthly Report',
    from: from,
    to: to,
    income: income,
    expense: expense,
    transactions: transactions,
  );

  // SHARE
  await Share.shareXFiles([
    XFile(pdf.path),
  ], text: 'Artho Monthly Expense Report');
}
