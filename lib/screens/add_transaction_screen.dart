import 'package:artho_app/models/transaction_model.dart';
import 'package:artho_app/services/firestore_service.dart';
import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();

  bool _isExpense = true;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  // Predefined categories (Bangladeshi context) - Rent added
  final List<String> _predefinedCategories = [
    'Food & Groceries',
    'Shopping',
    'Transport',
    'Bills & Utilities',
    'Medical',
    'Education',
    'Entertainment',
    'Rent', // Added Rent option
    'Other',
  ];

  // Selected category
  String _selectedCategory = 'Food & Groceries';
  bool _showCustomCategory = false;
  final TextEditingController _customCategoryController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = _predefinedCategories[0];
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    // If custom category is selected and has text, use it
    if (_showCustomCategory && _customCategoryController.text.isNotEmpty) {
      _selectedCategory = _customCategoryController.text.trim();
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final title = _titleController.text.trim();

      final newTransaction = TransactionModel(
        id: '',
        title: title,
        amount: amount,
        type: _isExpense ? 'expense' : 'income',
        date: _selectedDate,
        category: _selectedCategory,
      );

      await FirestoreService().addTransaction(newTransaction);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add transaction: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCategoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildCategoryModal(),
    );
  }

  Widget _buildCategoryModal() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Predefined categories grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: _predefinedCategories.length,
            itemBuilder: (context, index) {
              final category = _predefinedCategories[index];
              final isSelected = category == _selectedCategory;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _showCustomCategory = (category == 'Other');
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: isSelected ? Colors.blue : Colors.grey[700],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.blue : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Add safe area for bottom navigation
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Groceries':
        return Icons.restaurant;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Transport':
        return Icons.directions_car;
      case 'Bills & Utilities':
        return Icons.receipt;
      case 'Medical':
        return Icons.medical_services;
      case 'Education':
        return Icons.school;
      case 'Entertainment':
        return Icons.movie;
      case 'Rent': // Added Rent icon
        return Icons.home;
      case 'Other':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    // FIXED: Ensure bottomPadding is double
    final double bottomPadding = keyboardPadding > 0
        ? keyboardPadding + 16.0
        : 20.0;
    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(_selectedDate);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Container(
        padding: EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          top: 20.0,
          bottom: bottomPadding, // Now it's double
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Transaction',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: _isExpense,
                    onSelected: (_) => setState(() => _isExpense = true),
                    selectedColor: Colors.red.withOpacity(0.2),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: !_isExpense,
                    onSelected: (_) => setState(() => _isExpense = false),
                    selectedColor: Colors.green.withOpacity(0.2),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Coffee',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'e.g. 150',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(v) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Category Section - Your Image Style
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Category Button (like in your image)
              GestureDetector(
                onTap: () => _showCategoryModal(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(_selectedCategory),
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _selectedCategory,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              // Custom Category Field (only shows when "Other" is selected)
              if (_showCustomCategory) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Custom Category',
                    hintText: 'e.g. Investment, Gift, etc.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_showCustomCategory && (v == null || v.isEmpty)) {
                      return 'Please enter a category name';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formattedDate, style: const TextStyle(fontSize: 16)),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Transaction'),
              ),

              // Extra space at bottom to prevent overlap
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}
