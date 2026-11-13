import 'package:flutter/material.dart';
import '../../data/models/expense_model.dart';

class ExpenseCard extends StatelessWidget {
  final TransactionModel expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Еда':
        return Icons.restaurant;
      case 'Транспорт':
        return Icons.directions_bus;
      case 'Учёба':
      case 'Стипендия':
        return Icons.school_outlined;
      case 'Зарплата':
      case 'Подработка':
        return Icons.work_outline;
      case 'Подарок':
        return Icons.card_giftcard;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == 'income';
    final color = isIncome ? const Color(0xFF45C78A) : const Color(0xFFFF5B72);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: const Color(0xFF111619),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF3B4249)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(_categoryIcon(expense.category)),
        ),
        title: Text(expense.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        subtitle: Text(
          expense.comment.isEmpty
              ? '${expense.category} • ${expense.date}'
              : '${expense.category} • ${expense.date}\n${expense.comment}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60),
        ),
        isThreeLine: expense.comment.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isIncome ? '+' : '−'}${expense.amount.toStringAsFixed(0)} KGS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            IconButton(
              tooltip: 'Удалить запись',
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.white60,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
