import 'package:artho_app/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:artho_app/utils/chart_to_image.dart';
import 'package:artho_app/utils/pdf_report.dart';


class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTimeRange _todayRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return DateTimeRange(start: start, end: end);
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
            _TodayIncomeExpenseCard(
              service: service,
              range: _todayRange(),
            ),
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

/* ================= TODAY CATEGORY ================= */

class _TodayIncomeExpenseCard extends StatelessWidget {
  final FirestoreService service;
  final DateTimeRange range;

  const _TodayIncomeExpenseCard({required this.service, required this.range});

  @override
  Widget build(BuildContext context) {
    final chartKey = GlobalKey();
    final dateText = DateFormat('EEE, d MMM').format(range.start);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Report",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(dateText, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    final data = await service.getIncomeExpenseInRange(
                      range.start,
                      range.end,
                    );

                    final img = await captureChart(chartKey);

                    final file = await generatePdfReport(
                      title: 'Today Report',
                      from: range.start,
                      to: range.end,
                      income: data['income'] ?? 0,
                      expense: data['expense'] ?? 0,
                      chartImage: img,
                    );

                    await sharePdf(file);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            FutureBuilder<Map<String, double>>(
              future: service.getIncomeExpenseInRange(range.start, range.end),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final income = snapshot.data!['income'] ?? 0;
                final expense = snapshot.data!['expense'] ?? 0;

                if (income == 0 && expense == 0) {
                  return const Text('No transactions today');
                }

                return RepaintBoundary(
                  key: chartKey,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 40,
                        sections: [
                          if (income > 0)
                            PieChartSectionData(
                              value: income,
                              title: 'Income\n${income.toInt()}',
                              color: Colors.green,
                            ),
                          if (expense > 0)
                            PieChartSectionData(
                              value: expense,
                              title: 'Expense\n${expense.toInt()}',
                              color: Colors.red,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


/* ================= RANGE (WEEK / MONTH / YEAR) ================= */

class _RangeCard extends StatelessWidget {
  final String title;
  final DateTimeRange range;
  final FirestoreService service;

  _RangeCard({required this.title, required this.range, required this.service});

  final GlobalKey _chartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return _card(
      title: title,
      subtitle:
          '${DateFormat('d MMM').format(range.start)} - ${DateFormat('d MMM').format(range.end.subtract(const Duration(days: 1)))}',
      trailing: IconButton(
        icon: const Icon(Icons.download),
        onPressed: () async {
          final image = await captureChart(_chartKey);
          final data = await service.getTransactionsInRange(
            range.start,
            range.end,
          );

          await generateAndSharePdf(
            title: title,
            from: range.start,
            to: range.end,
            rows: data,
            chartImage: image,
          );
        },
      ),
      child: RepaintBoundary(
        key: _chartKey,
        child: FutureBuilder<Map<String, double>>(
          future: service.getIncomeExpenseInRange(range.start, range.end),
          builder: (_, s) {
            if (!s.hasData) {
              return const CircularProgressIndicator();
            }

            final inc = s.data!['income']!;
            final exp = s.data!['expense']!;

            if (inc == 0 && exp == 0) {
              return const Text('No data');
            }

            return PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sections: [
                  if (inc > 0)
                    PieChartSectionData(
                      value: inc,
                      title: 'Income\n${inc.toStringAsFixed(0)}',
                      color: Colors.green,
                    ),
                  if (exp > 0)
                    PieChartSectionData(
                      value: exp,
                      title: 'Expense\n${exp.toStringAsFixed(0)}',
                      color: Colors.red,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


/* ================= COMMON CARD ================= */

Widget _card({
  required String title,
  String? subtitle,
  Widget? trailing,
  required Widget child,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: Center(child: child)),
        ],
      ),
    ),
  );
}
