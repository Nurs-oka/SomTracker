import 'package:flutter_test/flutter_test.dart';
import 'package:somtracker/data/models/expense_model.dart';

void main() {
  test('parses transaction type and optional comment', () {
    final transaction = TransactionModel.fromJson(const {
      'id': 42,
      'title': 'Зарплата',
      'amount': 12500,
      'category': 'Зарплата',
      'type': 'income',
      'comment': 'Аванс',
      'date': '13.11.2026',
    });

    expect(transaction.id, '42');
    expect(transaction.type, 'income');
    expect(transaction.comment, 'Аванс');
    expect(transaction.amount, 12500);
  });

  test('defaults older records to expenses without comments', () {
    final transaction = TransactionModel.fromJson(const {
      'id': 'old',
      'title': 'Обед',
      'amount': 250,
      'category': 'Еда',
      'date': '12.11.2026',
    });

    expect(transaction.type, 'expense');
    expect(transaction.comment, isEmpty);
  });
}
