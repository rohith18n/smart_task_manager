class AppConstants {
  static const String appTitle = 'Smart Task Manager';
  static const String tasksTableName = 'tasks';
  static const String firestoreUsersCollection = 'users';
  static const String databaseName = 'smart_tasks.db';
  static const int databaseVersion = 3;

  // REST API
  static const String apiBaseUrl = 'https://taskmanager.uat-lplusltd.com';

  // Sync Action Constants
  static const String syncActionNone = 'NONE';
  static const String syncActionInsert = 'INSERT';
  static const String syncActionUpdate = 'UPDATE';
  static const String syncActionDelete = 'DELETE';

  // Notification Constants
  static const String notificationChannelId = 'smart_tasks_channel';
  static const String notificationChannelName = 'Smart Task Reminders & Updates';
  static const String notificationChannelDescription = 'Notifications for task due dates and updates';
}
