import 'package:equatable/equatable.dart';
import '../../data/models/expense_model.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final List<String> expenseCategories;
  final List<String> incomeCategories;

  const TransactionLoaded({
    required this.transactions,
    required this.expenseCategories,
    required this.incomeCategories,
  });

  @override
  List<Object?> get props => [
        transactions,
        expenseCategories,
        incomeCategories,
      ];
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}
