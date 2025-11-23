import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late final NotificationsManager _notificationsManager;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show popup after first frame + data loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationsManager.showUnreadPopupIfExist(context);
    });
  }

  @override
  void dispose() {
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
                            placeholder: (_, __) => Icon(
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
                // Text container
                SizedBox(
                  height: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${settings['clinicWord'] ?? 'عيادة'} ${settings['doctorName'] ?? 'د/ سارة أحمد'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'لوحة التحكم - ${_tabNames[_tabController.index]}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            toolbarHeight: 80,
            actions: [_buildNotificationsButton()],
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.pink[200],
              indicatorColor: Colors.white,
              isScrollable: true,
              tabs: _tabNames.map((name) => Tab(text: name)).toList(),
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

  Widget _buildNotificationsButton() {
    return StreamBuilder<int>(
      stream: _notificationsManager.unreadNotificationsStream,
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
              onPressed: () =>
                  _notificationsManager.showNotificationsDialog(context),
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
