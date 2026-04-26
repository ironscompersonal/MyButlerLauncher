import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/tasks/v1.dart';

class ApiConstants {
  static const List<String> googleScopes = [
    'email',
    'https://www.googleapis.com/auth/gmail.readonly',
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/tasks.readonly',
    // 'https://www.googleapis.com/auth/homegraph', // 一旦コメントアウトして検証
  ];
}
