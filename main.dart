import '../Page/createpage.dart';
import '../Page/readpage.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../assets/transaction.dart';
import '../assets/constant.dart';

void main() {
  runApp(const SmartSpendApp());
}

class SmartSpendApp extends StatelessWidget {
  const SmartSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSpend - Personal Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Database? _db;
  List<ExpenseTransaction> _transactions = [];
  String _groupBy = 'All';
  // Filter state
  DateTime? _filterStart;
  DateTime? _filterEnd;
  String _filterType = 'All'; // All, Income, Expense
  String _filterCategory = 'All';

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

Future<void> _initDatabase() async {
  // Get the database folder path
  String dbFolder = await getDatabasesPath();
  String dbPath = '$dbFolder/contacts_map.db'; // no path package needed

  // Delete old database for testing
  await deleteDatabase(dbPath);

  _db = await openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, version) async {
      // Create table
      await db.execute('''
        CREATE TABLE expense (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          amount REAL,
          date TEXT,
          isExpense INTEGER,
          category TEXT
        )
      ''');

      // Insert dummy data
      final dummyTransactions = [
        ExpenseTransaction(
          id: '1',
          title: 'Lunch',
          amount: 120,
          date: DateTime.now(),
          isExpense: true,
          category: 'Food',
        ),
        ExpenseTransaction(
          id: '2',
          title: 'Salary',
          amount: 5000,
          date: DateTime.now(),
          isExpense: false,
          category: 'Salary',
        ),
      ];

      for (var tx in dummyTransactions) {
        await db.insert('expense', tx.toMap());
      }

      // Debug: print inserted rows
      final rows = await db.query('expense');
      for (var row in rows) {
        print(row); // should show proper 'category'
      }
    },
  );

  await _refreshExpense();
}

  Future<void> _refreshExpense() async {
    if (_db == null) return;

    final data = await _db!.query('expense', orderBy: 'date DESC');

    setState(() {
      _transactions = data
          .map(
            (row) => ExpenseTransaction(
              id: row['id'].toString(),
              title: row['title'] as String,
              amount: row['amount'] as double,
              date: DateTime.parse(row['date'] as String),
              isExpense: (row['isExpense'] as int) == 1,
              category: row['category'].toString(),
            ),
          )
          .toList();
    });
  }

  double get _balance =>
    _groupedTransactions.fold(0.0, (total, t) => total + (t.isExpense ? -t.amount : t.amount));

  double _totalIncome() =>
    _groupedTransactions.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);

  double _totalExpenses() =>
    _groupedTransactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);



  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    Future.microtask(() => _refreshExpense());

    return Scaffold(
      appBar: AppBar(title: const Text('SmartSpend'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildLeftColumn()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _buildTransactionsCard()),
                ],
              )
            : Column(
                children: [
                  _buildLeftColumn(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildTransactionsCard()),
                ],
              ),
      ),
      floatingActionButton: _db == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateTransactionPage(database: _db!),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
    );
  }

  List<ExpenseTransaction> get _groupedTransactions {
  final now = DateTime.now();
  var list = _transactions;

  if (_groupBy == 'Day') {
    list = list.where((t) =>
        t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day).toList();
  } else if (_groupBy == 'Week') {
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    list = list.where((t) =>
        t.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        t.date.isBefore(weekEnd.add(const Duration(days: 1)))).toList();
  } else if (_groupBy == 'Month') {
    list = list.where((t) =>
        t.date.year == now.year &&
        t.date.month == now.month).toList();
  }

  return list;
}


  Widget _buildLeftColumn() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _groupBy,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Day', child: Text('Day')),
                    DropdownMenuItem(value: 'Week', child: Text('Week')),
                    DropdownMenuItem(value: 'Month', child: Text('Month')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _groupBy = v;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Balance', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      _balance.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Income: ${_totalIncome().toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.green),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Expenses: ${_totalExpenses().toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(height: 120, child: _buildMiniChart()),
            const SizedBox(height: 8),
            Text(
              'Grouped by: $_groupBy',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart() {
    final income = _totalIncome();
    final expenses = _totalExpenses();
    final total = (income + expenses) > 0 ? (income + expenses) : 1.0;
    final expenseFraction = expenses / total;

    return Row(
      children: [
        Expanded(
          flex: (expenseFraction * 100).round(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: ((1 - expenseFraction) * 100).round(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  List<ExpenseTransaction> get _filteredTransactions {
    var list = _transactions;
    if (_filterStart != null && _filterEnd != null) {
      list = list.where((t) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        final s = DateTime(
          _filterStart!.year,
          _filterStart!.month,
          _filterStart!.day,
        );
        final e = DateTime(
          _filterEnd!.year,
          _filterEnd!.month,
          _filterEnd!.day,
        );
        return !d.isBefore(s) && !d.isAfter(e);
      }).toList();
    }

    if (_filterType != 'All') {
      final wantExpense = _filterType == 'Expense';
      list = list.where((t) => t.isExpense == wantExpense).toList();
    }

    if (_filterCategory != 'All') {
      list = list.where((t) => t.category == _filterCategory).toList();
    }

    return list;
  }

  Future<void> _showFilterDialog() async {
    DateTime? start = _filterStart;
    DateTime? end = _filterEnd;
    String type = _filterType;
    String category = _filterCategory;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            return AlertDialog(
              title: const Text('Filter Transactions'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date range picker
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: ctx2,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDateRange: start != null && end != null
                              ? DateTimeRange(start: start!, end: end!)
                              : null,
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            start = picked.start;
                            end = picked.end;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        start == null || end == null
                            ? 'Select date range'
                            : '${start!.day}/${start!.month}/${start!.year} - ${end!.day}/${end!.month}/${end!.year}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Type selector
                    const Text('Type'),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
                        DropdownMenuItem(
                          value: 'Income',
                          child: Text('Income'),
                        ),
                        DropdownMenuItem(
                          value: 'Expense',
                          child: Text('Expense'),
                        ),
                      ],
                      onChanged: (v) => setStateDialog(() => type = v ?? 'All'),
                    ),
                    const SizedBox(height: 12),
                    // Category selector
                    const Text('Category'),
                    const SizedBox(height: 6),
                    DropdownButton<String>(
                      value: category,
                      items: [
                        const DropdownMenuItem(
                          value: 'All',
                          child: Text('All'),
                        ),
                        ...categories.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (v) =>
                          setStateDialog(() => category = v ?? 'All'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // clear filters
                    setState(() {
                      _filterStart = null;
                      _filterEnd = null;
                      _filterType = 'All';
                      _filterCategory = 'All';
                    });
                    Navigator.of(ctx2).pop();
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx2).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterStart = start;
                      _filterEnd = end;
                      _filterType = type;
                      _filterCategory = category;
                    });
                    Navigator.of(ctx2).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title, count and filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      '${_filteredTransactions.length}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Filter',
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // List of transactions
            Expanded(
              child: ListView.separated(
                itemCount: _filteredTransactions.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (ctx, i) {
                  final t = _filteredTransactions[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: t.isExpense
                          ? Colors.red[100]
                          : Colors.green[100],
                      child: Icon(
                        t.isExpense ? Icons.shopping_cart : Icons.attach_money,
                        color: t.isExpense ? Colors.red : Colors.green,
                      ),
                    ),
                    title: Text(t.title),
                    subtitle: Text(
                      '${t.date.day}/${t.date.month}/${t.date.year}',
                    ),
                    trailing: Text(
                      '${t.isExpense ? '-' : '+'}${t.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: t.isExpense ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // 👇 Tap to navigate to detail page
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReadPage(transaction: t, database: _db!),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
