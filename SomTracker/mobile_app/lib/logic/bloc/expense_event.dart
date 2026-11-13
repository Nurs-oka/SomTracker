import 'package:equatable/equatable.dart';
import '../../data/models/expense_model.dart';

abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionsEvent extends TransactionEvent {
  const LoadTransactionsEvent();
}

class AddCategoryEvent extends TransactionEvent {
  final String type;
  final String name;

  const AddCategoryEvent({required this.type, required this.name});

  @override
  List<Object?> get props => [type, name];
}

class AddTransactionEvent extends TransactionEvent {
  final String type;
  final double amount;
  final String category;
  final String comment;
  final String date;

  const AddTransactionEvent({
    required this.type,
    required this.amount,
    required this.category,
    required this.comment,
    required this.date,
  });

  @override
  List<Object?> get props => [type, amount, category, comment, date];
}

class UpdateTransactionEvent extends TransactionEvent {
  final TransactionModel transaction;
  const UpdateTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String id;
  const DeleteTransactionEvent(this.id);

  @override
  List<Object?> get props => [id];
}
