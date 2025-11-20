import '../Page/updatepage.dart';
import '../assets/transaction.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class ReadPage extends StatefulWidget {
  final ExpenseTransaction transaction;
  final Database database;

  const ReadPage({
    super.key,
    required this.transaction,
    required this.database,
  });

  @override
  State<ReadPage> createState() => _CreateReadPageState();
}

class _CreateReadPageState extends State<ReadPage> {
  Future<void> _deleteTransaction() async {
    await widget.database.delete(
      'expense',
      where: 'id = ?',
      whereArgs: [int.parse(widget.transaction.id)],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction deleted successfully')),
    );
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Detail')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      transaction.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.label, size: 20, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  transaction.category,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: transaction.isExpense
                    ? Colors.redAccent.withOpacity(0.06)
                    : Colors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: transaction.isExpense
                      ? Colors.redAccent.withOpacity(0.4)
                      : Colors.green.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: transaction.isExpense
                        ? Colors.redAccent
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(
                transaction.isExpense ? Icons.remove_circle : Icons.add_circle,
                color: transaction.isExpense ? Colors.redAccent : Colors.green,
              ),
              label: Text(transaction.isExpense ? 'Expense' : 'Income'),
              backgroundColor: transaction.isExpense
                  ? Colors.redAccent.withOpacity(0.12)
                  : Colors.green.withOpacity(0.12),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UpdateTransactionPage(transaction: transaction, database: widget.database),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _deleteTransaction,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
