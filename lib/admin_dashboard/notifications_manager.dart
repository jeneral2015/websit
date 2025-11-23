import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _notificationsSubscription;
  final List<Map<String, dynamic>> _notifications = [];
  final StreamController<int> _unreadNotificationsController =
      StreamController<int>.broadcast();

  // Single subscription to ensure no duplicates
  bool _isInitialized = false;

  // Getter for unread count (for external use if needed)
  int get unreadCount =>
      _notifications.where((n) => !(n['isRead'] ?? false)).length;

  Stream<int> get unreadNotificationsStream =>
      _unreadNotificationsController.stream;

  // ✅ Initialize FCM & Local Notifications
  Future<void> initializeNotifications() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 🔔 Initialize Local Notifications (only on mobile)
    if (!kIsWeb) {
      const AndroidInitializationSettings androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
      );
      await _flutterLocalNotificationsPlugin.initialize(initSettings);
    }

    // 🔔 Initialize FCM (only on mobile, as FCM is not fully supported on web)
    if (!kIsWeb) {
      final fcm = FirebaseMessaging.instance;
      await fcm.requestPermission();
      final token = await fcm.getToken();
      debugPrint('FCM Token: $token');

      // Handle background/terminated messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      FirebaseMessaging.onMessage.listen(_onMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    }

    // 🔔 Listen to Firestore notifications (real-time) - works on all platforms
    _notificationsSubscription = _firestore
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          _notifications.clear();
          _notifications.addAll(
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
          );
          _unreadNotificationsController.add(unreadCount);
        });
  }

  // Background handler (must be top-level or static)
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp();
    // You can log or handle background message here if needed
  }

  // Foreground message handler
  void _onMessage(RemoteMessage message) {
    final payload = message.data;
    final title = payload['title'] ?? 'تنبيه جديد';
    final body = payload['body'] ?? '';

    _showLocalNotification(title: title, body: body);
  }

  // When user taps notification while app is in background
  void _onMessageOpenedApp(RemoteMessage message) {
    // Optionally navigate to appointments tab
  }

  void _showLocalNotification({required String title, required String body}) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'appointments_channel',
          'حجوزات جديدة',
          channelDescription: 'تنبيهات الحجوزات',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.pink,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
          icon: '@mipmap/ic_notification',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    _flutterLocalNotificationsPlugin.show(0, title, body, details);
  }

  // ✅ Show popup on dashboard entry if unread > 0
  Future<void> showUnreadPopupIfExist(BuildContext context) async {
    if (unreadCount > 0) {
      await Future.delayed(const Duration(milliseconds: 500)); // Smooth entry
      if (!context.mounted) return;
      // Start the sequential flow directly
      await showSequentialNotifications(context);
    }
  }

  // ✅ New: Sequential Notification Flow
  Future<void> showSequentialNotifications(BuildContext context) async {
    final unreadNotifications = _notifications
        .where((n) => !(n['isRead'] ?? false))
        .toList();

    if (unreadNotifications.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('لا توجد تنبيهات جديدة')));
      }
      return;
    }

    // Sort by timestamp (oldest first usually makes sense for processing, or newest first)
    // Let's stick to the list order (which is descending/newest first in the listener)
    // If we want to process oldest first, we should reverse.
    // Let's process Newest First as per typical notification behavior.

    for (int i = 0; i < unreadNotifications.length; i++) {
      if (!context.mounted) return;

      final notification = unreadNotifications[i];
      final bool? shouldContinue = await _showSingleNotificationDialog(
        context,
        notification,
        currentIndex: i + 1,
        totalCount: unreadNotifications.length,
      );

      if (shouldContinue == null || !shouldContinue) {
        // User closed the dialog or cancelled the sequence
        break;
      }
    }
  }

  Future<bool?> _showSingleNotificationDialog(
    BuildContext context,
    Map<String, dynamic> notification, {
    required int currentIndex,
    required int totalCount,
  }) async {
    final appointmentId = notification['appointmentId'];
    Map<String, dynamic>? appointmentData;

    if (appointmentId != null) {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      if (doc.exists) {
        appointmentData = doc.data();
      }
    }

    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Force action
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                shape: BoxShape.circle,
              ),
              child: Text(
                '$currentIndex/$totalCount',
                style: TextStyle(
                  color: Colors.pink[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'تنبيه جديد',
                style: TextStyle(
                  color: Colors.pink[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification['message'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(notification['timestamp']),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Divider(height: 24),
              if (appointmentData != null) ...[
                _buildInfoRow('الاسم', appointmentData['name']),
                _buildInfoRow('الخدمة', appointmentData['service']),
                _buildInfoRow('التاريخ', appointmentData['date']),
                _buildInfoRow('الوقت', appointmentData['time']),
              ] else
                const Text(
                  'تفاصيل الموعد غير متوفرة',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        actions: [
          // Action Buttons
          if (appointmentData != null) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateStatus(appointmentId!, 'accepted');
                      await _markAsRead(notification['id'], true);
                      if (ctx.mounted) Navigator.pop(ctx, true); // Continue
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('قبول'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _updateStatus(appointmentId!, 'rejected');
                      await _markAsRead(notification['id'], true);
                      if (ctx.mounted) Navigator.pop(ctx, true); // Continue
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('رفض'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  // Close sequence
                  Navigator.pop(ctx, false);
                },
                child: const Text('إغلاق الكل'),
              ),
              TextButton(
                onPressed: () async {
                  // Mark as read and continue
                  await _markAsRead(notification['id'], true);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('تخطيط / التالي'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Kept for backward compatibility or manual access if needed,
  // but updated to show the list if user explicitly asks for "All Notifications"
  void showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.pink.shade100, width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.pink[800],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: const Text(
                  'كل التنبيهات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد تنبيهات',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          final isRead = notification['isRead'] ?? false;
                          final message = notification['message'] ?? '';
                          final timestamp = notification['timestamp'];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isRead
                                    ? Colors.grey.shade300
                                    : Colors.pink.shade200,
                                width: isRead ? 1 : 2,
                              ),
                            ),
                            color: isRead ? Colors.grey[50] : Colors.pink[50],
                            elevation: isRead ? 1 : 3,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              title: Text(
                                message,
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color: isRead
                                      ? Colors.grey[700]
                                      : Colors.pink[900],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isRead
                                      ? Colors.grey[500]
                                      : Colors.pink[600],
                                ),
                              ),
                              onTap: () {
                                _markAsReadAndOpenAppointment(
                                  context,
                                  notification,
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionIcon(
                      Icons.check_circle_outline,
                      'تحديد الكل كمقروء',
                      Colors.green,
                      () {
                        _markAllAsRead();
                        Navigator.pop(context);
                      },
                    ),
                    _buildActionIcon(
                      Icons.delete_outline,
                      'مسح الكل',
                      Colors.red,
                      () {
                        _showClearAllConfirmation(context);
                      },
                    ),
                    _buildActionIcon(
                      Icons.close,
                      'إغلاق',
                      Colors.grey,
                      () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _markAsReadAndOpenAppointment(
    BuildContext context,
    Map<String, dynamic> notification,
  ) async {
    await _markAsRead(notification['id'], true);

    final appointmentId = notification['appointmentId'];
    if (appointmentId != null) {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      if (doc.exists) {
        if (!context.mounted) return;
        Navigator.pop(context);
        showAppointmentDialog(context, appointmentId, doc.data()!);
      }
    }
  }

  void showAppointmentDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.pink[800]),
            const SizedBox(width: 12),
            Text(
              'تفاصيل الحجز',
              style: TextStyle(
                color: Colors.pink[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('الاسم', data['name']),
              _buildInfoRow('الهاتف', data['phone']),
              _buildInfoRow('الخدمة', data['service']),
              _buildInfoRow('المكان', data['location']),
              _buildInfoRow('التاريخ', data['date']),
              _buildInfoRow('الوقت', data['time']),
              _buildInfoRow(
                'الرسالة',
                data['message']?.isNotEmpty == true
                    ? data['message']
                    : 'لا توجد',
              ),
              _buildInfoRow('الحالة', _getStatusLabel(data['status'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _updateStatus(docId, 'accepted');
              if (!context.mounted) return;
              Navigator.pop(context);
              _showStatusSnackbar(context, 'تم قبول الموعد', Colors.green);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('قبول'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateStatus(docId, 'rejected');
              Navigator.pop(context);
              _showStatusSnackbar(context, 'تم رفض الموعد', Colors.red);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'accepted':
        return '✅ مقبول';
      case 'rejected':
        return '❌ مرفوض';
      default:
        return '⏳ معلق';
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: value ?? 'غير محدد',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _markAsRead(String id, bool isRead) async {
    await _firestore.collection('notifications').doc(id).update({
      'isRead': isRead,
    });
  }

  Future<void> _markAllAsRead() async {
    final batch = _firestore.batch();
    for (var n in _notifications.where((n) => !(n['isRead'] ?? false))) {
      batch.update(_firestore.collection('notifications').doc(n['id']), {
        'isRead': true,
      });
    }
    await batch.commit();
  }

  Future<void> _updateStatus(String docId, String status) async {
    await _firestore.collection('appointments').doc(docId).update({
      'status': status,
    });
  }

  void _showClearAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد مسح الكل'),
        content: const Text(
          'هل أنت متأكد من مسح جميع التنبيهات؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _clearAllNotifications();
              if (!context.mounted) return;
              Navigator.pop(context); // close notifications dialog
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('مسح الكل'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    final batch = _firestore.batch();
    for (var n in _notifications) {
      batch.delete(_firestore.collection('notifications').doc(n['id']));
    }
    await batch.commit();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'غير معروف';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.tryParse(timestamp) ?? DateTime.now();
      } else {
        return timestamp.toString();
      }
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return 'اليوم ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (date.difference(now).inDays == -1) {
        return 'أمس ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else {
        return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '---';
    }
  }

  // ✅ Helper: Trigger notification creation + FCM (to be called from BookingForm)
  Future<void> createNotificationForNewAppointment(
    Map<String, dynamic> appointmentData,
  ) async {
    try {
      // 🔒 Use Transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // 1. Save appointment (if not already saved — just for safety)
        //    (In practice, BookingForm saves it first — this is backup)
        // 2. Create notification
        final notificationRef = _firestore.collection('notifications').doc();
        final message =
            'موعد جديد: ${appointmentData['name'] ?? ''} - ${appointmentData['service'] ?? ''}';
        transaction.set(notificationRef, {
          'appointmentId': appointmentData['id'] ?? '',
          'message': message,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // ✅ Send FCM to admin devices (if tokens stored — for now, local + dashboard only)
        // In real app, you'd send to /topics/admin or stored tokens
      });

      // 🔔 Show local notification (admin side) - only on mobile
      if (!kIsWeb) {
        _showLocalNotification(
          title: 'موعد جديد',
          body: 'تم حجز موعد جديد. يرجى المراجعة.',
        );
      }
    } catch (e) {
      debugPrint('❌ فشل إنشاء تنبيه: $e');
      rethrow;
    }
  }

  void dispose() {
    _notificationsSubscription?.cancel();
    _unreadNotificationsController.close();
  }
}
