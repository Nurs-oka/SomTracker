import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/repositories/expense_repository.dart';
import 'logic/bloc/expense_bloc.dart';
import 'logic/bloc/expense_event.dart';
import 'presentation/screens/wallet_screen.dart';

void main() => runApp(const SomTrackerApp());

class SomTrackerApp extends StatelessWidget {
  const SomTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => TransactionRepository(),
      child: BlocProvider(
        create: (context) => TransactionBloc(
          repository: context.read<TransactionRepository>(),
        )..add(const LoadTransactionsEvent()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SomTracker',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF86BFFF),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF101416),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF101416),
              foregroundColor: Colors.white,
            ),
            navigationBarTheme: const NavigationBarThemeData(
              labelTextStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 12),
              ),
              elevation: 0,
            ),
            useMaterial3: true,
          ),
          home: const WalletScreen(),
        ),
      ),
    );
  }
}
