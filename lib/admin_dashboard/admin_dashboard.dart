import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:websit/auth/auth_service.dart'; // ✅ Moved import to top
import 'tabs/settings_tab.dart';
import 'tabs/services_tab.dart';
import 'tabs/gallery_tab.dart';
import 'tabs/reviews_tab.dart';
import 'tabs/appointments_tab.dart';
import 'tabs/statistics_tab.dart';
import 'tabs/ratings_management_tab.dart';
import 'notifications_manager.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late final NotificationsManager _notificationsManager;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _hasShownInitialNotifications = false;
  StreamSubscription<int>? _notificationSubscription;

  final List<String> _tabNames = [
    'الإعدادات',
    'الخدمات',
    'المعرض',
    'آراء العملاء',
    'المواعيد',
    'التقييمات',
    'الإحصائيات',
  ];

  @override
  void initState() {
    super.initState();
    _notificationsManager = NotificationsManager();
    _tabController = TabController(length: 7, vsync: this);
    _notificationsManager.initializeNotifications();

    // Listen to notifications stream and show popup when unread notifications arrive
    _notificationSubscription = _notificationsManager.unreadNotificationsStream
        .listen((unreadCount) {
          if (!_hasShownInitialNotifications && unreadCount > 0) {
            _hasShownInitialNotifications = true;
            // Use a small delay to ensure UI is ready
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                _notificationsManager.showUnreadPopupIfExist(context);
              }
            });
          }
        });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _notificationsManager.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('site_data').doc('settings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final settings = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final bgUrl = settings['backgroundUrl'];
        final hasValidBg = bgUrl is String && bgUrl.startsWith('http');

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo container
                SizedBox(
                  height: 60,
                  width: 60,
                  child: ClipOval(
                    child:
                        settings['logoUrl'] != null &&
                            settings['logoUrl'].isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: settings['logoUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Icon(
                              Icons.medical_services,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.medical_services,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Text container - wrapped in Flexible to prevent overflow
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${settings['clinicWord'] ?? 'عيادة'} ${settings['doctorName'] ?? 'د/ سارة أحمد'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'لوحة التحكم - ${_tabNames[_tabController.index]}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            toolbarHeight: 80,
            actions: [
              _buildNotificationsButton(),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  _showLogoutConfirmation(context);
                },
                tooltip: 'تسجيل الخروج',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Center(
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black,
                  indicatorColor: Colors.white,
                  isScrollable: true,
                  tabs: _tabNames.map((name) => Tab(text: name)).toList(),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              // Background image
              if (hasValidBg)
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(bgUrl),
                      fit: BoxFit.fill,
                    ),
                  ),
                )
              else
                Container(color: Colors.pink[50]),

              // Content
              TabBarView(
                controller: _tabController,
                children: [
                  SettingsTab(notificationsManager: _notificationsManager),
                  const ServicesTab(),
                  const GalleryTab(),
                  const ReviewsTab(),
                  AppointmentsTab(notificationsManager: _notificationsManager),
                  const RatingsManagementTab(),
                  StatisticsTab(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().logout();
              // AuthGate will handle the redirect to login page automatically
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsButton() {
    return StreamBuilder<int>(
      stream: _notificationsManager.unreadNotificationsStream,
      initialData: _notificationsManager.unreadCount, // ✅ Show initial count
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                unread > 0 ? Icons.notifications : Icons.notifications_none,
                color: unread > 0 ? Colors.white : Colors.pink[100],
                size: 28,
              ),
              onPressed: () {
                if (unread > 0) {
                  _notificationsManager.showSequentialNotifications(context);
                } else {
                  _notificationsManager.showNotificationsDialog(context);
                }
              },
              tooltip: 'التنبيهات',
            ),
            if (unread > 0)
              Positioned(
                top: 4,
                right: 4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: unread >= 10 ? 24 : 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: unread > 5 ? Colors.red : Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
