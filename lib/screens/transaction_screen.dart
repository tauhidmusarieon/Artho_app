import 'package:artho_app/models/transaction_model.dart';
import 'package:artho_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  // Move predefinedCategories to class level
  static const List<String> _predefinedCategories = [
    'Food & Groceries',
    'Shopping',
    'Transport',
    'Bills & Utilities',
    'Medical',
    'Education',
    'Entertainment',
    'Rent',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('All Transactions')),
      body: StreamBuilder<List<TransactionModel>>(
        stream: service.streamTransactions(),
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
                      backgroundColor: color.withAlpha(20),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    title: Text(
                      m.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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

    // Determine initial state
    final bool isCustomCategory =
        m.category == 'Other' || !_predefinedCategories.contains(m.category);

    final categoryCtrl = TextEditingController(
      text: isCustomCategory ? m.category : '',
    );

    String type = m.type;
    DateTime date = m.date;

    // Determine initial dropdown value
    String dropdownValue = isCustomCategory ? 'Other' : m.category;
    bool showCustomCategory = isCustomCategory;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: const Text('Edit Transaction'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Category Section
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Category Dropdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dropdownValue,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: _predefinedCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            dropdownValue = newValue;
                            if (newValue == 'Other') {
                              showCustomCategory = true;
                            } else {
                              showCustomCategory = false;
                              categoryCtrl.clear();
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),

                // Custom Category Field
                if (showCustomCategory) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: categoryCtrl,
                    decoration: InputDecoration(
                      labelText: 'Custom Category',
                      border: const OutlineInputBorder(),
                      // Set hint text based on existing value
                      hintText: isCustomCategory && m.category != 'Other'
                          ? m.category
                          : 'e.g. Investment, Gift, etc.',
                    ),
                  ),
                ],

                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                // Determine final category
                String finalCategory;

                if (dropdownValue == 'Other') {
                  if (categoryCtrl.text.trim().isNotEmpty) {
                    finalCategory = categoryCtrl.text.trim();
                  } else if (isCustomCategory && m.category != 'Other') {
                    // Keep existing custom category if no new input
                    finalCategory = m.category;
                  } else {
                    finalCategory = 'Other';
                  }
                } else {
                  finalCategory = dropdownValue;
                }

                final updated = TransactionModel(
                  id: m.id,
                  title: titleCtrl.text.trim(),
                  amount: double.tryParse(amountCtrl.text) ?? m.amount,
                  type: type,
                  category: finalCategory,
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
