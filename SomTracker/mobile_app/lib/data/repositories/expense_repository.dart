import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/expense_model.dart';

class TransactionRepository {
  String get baseUrl {
    if (kIsWeb) return 'http://${Uri.base.host}:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  Future<Map<String, List<String>>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));
    if (response.statusCode != 200) {
      throw Exception(
          'Не удалось загрузить категории (${response.statusCode})');
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return {
      'expense': (json['expense'] as List<dynamic>).cast<String>(),
      'income': (json['income'] as List<dynamic>).cast<String>(),
    };
  }

  Future<List<TransactionModel>> fetchTransactions() async {
    final uri = Uri.parse('$baseUrl/transactions');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return (json['items'] as List<dynamic>)
          .map(
              (item) => TransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Ошибка сервера: ${response.statusCode}');
  }

  Future<void> addCategory({
    required String type,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'type': type, 'name': name}),
    );
    if (response.statusCode == 409) {
      throw Exception('Такая категория уже существует');
    }
    if (response.statusCode != 201) {
      throw Exception('Не удалось добавить категорию (${response.statusCode})');
    }
  }

  Future<void> addTransaction({
    required String type,
    required String category,
    required double amount,
    required String comment,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'title': category,
        'amount': amount,
        'category': category,
        'comment': comment,
        'date': date,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Не удалось сохранить расход (${response.statusCode})');
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/transactions/${transaction.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': transaction.type,
        'title': transaction.title,
        'amount': transaction.amount,
        'category': transaction.category,
        'comment': transaction.comment,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Не удалось изменить запись (${response.statusCode})');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/transactions/$id'));
    if (response.statusCode != 204) {
      throw Exception('Не удалось удалить запись (${response.statusCode})');
    }
  }
}
