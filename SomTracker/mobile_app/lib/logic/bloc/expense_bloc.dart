import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/expense_repository.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc({required this.repository}) : super(TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<AddCategoryEvent>(_onAddCategory);
    on<AddTransactionEvent>(_onAddTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final categories = await repository.fetchCategories();
      final transactions = await repository.fetchTransactions();
      emit(TransactionLoaded(
        transactions: transactions,
        expenseCategories: categories['expense']!,
        incomeCategories: categories['income']!,
      ));
    } catch (error) {
      emit(
          TransactionError('Нет связи с сервером. Проверьте backend.\n$error'));
    }
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await repository.addCategory(type: event.type, name: event.name);
      add(const LoadTransactionsEvent());
    } catch (error) {
      emit(TransactionError('Ошибка добавления категории: $error'));
    }
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await repository.addTransaction(
        type: event.type,
        category: event.category,
        amount: event.amount,
        comment: event.comment,
        date: event.date,
      );
      add(const LoadTransactionsEvent());
    } catch (error) {
      emit(TransactionError('Ошибка сохранения: $error'));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await repository.updateTransaction(event.transaction);
      add(const LoadTransactionsEvent());
    } catch (error) {
      emit(TransactionError('Ошибка изменения: $error'));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      await repository.deleteTransaction(event.id);
      add(const LoadTransactionsEvent());
    } catch (error) {
      emit(TransactionError('Ошибка удаления: $error'));
    }
  }
}
