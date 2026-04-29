import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/tasks/v1.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class GoogleApiService {
  final http.Client _client;

  GoogleApiService(this._client);

  // Gmailの直近の未読メールを数件取得
  Future<String> fetchRecentEmails() async {
    final gmail = GmailApi(_client);
    try {
      final list = await gmail.users.messages.list('me', q: 'is:unread', maxResults: 5);
      if (list.messages == null || list.messages!.isEmpty) return '未読メールはありません。';

      StringBuffer sb = StringBuffer('【Gmail未読】\n');
      for (var msg in list.messages!) {
        final detail = await gmail.users.messages.get('me', msg.id!);
        final snippet = detail.snippet ?? '';
        final subject = detail.payload?.headers?.firstWhere((h) => h.name == 'Subject').value ?? '無題';
        sb.writeln('件名: $subject\n内容: $snippet\n---');
      }
      return sb.toString();
    } catch (e) {
      return 'Gmail取得エラー: $e';
    }
  }

  // 解析用：指定日時以降の未読メールデータを取得
  Future<List<Map<String, String>>> fetchUnreadEmailsData(DateTime since) async {
    final gmail = GmailApi(_client);
    try {
      final sinceEpoch = (since.millisecondsSinceEpoch / 1000).floor();
      final query = 'is:unread after:$sinceEpoch';
      final list = await gmail.users.messages.list('me', q: query, maxResults: 10);
      if (list.messages == null || list.messages!.isEmpty) return [];

      List<Map<String, String>> emails = [];
      for (var msg in list.messages!) {
        final detail = await gmail.users.messages.get('me', msg.id!);
        final snippet = detail.snippet ?? '';
        final subject = detail.payload?.headers?.firstWhere((h) => h.name == 'Subject', orElse: () => MessagePartHeader(name: 'Subject', value: '無題')).value ?? '無題';
        emails.add({
          'id': msg.id!,
          'subject': subject,
          'snippet': snippet,
        });
      }
      return emails;
    } catch (e) {
      print('Gmail fetch data error: $e');
      return [];
    }
  }

  // カレンダーに予定を登録する
  Future<bool> insertCalendarEvent(String title, DateTime start, DateTime end, String description) async {
    final calendar = CalendarApi(_client);
    try {
      final event = Event(
        summary: title,
        description: description,
        start: EventDateTime(dateTime: start.toUtc()),
        end: EventDateTime(dateTime: end.toUtc()),
      );
      await calendar.events.insert(event, 'primary');
      return true;
    } catch (e) {
      print('Calendar insert error: $e');
      return false;
    }
  }

  // Google Tasksにタスクを登録する
  Future<bool> insertTask(String title, String notes, DateTime? dueDate) async {
    final tasksApi = TasksApi(_client);
    try {
      final task = Task(
        title: title,
        notes: notes,
        due: dueDate != null ? '${dueDate.toUtc().toIso8601String().split('T')[0]}T00:00:00.000Z' : null,
      );
      await tasksApi.tasks.insert(task, '@default');
      return true;
    } catch (e) {
      print('Task insert error: $e');
      return false;
    }
  }

  // 本日のカレンダー予定を取得
  Future<String> fetchTodayEvents() async {
    final calendar = CalendarApi(_client);
    try {
      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final events = await calendar.events.list(
        'primary',
        timeMin: now.toUtc(),
        timeMax: endOfDay.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      if (events.items == null || events.items!.isEmpty) return '本日の予定はありません。';

      StringBuffer sb = StringBuffer('【カレンダー予定】\n');
      for (var event in events.items!) {
        final start = event.start?.dateTime ?? event.start?.date;
        sb.writeln('・${event.summary} ($start)');
      }
      return sb.toString();
    } catch (e) {
      return 'カレンダー取得エラー: $e';
    }
  }

  // Google Tasksの期限付きタスクを取得
  Future<String> fetchPendingTasks() async {
    final tasksApi = TasksApi(_client);
    try {
      final taskLists = await tasksApi.tasklists.list();
      if (taskLists.items == null || taskLists.items!.isEmpty) return 'タスクリストがありません。';

      StringBuffer sb = StringBuffer('【Google Tasks】\n');
      for (var list in taskLists.items!) {
        final tasks = await tasksApi.tasks.list(list.id!, showCompleted: false);
        if (tasks.items != null) {
          for (var task in tasks.items!) {
            sb.writeln('・${task.title} (期限: ${task.due ?? 'なし'})');
          }
        }
      }
      return sb.toString();
    } catch (e) {
      return 'タスク取得エラー: $e';
    }
  }

  // カレンダーの生イベントデータを取得（UI表示用）
  Future<List<Event>> fetchCalendarEvents(DateTime start, DateTime end) async {
    final calendar = CalendarApi(_client);
    try {
      final events = await calendar.events.list(
        'primary',
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      return events.items ?? [];
    } catch (e) {
      print('Calendar fetch error: $e');
      return [];
    }
  }
}
