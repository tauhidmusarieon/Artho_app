import 'package:artho_app/models/transaction_model.dart';
import 'package:artho_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: StreamBuilder<List<TransactionModel>>(
        stream: service.streamTransactions(), // all, ordered by date desc
        builder: (c, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No transactions yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (c, i) {
              final m = items[i];
              final bool isIncome = m.type == 'income';
              final color = isIncome
                  ? const Color.fromRGBO(46, 204, 113, 1)
                  : const Color.fromRGBO(231, 76, 60, 1);
              final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;
              final amountText =
                  (isIncome ? '+' : '-') + m.amount.toStringAsFixed(0);
              final dateText = DateFormat('d MMM yyyy').format(m.date);

              return Dismissible(
                key: ValueKey(m.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete transaction?'),
                      content: Text(m.title),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return false;

                  try {
                    await service.deleteTransaction(m.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted')),
                      );
                    }
                    return true;
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete: $e')),
                      );
                    }
                    return false;
                  }
                },
                onDismissed: (_) {},
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.1),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    title: Text(
                      m.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    // match Home: date (and category small)
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateText, style: const TextStyle(fontSize: 12)),
                        if (m.category.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            m.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          amountText,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(context, m, service),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      backgroundColor: const Color(0xFFF7F7F7),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    TransactionModel m,
    FirestoreService service,
  ) async {
    final titleCtrl = TextEditingController(text: m.title);
    final amountCtrl = TextEditingController(text: m.amount.toStringAsFixed(0));
    final categoryCtrl = TextEditingController(text: m.category);
    String type = m.type;
    DateTime date = m.date;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: const Text('Edit Transaction'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Expense'),
                      selected: type == 'expense',
                      onSelected: (_) => setState(() => type = 'expense'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Income'),
                      selected: type == 'income',
                      onSelected: (_) => setState(() => type = 'income'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2010),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => date = d);
                  },
                  child: Text(DateFormat('EEE, d MMM yyyy').format(date)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete this transaction?'),
                    content: Text(m.title),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  try {
                    await service.deleteTransaction(m.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction deleted')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final updated = TransactionModel(
                  id: m.id,
                  title: titleCtrl.text.trim(),
                  amount: double.tryParse(amountCtrl.text) ?? m.amount,
                  type: type,
                  category: categoryCtrl.text.trim(),
                  date: date,
                );
                await service.updateTransaction(updated);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}


