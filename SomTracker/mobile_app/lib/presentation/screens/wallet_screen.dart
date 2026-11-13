import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/expense_model.dart';
import '../../logic/bloc/expense_bloc.dart';
import '../../logic/bloc/expense_event.dart';
import '../../logic/bloc/expense_state.dart';
import '../widgets/expense_card.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const _months = [
    'Январь',
    'Февраль',
    'Март',
    'Апрель',
    'Май',
    'Июнь',
    'Июль',
    'Август',
    'Сентябрь',
    'Октябрь',
    'Ноябрь',
    'Декабрь',
  ];

  static const _categoryColors = [
    Color(0xFF8A4DFF),
    Color(0xFF456BFF),
    Color(0xFF4CC6D6),
    Color(0xFFE35C43),
    Color(0xFFF0A934),
    Color(0xFF83BF62),
    Color(0xFFD66BC1),
  ];

  static const _backgroundColor = Color(0xFF101416);
  static const _panelColor = Color(0xFF252E39);
  static const _cardColor = Color(0xFF111619);

  int _selectedTab = 0;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _balanceVisible = true;

  String get _type => _selectedTab == 1 ? 'income' : 'expense';

  String _formatAmount(double amount) {
    final absolute = amount.abs();
    final fixed = absolute == absolute.truncateToDouble()
        ? absolute.toStringAsFixed(0)
        : absolute.toStringAsFixed(2);
    final parts = fixed.split('.');
    final grouped = parts.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );
    final sign = amount < 0 ? '−' : '';
    return '$sign$grouped${parts.length == 2 ? ',${parts[1]}' : ''}';
  }

  DateTime? _parseTransactionDate(String value) {
    final parts = value.split('.');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  String _dateForSelectedMonth() {
    final now = DateTime.now();
    final isCurrentMonth =
        now.year == _selectedMonth.year && now.month == _selectedMonth.month;
    final day = isCurrentMonth ? now.day : 1;
    return '${day.toString().padLeft(2, '0')}.'
        '${_selectedMonth.month.toString().padLeft(2, '0')}.'
        '${_selectedMonth.year}';
  }

  bool _isInSelectedMonth(TransactionModel transaction) {
    final date = _parseTransactionDate(transaction.date);
    return date?.month == _selectedMonth.month &&
        date?.year == _selectedMonth.year;
  }

  List<TransactionModel> _transactionsForMonth(
    List<TransactionModel> transactions,
  ) {
    return transactions.where(_isInSelectedMonth).toList();
  }

  Future<void> _selectMonth() async {
    final month = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Выберите месяц',
    );
    if (month != null && mounted) {
      setState(() {
        _selectedMonth = DateTime(month.year, month.month);
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  Future<void> _showAddDialog(
    BuildContext context, {
    required String type,
    required String category,
  }) async {
    final amountController = TextEditingController();
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _panelColor,
        title: Text(category),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Сумма',
                suffixText: 'KGS',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Комментарий (необязательно)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(
                amountController.text.trim().replaceAll(',', '.'),
              );
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите корректную сумму')),
                );
                return;
              }
              context.read<TransactionBloc>().add(AddTransactionEvent(
                    type: type,
                    category: category,
                    amount: amount,
                    comment: commentController.text.trim(),
                    date: _dateForSelectedMonth(),
                  ));
              Navigator.pop(dialogContext);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    amountController.dispose();
    commentController.dispose();
  }

  Future<void> _showAddCategoryDialog(
    BuildContext context, {
    required String type,
    required List<String> categories,
  }) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _panelColor,
        title: Text(type == 'income'
            ? 'Новая категория дохода'
            : 'Новая категория расхода'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Название категории'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Введите название категории'),
                  ),
                );
                return;
              }
              if (categories.any(
                (item) => item.toLowerCase() == name.toLowerCase(),
              )) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Такая категория уже есть'),
                  ),
                );
                return;
              }
              context
                  .read<TransactionBloc>()
                  .add(AddCategoryEvent(type: type, name: name));
              Navigator.pop(dialogContext);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _showEditDialog(
    BuildContext context,
    TransactionModel transaction,
    List<String> expenseCategories,
    List<String> incomeCategories,
  ) async {
    final titleController = TextEditingController(text: transaction.title);
    final amountController =
        TextEditingController(text: transaction.amount.toString());
    final commentController = TextEditingController(text: transaction.comment);
    var type = transaction.type;
    var category = transaction.category;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final categories =
              type == 'income' ? incomeCategories : expenseCategories;
          if (!categories.contains(category)) category = categories.first;

          return AlertDialog(
            backgroundColor: _panelColor,
            title: const Text('Изменить запись'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Тип'),
                    items: const [
                      DropdownMenuItem(
                        value: 'expense',
                        child: Text('Расход'),
                      ),
                      DropdownMenuItem(
                        value: 'income',
                        child: Text('Доход'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          type = value;
                          category = value == 'income'
                              ? incomeCategories.first
                              : expenseCategories.first;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Категория'),
                    items: categories
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Сумма',
                      suffixText: 'KGS',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Комментарий (необязательно)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  final amount = double.tryParse(
                    amountController.text.trim().replaceAll(',', '.'),
                  );
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Введите корректную сумму'),
                      ),
                    );
                    return;
                  }
                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Введите название записи'),
                      ),
                    );
                    return;
                  }
                  context.read<TransactionBloc>().add(
                        UpdateTransactionEvent(
                          TransactionModel(
                            id: transaction.id,
                            title: title,
                            amount: amount,
                            category: category,
                            type: type,
                            comment: commentController.text.trim(),
                            date: transaction.date,
                          ),
                        ),
                      );
                  Navigator.pop(dialogContext);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
    titleController.dispose();
    amountController.dispose();
    commentController.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _panelColor,
        title: const Text('Удалить запись?'),
        content: Text(
            '${transaction.title} — ${_formatAmount(transaction.amount)} KGS'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context
          .read<TransactionBloc>()
          .add(DeleteTransactionEvent(transaction.id));
    }
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Предыдущий месяц',
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left, size: 30),
          ),
          TextButton.icon(
            onPressed: _selectMonth,
            icon: const Icon(Icons.arrow_drop_down),
            label: Text(
              '${_months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          IconButton(
            tooltip: 'Следующий месяц',
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary({
    required double expenses,
    required double income,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _summaryTile(
            label: 'Расходы',
            amount: expenses,
            color: const Color(0xFFFF5B72),
            selected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          _summaryTile(
            label: 'Доходы',
            amount: income,
            color: const Color(0xFF45C78A),
            selected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required double amount,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? _backgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${_formatAmount(amount)} KGS',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid({
    required BuildContext context,
    required String type,
    required List<String> categories,
    required List<TransactionModel> transactions,
  }) {
    final categoryTotals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type == type) {
        categoryTotals.update(
          transaction.category,
          (amount) => amount + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 400;
        final columns = width >= 1000
            ? 4
            : width >= 650
                ? 3
                : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: width < 400 ? 1.55 : 1.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length + 1,
          itemBuilder: (context, index) {
            if (index == categories.length) {
              return _buildAddCategoryCard(
                compact: compact,
                onTap: () => _showAddCategoryDialog(
                  context,
                  type: type,
                  categories: categories,
                ),
              );
            }
            final category = categories[index];
            final color = _categoryColors[index % _categoryColors.length];
            final amount = categoryTotals[category] ?? 0;
            return _buildCategoryCard(
              category: category,
              amount: amount,
              color: color,
              icon: _categoryIcon(category),
              compact: compact,
              onTap: () => _showAddDialog(
                context,
                type: type,
                category: category,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryCard({
    required String category,
    required double amount,
    required Color color,
    required IconData icon,
    required bool compact,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(compact ? 6 : 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF3B4249)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 52,
                height: compact ? 38 : 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              SizedBox(width: compact ? 6 : 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: compact ? 13 : 15),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_formatAmount(amount)} KGS',
                        style: TextStyle(
                          fontSize: compact ? 12 : 16,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCategoryCard({
    required bool compact,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(compact ? 6 : 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF555D65),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 38 : 52,
                height: compact ? 38 : 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF252A30),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add, size: 30, color: Colors.white70),
              ),
              SizedBox(width: compact ? 6 : 10),
              Text(
                'Добавить',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: compact ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Еда':
        return Icons.restaurant;
      case 'Транспорт':
        return Icons.directions_bus;
      case 'Учёба':
      case 'Стипендия':
        return Icons.school_outlined;
      case 'Дом':
      case 'Жильё':
        return Icons.bed_outlined;
      case 'Здоровье':
        return Icons.medical_services_outlined;
      case 'Развлечения':
        return Icons.movie_outlined;
      case 'Зарплата':
      case 'Подработка':
        return Icons.work_outline;
      case 'Подарок':
        return Icons.card_giftcard;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildJournal(
    BuildContext context,
    List<TransactionModel> transactions,
    List<String> expenseCategories,
    List<String> incomeCategories,
  ) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text(
          'Операций за этот месяц пока нет',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return ExpenseCard(
          expense: transaction,
          onTap: () => _showEditDialog(
            context,
            transaction,
            expenseCategories,
            incomeCategories,
          ),
          onDelete: () => _confirmDelete(context, transaction),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        toolbarHeight: 112,
        backgroundColor: _backgroundColor,
        centerTitle: true,
        title: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            final transactions = state is TransactionLoaded
                ? state.transactions
                : <TransactionModel>[];
            final today = DateTime.now();
            final balance = transactions.fold<double>(
              0,
              (total, item) {
                final date = _parseTransactionDate(item.date);
                if (date == null ||
                    date.isAfter(
                        DateTime(today.year, today.month, today.day))) {
                  return total;
                }
                return total +
                    (item.type == 'income' ? item.amount : -item.amount);
              },
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Общий баланс',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    IconButton(
                      tooltip:
                          _balanceVisible ? 'Скрыть баланс' : 'Показать баланс',
                      onPressed: () =>
                          setState(() => _balanceVisible = !_balanceVisible),
                      icon: Icon(
                        _balanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Text(
                  _balanceVisible ? '${_formatAmount(balance)} KGS' : '••••••',
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TransactionBloc>().add(
                  const LoadTransactionsEvent(),
                ),
          ),
        ],
      ),
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionInitial || state is TransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TransactionError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off,
                        size: 56, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => context
                          .read<TransactionBloc>()
                          .add(const LoadTransactionsEvent()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is TransactionLoaded) {
            final monthTransactions = _transactionsForMonth(state.transactions);
            final monthlyExpenses = monthTransactions
                .where((item) => item.type == 'expense')
                .fold<double>(0, (total, item) => total + item.amount);
            final monthlyIncome = monthTransactions
                .where((item) => item.type == 'income')
                .fold<double>(0, (total, item) => total + item.amount);
            final categories = _selectedTab == 1
                ? state.incomeCategories
                : state.expenseCategories;

            return Column(
              children: [
                _buildMonthSelector(),
                _buildMonthlySummary(
                  expenses: monthlyExpenses,
                  income: monthlyIncome,
                ),
                Expanded(
                  child: _selectedTab == 2
                      ? _buildJournal(
                          context,
                          monthTransactions,
                          state.expenseCategories,
                          state.incomeCategories,
                        )
                      : _buildCategoryGrid(
                          context: context,
                          type: _type,
                          categories: categories,
                          transactions: monthTransactions,
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _panelColor,
        indicatorColor: const Color(0xFF344453),
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.remove_circle_outline),
            selectedIcon: Icon(Icons.remove_circle),
            label: 'Расходы',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Доходы',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Операции',
          ),
        ],
      ),
    );
  }
}
