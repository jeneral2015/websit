import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:websit/services/dropbox_uploader.dart';
import '../notifications_manager.dart';

class SettingsTab extends StatefulWidget {
  final NotificationsManager notificationsManager;

  const SettingsTab({super.key, required this.notificationsManager});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DropboxUploader _dropboxUploader = DropboxUploader();

  // Temporary lists for featured items
  List<String> _tempFeaturedServiceIds = [];
  List<String> _tempFeaturedGalleryIds = [];
  List<String> _tempFeaturedReviewIds = [];
  List<String> _tempFeaturedRatingIds = [];

  // Text variables
  String _logoUrl = '';
  String _backgroundUrl = '';
  String _doctorName = 'د/ سارة أحمد حامد';
  String _specialty = 'استشاري جلدية وتجميل وليزر';
  String _clinicWord = 'عيادة';
  String _welcomeMessage = 'مرحباً بكم في عيادة';
  String _experience = 'بخبرة اكثر من 15 عام فى احدث التقنيات';
  String _aboutText = 'طبيبة متخصصة في أمراض الجلدية...';
  String _phone = '+201234567890';
  String _location = 'https://maps.google.com';
  String _facebookUrl = '';
  String _instagramUrl = '';
  String _tiktokUrl = '';
  String _whatsappUrl = '';

  List<Map<String, dynamic>> _weeklySchedule = [];

