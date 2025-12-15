import 'package:intl/intl.dart';
import 'package:artho_app/services/firestore_service.dart';
import 'pdf_report.dart';

Future<void> generateAutoMonthlyReport(FirestoreService service) async {
  final now = DateTime.now();

  // this month range
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 1);

  final data = await service.getIncomeExpenseInRange(start, end);

  await generatePdfReport(
    title: 'Monthly Report ${DateFormat('MMM yyyy').format(now)}',
    from: start,
    to: end,
    income: data['income'] ?? 0,
    expense: data['expense'] ?? 0,
  );
}
