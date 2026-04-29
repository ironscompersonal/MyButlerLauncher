import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/tasks/v1.dart';

class ApiConstants {
  static const List<String> googleScopes = [
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
    'openid',
    GmailApi.gmailReadonlyScope,
    CalendarApi.calendarEventsScope,
    TasksApi.tasksScope,
  ];
}