  bool _isDataLoaded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('site_data').doc('settings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data!.exists && !_isDataLoaded) {
          var settings = snapshot.data!.data() as Map<String, dynamic>;
          _initializeData(settings);
          _isDataLoaded = true;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 800;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? constraints.maxWidth * 0.15 : 20,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAnimatedSection(
                    title: 'الصور والشعار',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildImageUploader(
                                'تغيير اللوجو',
                                _logoUrl,
                                () => _uploadFile('logoUrl'),
                              ),
                              if (_logoUrl.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildImagePreview(_logoUrl, 'اللوجو'),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _buildImageUploader(
                                'تغيير الخلفية',
                                _backgroundUrl,
                                () => _uploadFile('backgroundUrl'),
                              ),
                              if (_backgroundUrl.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _buildImagePreview(_backgroundUrl, 'الخلفية'),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildAnimatedSection(
                    title: 'بيانات الطبيب',
                    child: Column(
                      children: [
                        _buildTextField(
                          'اسم الطبيب',
                          _doctorName,
                          (v) => _doctorName = v,
                        ),
                        _buildTextField(
                          'مجال العمل',
                          _clinicWord,
                          (v) => _clinicWord = v,
                        ),
                        _buildTextField(
                          'رسالة الترحيب',
                          _welcomeMessage,
                          (v) => _welcomeMessage = v,
                        ),
                        _buildTextField(
                          'التخصص',
                          _specialty,
                          (v) => _specialty = v,
                        ),
                        _buildTextField(
                          'الخبرة',
                          _experience,
                          (v) => _experience = v,
                        ),
                        _buildTextField(
                          'نبذة عن الطبيب',
                          _aboutText,
                          (v) => _aboutText = v,
                          maxLines: 4,
                        ),
                        _buildTextField(
                          'رقم الهاتف',
                          _phone,
                          (v) => _phone = v,
                        ),
                        _buildTextField(
                          'رابط الموقع (Google Maps)',
                          _location,
                          (v) => _location = v,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildAnimatedSection(
                    title: 'روابط وسائل التواصل الاجتماعي',
                    child: Column(
                      children: [
                        _buildTextField(
                          'رابط فيسبوك',
                          _facebookUrl,
                          (v) => _facebookUrl = v,
                          icon: Icons.facebook,
                        ),
                        _buildTextField(
                          'رابط إنستغرام',
                          _instagramUrl,
                          (v) => _instagramUrl = v,
                          icon: FontAwesomeIcons.instagram,
                        ),
                        _buildTextField(
                          'رابط تيك توك',
                          _tiktokUrl,
                          (v) => _tiktokUrl = v,
                          icon: FontAwesomeIcons.tiktok,
                        ),
                        _buildTextField(
                          'رقم واتساب',
                          _whatsappUrl,
                          (v) => _whatsappUrl = v,
                          icon: FontAwesomeIcons.whatsapp,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildAnimatedSection(
                    title: 'جدول العمل الأسبوعي',
                    child: _buildWeeklyScheduleTable(isWideScreen),
                  ),
                  const SizedBox(height: 30),
                  _buildAnimatedSection(
                    title: 'الخدمات المميزة في الصفحة الرئيسية (3 فقط)',
                    child: _buildFeaturedServicesSelector(constraints.maxWidth),
                  ),
                  const SizedBox(height: 30),
                  _buildAnimatedSection(
                    title: 'صور المعرض المميزة في الصفحة الرئيسية (3 فقط)',
                    child: _buildFeaturedGallerySelector(constraints.maxWidth),
                  ),
                  const SizedBox(height: 30),
                  _buildAnimatedSection(
                    title:
                        'صور آراء العملاء المميزة في الصفحة الرئيسية (3 فقط)',
                    child: _buildFeaturedReviewsSelector(constraints.maxWidth),
                  ),
                  const SizedBox(height: 30),
                  _buildAnimatedSection(
                    title: 'التقييمات المميزة في الصفحة الرئيسية (4 فقط)',
                    child: _buildFeaturedRatingsSelector(constraints.maxWidth),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'حفظ التغييرات',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _initializeData(Map<String, dynamic> settings) {
    _logoUrl = settings['logoUrl'] ?? '';
    _backgroundUrl = settings['backgroundUrl'] ?? '';
    _doctorName = settings['doctorName'] ?? 'د/ سارة أحمد حامد';
    _specialty = settings['specialty'] ?? 'استشاري جلدية وتجميل وليزر';
    _clinicWord = settings['clinicWord'] ?? 'عيادة';
    _welcomeMessage = settings['welcomeMessage'] ?? 'مرحباً بكم في عيادة';
    _experience =
        settings['experience'] ?? 'بخبرة اكثر من 15 عام فى احدث التقنيات';
    _aboutText = settings['aboutText'] ?? 'طبيبة متخصصة في أمراض الجلدية...';
    _phone = settings['phone'] ?? '+201234567890';
    _location = settings['location'] ?? 'https://maps.google.com';
    _facebookUrl = settings['facebookUrl'] ?? '';
    _instagramUrl = settings['instagramUrl'] ?? '';
    _tiktokUrl = settings['tiktokUrl'] ?? '';
    _whatsappUrl = settings['whatsappUrl'] ?? '';

    List<String> featuredServiceIds = (settings['featuredServiceIds'] is List)
        ? (settings['featuredServiceIds'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
        : [];

    List<String> featuredGalleryIds = (settings['featuredGalleryIds'] is List)
        ? (settings['featuredGalleryIds'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
        : [];

    List<String> featuredReviewIds = (settings['featuredReviewIds'] is List)
        ? (settings['featuredReviewIds'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
        : [];

    List<String> featuredRatingIds = (settings['featuredRatingIds'] is List)
        ? (settings['featuredRatingIds'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
        : [];

    if (_tempFeaturedServiceIds.isEmpty) {
      _tempFeaturedServiceIds = List.from(featuredServiceIds);
    }
    if (_tempFeaturedGalleryIds.isEmpty) {
      _tempFeaturedGalleryIds = List.from(featuredGalleryIds);
    }
    if (_tempFeaturedReviewIds.isEmpty) {
      _tempFeaturedReviewIds = List.from(featuredReviewIds);
    }
    if (_tempFeaturedRatingIds.isEmpty) {
      _tempFeaturedRatingIds = List.from(featuredRatingIds);
    }

    _weeklySchedule =
        (settings['weeklySchedule'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>()
            .toList() ??
        [];

    if (_weeklySchedule.isEmpty) {
      List<String> days = [
        'السبت',
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
      ];
      _weeklySchedule = List.generate(
        7,
        (i) => {
          'day': days[i],
          'enabled': i < 6,
          'location': '',
          'startTime': '9:00 ص',
          'endTime': '5:00 م',
        },
      );
    }
  }

  Widget _buildAnimatedSection({required String title, required Widget child}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildImageUploader(
    String label,
    String currentUrl,
    VoidCallback onUpload,
  ) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onUpload,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(label),
        ),
        if (currentUrl.isNotEmpty) const SizedBox(height: 8),
        if (currentUrl.isNotEmpty)
          const Text('تم الرفع', style: TextStyle(color: Colors.green)),
      ],
    );
  }

  Widget _buildImagePreview(String url, String label) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: url,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    int maxLines = 1,
    IconData? icon,
  }) {
    final controller = TextEditingController(text: value);
    controller.addListener(() => onChanged(controller.text));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.pink) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.pink, width: 2),
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    Map<String, dynamic> day,
    String key,
  ) async {
    String initialTimeStr = day[key] as String;

    // Replace Arabic numerals with English numerals for parsing
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < arabicDigits.length; i++) {
      initialTimeStr = initialTimeStr.replaceAll(arabicDigits[i], i.toString());
    }

    TimeOfDay initialTime = TimeOfDay.now();

    try {
      // Simple parsing for "9:00 AM" or "9:00 ص" format
      final parts = initialTimeStr.split(' ');
      if (parts.length == 2) {
        final timeParts = parts[0].split(':');
        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final period = parts[1];

        // Handle both Arabic (ص/م) and English (AM/PM) formats
        if (period == 'م' || period == 'PM') {
          if (hour != 12) hour += 12;
        } else if (period == 'ص' || period == 'AM') {
          if (hour == 12) hour = 0;
        }

        initialTime = TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {
      // Fallback to current time if parsing fails
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.pink),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      // We can construct the string manually to ensure consistency with "AM/PM"
      final hour = picked.hourOfPeriod == 0
          ? 12
          : picked.hourOfPeriod > 12
          ? picked.hourOfPeriod - 12
          : picked.hourOfPeriod;

      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';

      // Ensure English numerals are used in the output string
      final formattedTime = '$hour:$minute $period';

      setState(() {
        day[key] = formattedTime;
      });
    }
  }

  Widget _buildWeeklyScheduleTable(bool isWideScreen) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: isWideScreen ? 60 : 30,
        columns: const [
          DataColumn(
            label: Text('اليوم', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('مفعل', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'الموقع',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('من', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('إلى', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        rows: _weeklySchedule.map((day) {
          return DataRow(
            cells: [
              DataCell(Text(day['day'])),
              DataCell(
                Checkbox(
                  value: day['enabled'],
                  onChanged: (v) => setState(() => day['enabled'] = v ?? false),
                ),
              ),
              DataCell(
                TextFormField(
                  initialValue: day['location'],
                  onChanged: (v) => day['location'] = v,
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _selectTime(context, day, 'startTime'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(day['startTime']),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.pink,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _selectTime(context, day, 'endTime'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(day['endTime']),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.pink,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedServicesSelector(double screenWidth) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final services = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (context, setStateSelector) {
            final crossAxisCount = screenWidth > 1200
                ? 4
                : screenWidth > 600
                ? 3
                : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final doc = services[index];
                final data = doc.data() as Map<String, dynamic>;
                final id = doc.id;
                final isSelected = _tempFeaturedServiceIds.contains(id);
                final mainImage =
                    data['mainImage'] ??
                    (data['images'] is List &&
                            (data['images'] as List).isNotEmpty
                        ? (data['images'] as List).first
                        : null);
                return GestureDetector(
                  onTap: () {
                    setStateSelector(() {
                      if (isSelected) {
                        _tempFeaturedServiceIds.remove(id);
                      } else if (_tempFeaturedServiceIds.length < 3) {
                        _tempFeaturedServiceIds.add(id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يمكن اختيار 3 خدمات فقط'),
                          ),
                        );
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.pink : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.pink[50] : Colors.white,
                    ),
                    child: Stack(
                      children: [
                        if (mainImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: mainImage.toString(),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        else
                          Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              data['title']?.toString() ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (selected) {
                              setStateSelector(() {
                                if (selected == true &&
                                    _tempFeaturedServiceIds.length < 3) {
                                  _tempFeaturedServiceIds.add(id);
                                } else if (selected == false) {
                                  _tempFeaturedServiceIds.remove(id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('يمكن اختيار 3 خدمات فقط'),
                                    ),
                                  );
                                }
                              });
                            },
                            shape: const CircleBorder(),
                            activeColor: Colors.pink,
                          ),
                        ),
                        if (_tempFeaturedServiceIds.isNotEmpty)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_tempFeaturedServiceIds.length}/3',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturedGallerySelector(double screenWidth) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('gallery').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final images = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (context, setStateSelector) {
            final crossAxisCount = screenWidth > 1200
                ? 4
                : screenWidth > 600
                ? 3
                : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final doc = images[index];
                final id = doc.id;
                final isSelected = _tempFeaturedGalleryIds.contains(id);
                return GestureDetector(
                  onTap: () {
                    setStateSelector(() {
                      if (isSelected) {
                        _tempFeaturedGalleryIds.remove(id);
                      } else if (_tempFeaturedGalleryIds.length < 3) {
                        _tempFeaturedGalleryIds.add(id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يمكن اختيار 3 صور فقط'),
                          ),
                        );
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.pink : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.pink[50] : Colors.white,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: doc['url'] ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (selected) {
                              setStateSelector(() {
                                if (selected == true &&
                                    _tempFeaturedGalleryIds.length < 3) {
                                  _tempFeaturedGalleryIds.add(id);
                                } else if (selected == false) {
                                  _tempFeaturedGalleryIds.remove(id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('يمكن اختيار 3 صور فقط'),
                                    ),
                                  );
                                }
                              });
                            },
                            shape: const CircleBorder(),
                            activeColor: Colors.pink,
                          ),
                        ),
                        if (_tempFeaturedGalleryIds.isNotEmpty)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_tempFeaturedGalleryIds.length}/3',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturedReviewsSelector(double screenWidth) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('reviews').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final images = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (context, setStateSelector) {
            final crossAxisCount = screenWidth > 1200
                ? 4
                : screenWidth > 600
                ? 3
                : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final doc = images[index];
                final id = doc.id;
                final isSelected = _tempFeaturedReviewIds.contains(id);
                return GestureDetector(
                  onTap: () {
                    setStateSelector(() {
                      if (isSelected) {
                        _tempFeaturedReviewIds.remove(id);
                      } else if (_tempFeaturedReviewIds.length < 3) {
                        _tempFeaturedReviewIds.add(id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يمكن اختيار 3 آراء فقط'),
                          ),
                        );
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.pink : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.pink[50] : Colors.white,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: doc['url'] ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (selected) {
                              setStateSelector(() {
                                if (selected == true &&
                                    _tempFeaturedReviewIds.length < 3) {
                                  _tempFeaturedReviewIds.add(id);
                                } else if (selected == false) {
                                  _tempFeaturedReviewIds.remove(id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('يمكن اختيار 3 آراء فقط'),
                                    ),
                                  );
                                }
                              });
                            },
                            shape: const CircleBorder(),
                            activeColor: Colors.pink,
                          ),
                        ),
                        if (_tempFeaturedReviewIds.isNotEmpty)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_tempFeaturedReviewIds.length}/3',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFeaturedRatingsSelector(double screenWidth) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final ratings = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (context, setStateSelector) {
            final crossAxisCount = screenWidth > 1200
                ? 4
                : screenWidth > 600
                ? 3
                : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: ratings.length,
              itemBuilder: (context, index) {
                final doc = ratings[index];
                final id = doc.id;
                final data = doc.data() as Map<String, dynamic>;
                final isSelected = _tempFeaturedRatingIds.contains(id);
                final clientName = data['clientName'] ?? 'عميل';
                final stars = data['stars'] ?? 5;
                final comment = data['comment'] ?? '';
                return GestureDetector(
                  onTap: () {
                    setStateSelector(() {
                      if (isSelected) {
                        _tempFeaturedRatingIds.remove(id);
                      } else if (_tempFeaturedRatingIds.length < 4) {
                        _tempFeaturedRatingIds.add(id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('يمكن اختيار 4 تقييمات فقط'),
                          ),
                        );
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.pink : Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? Colors.pink[50] : Colors.white,
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$stars',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              clientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                comment,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (selected) {
                              setStateSelector(() {
                                if (selected == true &&
                                    _tempFeaturedRatingIds.length < 4) {
                                  _tempFeaturedRatingIds.add(id);
                                } else if (selected == false) {
                                  _tempFeaturedRatingIds.remove(id);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'يمكن اختيار 4 تقييمات فقط',
                                      ),
                                    ),
                                  );
                                }
                              });
                            },
                            shape: const CircleBorder(),
                            activeColor: Colors.pink,
                          ),
                        ),
                        if (_tempFeaturedRatingIds.isNotEmpty)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_tempFeaturedRatingIds.length}/4',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _uploadFile(String field) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      final url = await _dropboxUploader.uploadFile(
        result.files.single.bytes!,
        result.files.single.name,
        docId: field,
      );
      if (url != null) {
        await _firestore.collection('site_data').doc('settings').update({
          field: url,
        });
        setState(() {
          if (field == 'logoUrl') _logoUrl = url;
          if (field == 'backgroundUrl') _backgroundUrl = url;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    await _firestore.collection('site_data').doc('settings').set({
      'logoUrl': _logoUrl,
      'backgroundUrl': _backgroundUrl,
      'doctorName': _doctorName,
      'specialty': _specialty,
      'clinicWord': _clinicWord,
      'welcomeMessage': _welcomeMessage,
      'experience': _experience,
      'aboutText': _aboutText,
      'phone': _phone,
      'location': _location,
      'facebookUrl': _facebookUrl,
      'instagramUrl': _instagramUrl,
      'tiktokUrl': _tiktokUrl,
      'whatsappUrl': _whatsappUrl,
      'weeklySchedule': _weeklySchedule,
      'featuredServiceIds': _tempFeaturedServiceIds,
      'featuredGalleryIds': _tempFeaturedGalleryIds,
      'featuredReviewIds': _tempFeaturedReviewIds,
      'featuredRatingIds': _tempFeaturedRatingIds,
    }, SetOptions(merge: true));

    _tempFeaturedServiceIds = [];
    _tempFeaturedGalleryIds = [];
    _tempFeaturedReviewIds = [];
    _tempFeaturedRatingIds = [];

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
    }
  }
}
