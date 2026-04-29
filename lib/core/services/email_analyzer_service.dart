import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'google_api_service.dart';
import 'package:flutter/foundation.dart';

class EmailAnalyzerService {
  final GoogleApiService _googleApi;
  final GenerativeModel _model;

  EmailAnalyzerService(this._googleApi, String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey.trim(),
        );

  /// 指定した日時以降の未読メールを解析し、予定やタスクがあれば自動登録する
  /// 登録された予定数とタスク数をマップで返す
  Future<Map<String, int>> analyzeAndRegisterEvents(DateTime since) async {
    final emails = await _googleApi.fetchUnreadEmailsData(since);
    if (emails.isEmpty) return {'events': 0, 'tasks': 0};

    int registeredEvents = 0;
    int registeredTasks = 0;

    for (var email in emails) {
      try {
        final prompt = '''
あなたは極めて優秀な秘書AIです。以下のメール内容を解析し、カレンダーに登録すべき「予定・会議」や、Google Tasksに登録すべき「やるべきこと（ToDo）」があれば抽出し、以下のJSON形式のみで出力してください。

【重要な制約事項（厳守）】
- 宣伝、広告、セール情報、メルマガ、アンケートのお願い、単なるお知らせ（規約改定やログイン通知など）は【絶対に無視】してください。
- ユーザーが実際に行動を起こす必要があるタスク、または日時が明確に確定している予定のみを抽出してください。
- 該当するものがない場合（広告メールなど）は、両方の配列を空にしてください。
- マークダウンのコードブロック(` ```json `)は使用せず、純粋なJSON文字列のみを出力してください。

現在の日時（基準）: ${DateTime.now().toIso8601String()}

出力フォーマット:
{
  "events": [
    {
      "title": "予定のタイトル",
      "start": "ISO8601形式の開始日時 (例: 2026-05-01T14:00:00+09:00)",
      "end": "ISO8601形式の終了日時 (例: 2026-05-01T15:00:00+09:00)",
      "description": "予定の詳細や補足事項"
    }
  ],
  "tasks": [
    {
      "title": "タスクのタイトル（簡潔に）",
      "dueDate": "ISO8601形式の期限日時 (期限が不明な場合はnull)",
      "notes": "詳細や補足事項"
    }
  ]
}

メール内容:
件名: ${email['subject']}
内容: ${email['snippet']}
''';

        final response = await _model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim() ?? '{"events":[],"tasks":[]}';
        
        String jsonStr = text;
        if (jsonStr.startsWith('```json')) {
          jsonStr = jsonStr.substring(7);
          if (jsonStr.endsWith('```')) {
            jsonStr = jsonStr.substring(0, jsonStr.length - 3);
          }
        }
        jsonStr = jsonStr.trim();

        if (jsonStr.isEmpty) continue;

        final Map<String, dynamic> result = jsonDecode(jsonStr);
        
        // 予定の登録
        if (result['events'] != null) {
          final List<dynamic> events = result['events'];
          for (var evt in events) {
            final title = evt['title'] as String;
            final start = DateTime.parse(evt['start'] as String);
            final end = DateTime.parse(evt['end'] as String);
            final desc = evt['description'] as String;

            final success = await _googleApi.insertCalendarEvent(title, start, end, desc);
            if (success) registeredEvents++;
          }
        }

        // タスクの登録
        if (result['tasks'] != null) {
          final List<dynamic> tasks = result['tasks'];
          for (var tsk in tasks) {
            final title = tsk['title'] as String;
            final dueDateStr = tsk['dueDate'] as String?;
            final notes = tsk['notes'] as String? ?? '';
            
            DateTime? dueDate;
            if (dueDateStr != null && dueDateStr != 'null') {
              try {
                dueDate = DateTime.parse(dueDateStr);
              } catch (_) {}
            }

            final success = await _googleApi.insertTask(title, notes, dueDate);
            if (success) registeredTasks++;
          }
        }

      } catch (e) {
        debugPrint('Email Analysis Error for ${email['subject']}: $e');
      }
    }

    return {'events': registeredEvents, 'tasks': registeredTasks};
  }

