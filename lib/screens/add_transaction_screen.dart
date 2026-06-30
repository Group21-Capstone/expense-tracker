import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../core/theme.dart';
import '../core/categories.dart';

// A special result object returned when this screen pops, so the caller
// (home screen) knows whether the user saved or deleted the transaction.
class TransactionScreenResult {
  final Transaction? transaction; // non-null = save/edit
  final bool deleted;             // true = user tapped Delete

  const TransactionScreenResult({this.transaction, this.deleted = false});
}

// This screen handles both Adding a new transaction and Editing an existing one.
// If [transactionToEdit] is provided, the screen pre-fills the fields and
// shows a Delete button alongside the Save button.
class AddTransactionScreen extends StatefulWidget {
  final Transaction? transactionToEdit;

  const AddTransactionScreen({super.key, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = Categories.all.first;

  List<String> get _categories => Categories.all;

  @override
  void initState() {
    super.initState();
    // If editing, pre-fill all fields with the existing transaction's values.
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _titleController.text = t.title;
      _amountController.text = t.amount.toString();
      _notesController.text = t.notes ?? '';
      _selectedDate = t.date;
      _selectedType = t.type;
      _selectedCategory = t.category;
    }
  }

  @override
  void dispose() {
    // Always dispose controllers to free memory when the screen is removed.
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Validates the form and pops the screen with the new/updated transaction.
  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final enteredTitle = _titleController.text;
      final enteredAmount = double.parse(_amountController.text);

      if (enteredAmount <= 0) {
        return;
      }

      final newTransaction = Transaction(
        // Reuse the existing ID when editing, generate a new one when adding.
        id: widget.transactionToEdit?.id ?? const Uuid().v4(),
        title: enteredTitle,
        amount: enteredAmount,
        date: _selectedDate,
        category: _selectedCategory,
        type: _selectedType,
        notes: _notesController.text,
      );

      // Return the saved transaction wrapped in a result object.
      Navigator.of(context).pop(
        TransactionScreenResult(transaction: newTransaction),
      );
    }
  }

  // Shows a confirmation dialog before deleting, so the user can't
  // accidentally delete a transaction with a single tap.
  void _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text(
          'Are you sure you want to delete this transaction? This cannot be undone.',
        ),
        actions: [
          // Cancel — dismiss the dialog and do nothing.
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          // Confirm — return true to proceed with deletion.
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // If user confirmed, pop with a deleted result so the caller can call
    // TransactionService.deleteTransaction() with the transaction's ID.
    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop(
        const TransactionScreenResult(deleted: true),
      );
    }
  }

  // Opens the date picker and updates [_selectedDate] if the user picks one.
  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: now,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // True when editing an existing transaction — controls Delete button visibility.
    final isEditing = widget.transactionToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Transaction Type Toggle
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return _selectedType == TransactionType.expense
                            ? Colors.redAccent.withOpacity(0.2)
                            : Colors.greenAccent.withOpacity(0.2);
                      }
                      return Colors.transparent;
                    },
                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return _selectedType == TransactionType.expense
                            ? Colors.red
                            : Colors.green;
                      }
                      return Colors.grey;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount Input
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: _presentDatePicker,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    DateFormat.yMMMd().format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes Input
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Button row — Save always shown; Delete only shown when editing.
              Row(
                children: [
                  // Delete button — only visible when editing an existing transaction.
                  if (isEditing) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirmDelete,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // gap between the two buttons
                  ],

                  // Save button — always visible.
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save Transaction',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}