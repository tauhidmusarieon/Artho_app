import 'package:artho_app/models/transaction_model.dart';
import 'package:artho_app/services/firestore_service.dart';
import 'package:artho_app/utils/chart_to_image.dart';
import 'package:artho_app/utils/pdf_report.dart';
import 'package:artho_app/utils/save_pdf_to_downloads.dart';
import 'package:artho_app/utils/share_pdf.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTimeRange _todayRange() {
    final start = _startOfToday();
    return DateTimeRange(start: start, end: start.add(const Duration(days: 1)));
  }

  DateTimeRange _weekRange() {
    final today = _startOfToday();
    return DateTimeRange(
      start: today.subtract(const Duration(days: 6)),
      end: today.add(const Duration(days: 1)),
    );
  }

  DateTimeRange _monthRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 1),
    );
  }

  DateTimeRange _yearRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year + 1, 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _TodayIncomeExpenseCard(service: service),
            _RangeCard(
              title: 'This Week',
              range: _weekRange(),
              service: service,
            ),
            _RangeCard(
              title: 'This Month',
              range: _monthRange(),
              service: service,
            ),
            _RangeCard(
              title: 'This Year',
              range: _yearRange(),
              service: service,
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= TODAY CARD ================= */

class _TodayIncomeExpenseCard extends StatelessWidget {
  final FirestoreService service;
  _TodayIncomeExpenseCard({required this.service});

  final GlobalKey _chartKey = GlobalKey();

  DateTimeRange _todayRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: start, end: start.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final range = _todayRange();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _header(
              context,
              title: "Today's Report",
              date: range,
              onDownload: () async {
                await _downloadPdf(
                  context: context,
                  title: "Today's Report",
                  range: range,
                );
              },
            ),
            const SizedBox(height: 16),
            _chart(range),
          ],
        ),
      ),
    );
  }

  Widget _chart(DateTimeRange range) {
    return FutureBuilder<Map<String, double>>(
      future: service.getIncomeExpenseInRange(range.start, range.end),
      builder: (_, s) {
        if (!s.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final income = s.data!['income'] ?? 0;
        final expense = s.data!['expense'] ?? 0;

        if (income == 0 && expense == 0) {
          return const Text('No transactions today');
        }

        return RepaintBoundary(
          key: _chartKey,
          child: SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sections: [
                  if (income > 0)
                    PieChartSectionData(
                      value: income,
                      color: Colors.green,
                      title: 'Income\n${income.toStringAsFixed(0)}',
                    ),
                  if (expense > 0)
                    PieChartSectionData(
                      value: expense,
                      color: Colors.red,
                      title: 'Expense\n${expense.toStringAsFixed(0)}',
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadPdf({
    required BuildContext context,
    required String title,
    required DateTimeRange range,
  }) async {
    // income / expense summary
    final summary = await service.getIncomeExpenseInRange(
      range.start,
      range.end,
    );

    //raw transactions (Map list)
    final rawTx = await service.getTransactionsInRange(range.start, range.end);

    //CONVERT  TransactionModel list 
    final List<TransactionModel> txList = rawTx
        .map((e) => TransactionModel.fromMap(e['data'], e['id']))
        .toList();

    //chart image
    final chartBytes = await captureChart(_chartKey);

    //generate pdf
    final pdf = await generatePdfReport(
      title: title,
      from: range.start,
      to: range.end,
      income: summary['income'] ?? 0,
      expense: summary['expense'] ?? 0,
      transactions: txList, //correct type now
      chartImage: chartBytes,
    );

    //save + share
    final saved = await savePdfToDownloads(pdf);
    await sharePdf(saved);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF saved to Downloads')));
    }
  }
}

/* ================= RANGE CARD ================= */

class _RangeCard extends StatelessWidget {
  final String title;
  final DateTimeRange range;
  final FirestoreService service;

  _RangeCard({required this.title, required this.range, required this.service});

  final GlobalKey _chartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _header(
              context,
              title: title,
              date: range,
              onDownload: () async {
                await _downloadPdf(context);
              },
            ),
            const SizedBox(height: 16),
            _chart(),
          ],
        ),
      ),
    );
  }

  Widget _chart() {
    return RepaintBoundary(
      key: _chartKey,
      child: FutureBuilder<Map<String, double>>(
        future: service.getIncomeExpenseInRange(range.start, range.end),
        builder: (_, s) {
          if (!s.hasData) return const CircularProgressIndicator();

          final inc = s.data!['income'] ?? 0;
          final exp = s.data!['expense'] ?? 0;

          if (inc == 0 && exp == 0) return const Text('No data');

          return SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sections: [
                  if (inc > 0)
                    PieChartSectionData(
                      value: inc,
                      color: Colors.green,
                      title: 'Income\n${inc.toStringAsFixed(0)}',
                    ),
                  if (exp > 0)
                    PieChartSectionData(
                      value: exp,
                      color: Colors.red,
                      title: 'Expense\n${exp.toStringAsFixed(0)}',
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final summary = await service.getIncomeExpenseInRange(
      range.start,
      range.end,
    );

    final rawTx = await service.getTransactionsInRange(range.start, range.end);

    final txList = rawTx
        .map((e) => TransactionModel.fromMap(e['data'], e['id']))
        .toList();


    final chartBytes = await captureChart(_chartKey);

    final pdf = await generatePdfReport(
      title: title,
      from: range.start,
      to: range.end,
      income: summary['income'] ?? 0,
      expense: summary['expense'] ?? 0,
      transactions: txList,
      chartImage: chartBytes,
    );

    final saved = await savePdfToDownloads(pdf);
    await sharePdf(saved);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF saved to Downloads')));
    }
  }
}

/* ================= HEADER WIDGET ================= */

Widget _header(
  BuildContext context, {
  required String title,
  required DateTimeRange date,
  required VoidCallback onDownload,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '${DateFormat('d MMM').format(date.start)} - ${DateFormat('d MMM').format(date.end.subtract(const Duration(days: 1)))}',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
      IconButton(icon: const Icon(Icons.download), onPressed: onDownload),
    ],
  );
}
