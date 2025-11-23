# Notification Extraction Task

## Pending Tasks
- [x] Create `lib/admin_dashboard/notifications_manager.dart` with NotificationsManager class
- [ ] Move notification variables to NotificationsManager: `_flutterLocalNotificationsPlugin`, `_appointmentsSubscription`, `_notificationsSubscription`, `_seenAppointmentIds`, `_notifications`, `_unreadNotifications`
- [ ] Move notification methods to NotificationsManager: `_initializeNotifications()`, `_handleNewAppointment()`, `_showNotificationsDialog()`, `_markAsReadAndOpenAppointment()`, `_markAllAsRead()`
- [ ] Update AdminDashboard.dart to instantiate NotificationsManager with callbacks
- [ ] Remove notification logic from AdminDashboard.dart
- [ ] Update imports in AdminDashboard.dart
- [ ] Test functionality: local notifications, Firestore sync, unread badge, mark as read, opening appointments
