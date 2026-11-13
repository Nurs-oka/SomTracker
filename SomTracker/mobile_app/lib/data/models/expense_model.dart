import 'package:equatable/equatable.dart';

class TransactionModel extends Equatable {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String type;
  final String comment;
  final String date;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.comment,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'Прочее',
      type: json['type'] as String? ?? 'expense',
      comment: json['comment'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, title, amount, category, type, comment, date];
}
