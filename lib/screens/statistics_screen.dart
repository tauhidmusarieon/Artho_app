import 'package:artho_app/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // আজ + শেষ ৭ দিন (আজসহ)
  DateTimeRange _weekRange() {
    final startToday = _startOfToday();
    final from = startToday.subtract(const Duration(days: 6));
    final to = startToday.add(const Duration(days: 1));
    return DateTimeRange(start: from, end: to);
  }

  DateTimeRange _monthRange() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 1);
    return DateTimeRange(start: from, end: to);
  }

  DateTimeRange _yearRange() {
    final now = DateTime.now();
    final from = DateTime(now.year, 1, 1);
    final to = DateTime(now.year + 1, 1, 1);
    return DateTimeRange(start: from, end: to);
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final today = _startOfToday();
    final weekRange = _weekRange();
    final monthRange = _monthRange();
    final yearRange = _yearRange();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      backgroundColor: const Color.fromRGBO(253, 249, 246, 1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1) TODAY – category wise expense
            _TodayCategoryChartCard(service: service, date: today),
            const SizedBox(height: 16),

            // 2) WEEK – income vs expense
            _RangeIncomeExpenseCard(
              title: 'This Week',
              service: service,
              from: weekRange.start,
              to: weekRange.end,
            ),
            const SizedBox(height: 16),

            // 3) MONTH – income vs expense
            _RangeIncomeExpenseCard(
              title: 'This Month',
              service: service,
              from: monthRange.start,
              to: monthRange.end,
            ),
            const SizedBox(height: 16),

            // 4) YEAR – income vs expense
            _RangeIncomeExpenseCard(
              title: 'This Year',
              service: service,
              from: yearRange.start,
              to: yearRange.end,
            ),
          ],
        ),
      ),
    );
  }
}

/// TODAY: category-wise expense pie chart
class _TodayCategoryChartCard extends StatelessWidget {
  final FirestoreService service;
  final DateTime date;

  const _TodayCategoryChartCard({required this.service, required this.date});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('EEE, d MMM').format(date);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Today's Expenses by Category",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              formatted,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, double>>(
              future: service.getTodayExpenseByCategory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox(
                    height: 80,
                    child: Center(child: Text('No expenses today.')),
                  );
                }

                final data = snapshot.data!;
                final total = data.values.fold<double>(0.0, (a, b) => a + b);

                final colors = <Color>[
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.red,
                  Colors.teal,
                  Colors.brown,
                ];

                final List<PieChartSectionData> sections = [];
                var index = 0;
                data.forEach((category, value) {
                  final percent = (value / total * 100).toStringAsFixed(1);
                  sections.add(
                    PieChartSectionData(
                      value: value,
                      title: '$percent%',
                      radius: 55,
                      color: colors[index % colors.length],
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                  index++;
                });

                return Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ছোট legend
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: data.entries.map((e) {
                        final i = data.keys.toList().indexOf(e.key);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors[i % colors.length],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${e.key} (${e.value.toStringAsFixed(0)})',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// WEEK / MONTH / YEAR: income vs expense pie chart
class _RangeIncomeExpenseCard extends StatelessWidget {
  final String title;
  final FirestoreService service;
  final DateTime from;
  final DateTime to;

  const _RangeIncomeExpenseCard({
    required this.title,
    required this.service,
    required this.from,
    required this.to,
  });

  @override
  Widget build(BuildContext context) {
    final rangeText =
        '${DateFormat('d MMM').format(from)} – ${DateFormat('d MMM').format(to.subtract(const Duration(days: 1)))}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              rangeText,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, double>>(
              future: service.getIncomeExpenseInRange(from, to),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 80,
                    child: Center(child: Text('No data.')),
                  );
                }

                final data = snapshot.data!;
                final income = data['income'] ?? 0.0;
                final expense = data['expense'] ?? 0.0;

                if (income == 0 && expense == 0) {
                  return const SizedBox(
                    height: 80,
                    child: Center(
                      child: Text('No transactions in this range.'),
                    ),
                  );
                }

                final List<PieChartSectionData> sections = [];
                if (income > 0) {
                  sections.add(
                    PieChartSectionData(
                      value: income,
                      title: 'Income\n${income.toStringAsFixed(0)}',
                      color: Colors.green,
                      radius: 55,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                if (expense > 0) {
                  sections.add(
                    PieChartSectionData(
                      value: expense,
                      title: 'Expense\n${expense.toStringAsFixed(0)}',
                      color: Colors.red,
                      radius: 55,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
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


