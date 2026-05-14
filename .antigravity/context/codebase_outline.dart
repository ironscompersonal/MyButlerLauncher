// MY AI BUTLER Codebase Outline (Service Interfaces)

abstract class WeatherService {
  Future<WeatherData> fetchWeather(double lat, double lon);
}

abstract class TransitService {
  Future<String> fetchTransitInfo();
}

abstract class NotificationService {
  Future<bool> checkPermission();
  Future<String> getAppSignature();
}

abstract class NativeNotificationService {
  Future<void> requestPermission();
}

abstract class HealthService {
  Future<bool> isHealthConnectInstalled();
  Future<void> openHealthConnectStore();
  Future<bool> requestPermissions();
  Future<Map<String, dynamic>> fetchHealthSummary();
  Future<List<Map<String, dynamic>>> fetchWeeklyHealthData();
}

abstract class GoogleApiService {
  Future<String> fetchRecentEmails();
  Future<List<Map<String, String>>> fetchUnreadEmailsData(DateTime since);
  Future<bool> insertCalendarEvent(String title, DateTime start, DateTime end, String description);
  Future<bool> insertTask(String title, String notes, DateTime? dueDate);
  Future<String> fetchTodayEvents();
  Future<String> fetchPendingTasks();
  Future<List<Event>> fetchCalendarEvents(DateTime start, DateTime end);
}

abstract class EmailAnalyzerService {
  Future<Map<String, int>> analyzeAndRegisterEvents(DateTime since);
  Future<Map<String, int>> analyzeNotificationsAndRegisterEvents(List<Map<dynamic, dynamic>> notifications);
}

abstract class ChatService {
  Future<String> sendMessage(String message);
}

abstract class AppLauncherService {
  Future<List<Map<String, dynamic>>> getInstalledApps();
  Future<void> launchApp(String packageName);
  Future<Uint8List?> getAppIcon(String packageName);
}

abstract class AIInsightService {
  Future<String> getSimplifiedInsight(String rawData);
}