  /// メッセンジャー等の通知内容を解析し、予定やタスクがあれば自動登録する
  Future<Map<String, int>> analyzeNotificationsAndRegisterEvents(List<Map<dynamic, dynamic>> notifications) async {
    if (notifications.isEmpty) return {'events': 0, 'tasks': 0};

    int registeredEvents = 0;
    int registeredTasks = 0;

    // 通知内容を連結して一度に解析する
    StringBuffer messagesBuffer = StringBuffer();
    for (int i = 0; i < notifications.length; i++) {
      final n = notifications[i];
      messagesBuffer.writeln('【メッセージ ${i + 1}】');
      messagesBuffer.writeln('アプリ: ${n['packageName']}');
      messagesBuffer.writeln('送信者: ${n['sender']}');
      messagesBuffer.writeln('内容: ${n['text']}');
      messagesBuffer.writeln('---');
    }

    try {
      final prompt = '''
あなたは極めて優秀な秘書AIです。以下のLINE、WhatsApp、Chatwork、Teams等のメッセンジャー通知ログを解析し、カレンダーに登録すべき「予定・会議」や、Google Tasksに登録すべき「やるべきこと（ToDo）」があれば抽出し、以下のJSON形式のみで出力してください。

【重要な制約事項（厳守）】
- 友人との単なる雑談、スタンプのみの通知、「了解」「ありがとうございます」等の短い返信、システム通知は【絶対に無視】してください。
- ユーザーが実際に行動を起こす必要があるタスク、または日時や場所が明確に確定している予定のみを抽出してください。
- 各メッセージごとに判断し、該当するものがない場合は両方の配列を空にしてください。
- マークダウンのコードブロック(` ```json `)は使用せず、純粋なJSON文字列のみを出力してください。

現在の日時（基準）: ${DateTime.now().toIso8601String()}

出力フォーマット:
{
  "events": [
    {
      "title": "予定のタイトル（送信者名を含めると親切です）",
      "start": "ISO8601形式の開始日時 (例: 2026-05-01T14:00:00+09:00)",
      "end": "ISO8601形式の終了日時 (例: 2026-05-01T15:00:00+09:00)",
      "description": "予定の詳細や補足事項"
    }
  ],
  "tasks": [
    {
      "title": "タスクのタイトル（送信者名を含めると親切です）",
      "dueDate": "ISO8601形式の期限日時 (期限が不明な場合はnull)",
      "notes": "詳細や補足事項"
    }
  ]
}

メッセンジャー通知ログ:
${messagesBuffer.toString()}
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '{"events":[],"tasks":[]}';
      
      String jsonStr = text;
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
        if (jsonStr.endsWith('```')) {
          jsonStr = jsonStr.substring(0, jsonStr.length - 3);
        }
      }
      jsonStr = jsonStr.trim();

      if (jsonStr.isNotEmpty) {
        final Map<String, dynamic> result = jsonDecode(jsonStr);
        
        // 予定の登録
        if (result['events'] != null) {
          final List<dynamic> events = result['events'];
          for (var evt in events) {
            final title = evt['title'] as String;
            final start = DateTime.parse(evt['start'] as String);
            final end = DateTime.parse(evt['end'] as String);
            final desc = evt['description'] as String;

            final success = await _googleApi.insertCalendarEvent(title, start, end, desc);
            if (success) registeredEvents++;
          }
        }

        // タスクの登録
        if (result['tasks'] != null) {
          final List<dynamic> tasks = result['tasks'];
          for (var tsk in tasks) {
            final title = tsk['title'] as String;
            final dueDateStr = tsk['dueDate'] as String?;
            final notes = tsk['notes'] as String? ?? '';
            
            DateTime? dueDate;
            if (dueDateStr != null && dueDateStr != 'null') {
              try {
                dueDate = DateTime.parse(dueDateStr);
              } catch (_) {}
            }

            final success = await _googleApi.insertTask(title, notes, dueDate);
            if (success) registeredTasks++;
          }
        }
      }
    } catch (e) {
      debugPrint('Messenger Analysis Error: $e');
    }

    return {'events': registeredEvents, 'tasks': registeredTasks};
  }
}
