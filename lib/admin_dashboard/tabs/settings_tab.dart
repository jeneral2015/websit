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

  // متغيرات لحفظ حالة الشيك بوكس محلياً
  List<String> _tempFeaturedServiceIds = [];
  List<String> _tempFeaturedGalleryIds = [];
  List<String> _tempFeaturedReviewIds = [];
  List<String> _tempFeaturedRatingIds = [];

  // متغيرات النصوص
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('site_data').doc('settings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          var settings = snapshot.data!.data() as Map<String, dynamic>;
          _initializeData(settings);
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('الصور والشعار'),
                Row(
                  children: [
                    _buildImageUploader(
                      'تغيير اللوجو',
                      _logoUrl,
                      () => _uploadFile('logoUrl'),
                    ),
                    const SizedBox(width: 16),
                    _buildImageUploader(
                      'تغيير الخلفية',
                      _backgroundUrl,
                      () => _uploadFile('backgroundUrl'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    if (_logoUrl.isNotEmpty)
                      _buildImagePreview(_logoUrl, 'اللوجو'),
                    if (_backgroundUrl.isNotEmpty)
                      _buildImagePreview(_backgroundUrl, 'الخلفية'),
                  ],
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('بيانات الطبيب'),
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
                _buildTextField('التخصص', _specialty, (v) => _specialty = v),
                _buildTextField('الخبرة', _experience, (v) => _experience = v),
                _buildTextField(
                  'نبذة عن الطبيب',
                  _aboutText,
                  (v) => _aboutText = v,
                  maxLines: 4,
                ),
                _buildTextField('رقم الهاتف', _phone, (v) => _phone = v),
                _buildTextField(
                  'رابط الموقع (Google Maps)',
                  _location,
                  (v) => _location = v,
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('روابط وسائل التواصل الاجتماعي'),
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
                const SizedBox(height: 30),
                _buildSectionTitle('جدول العمل الأسبوعي'),
                _buildWeeklyScheduleTable(),
                const SizedBox(height: 30),
                _buildSectionTitle(
                  'الخدمات المميزة في الصفحة الرئيسية (3 فقط)',
                ),
                _buildFeaturedServicesSelector(),
                const SizedBox(height: 20),
                _buildSectionTitle(
                  'صور المعرض المميزة في الصفحة الرئيسية (3 فقط)',
                ),
                _buildFeaturedGallerySelector(),
                const SizedBox(height: 20),
                _buildSectionTitle(
                  'صور آراء العملاء المميزة في الصفحة الرئيسية (3 فقط)',
                ),
                _buildFeaturedReviewsSelector(),
                _buildFeaturedReviewsSelector(),
                const SizedBox(height: 20),
                _buildSectionTitle(
                  'التقييمات المميزة في الصفحة الرئيسية (4 فقط)',
                ),
                _buildFeaturedRatingsSelector(),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text('حفظ التغييرات'),
                ),
              ],
            ),
          ),
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

    // تهيئة المتغيرات المؤقتة إذا كانت فارغة
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

  Widget _buildFeaturedServicesSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final services = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (context, setStateSelector) {
            final screenWidth = MediaQuery.of(context).size.width;
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
                      } else {
                        if (_tempFeaturedServiceIds.length < 3) {
                          _tempFeaturedServiceIds.add(id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يمكن اختيار 3 خدمات فقط'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    });
                  },
                  child: Container(
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
                        // الصورة التي تملأ الكونتينر بالكامل
                        if (mainImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: mainImage.toString(),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, size: 40),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image, size: 40),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),

                        // النص في الأسفل
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                            child: Text(
                              data['title']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        // الشيك بوكس
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (selected) {
                                setStateSelector(() {
                                  if (selected == true) {
                                    if (_tempFeaturedServiceIds.length < 3) {
                                      _tempFeaturedServiceIds.add(id);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'يمكن اختيار 3 خدمات فقط',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } else {
                                    _tempFeaturedServiceIds.remove(id);
                                  }
                                });
                              },
                              shape: const CircleBorder(),
                              activeColor: Colors.pink,
                            ),
                          ),
                        ),

                        // عداد الخدمات المختارة
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
                                  fontWeight: FontWeight.bold,
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

  Widget _buildFeaturedGallerySelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('gallery').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final images = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final screenWidth = MediaQuery.of(context).size.width;
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
                    setStateDialog(() {
                      if (isSelected) {
                        _tempFeaturedGalleryIds.remove(id);
                      } else {
                        if (_tempFeaturedGalleryIds.length < 3) {
                          _tempFeaturedGalleryIds.add(id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يمكن اختيار 3 صور فقط'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    });
                  },
                  child: Container(
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
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (selected) {
                                setStateDialog(() {
                                  if (selected == true) {
                                    if (_tempFeaturedGalleryIds.length < 3) {
                                      _tempFeaturedGalleryIds.add(id);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'يمكن اختيار 3 صور فقط',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } else {
                                    _tempFeaturedGalleryIds.remove(id);
                                  }
                                });
                              },
                              shape: const CircleBorder(),
                              activeColor: Colors.pink,
                            ),
                          ),
                        ),

                        // عداد الصور المختارة
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
                                  fontWeight: FontWeight.bold,
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

  Widget _buildFeaturedReviewsSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('reviews').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final images = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final screenWidth = MediaQuery.of(context).size.width;
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
                    setStateDialog(() {
                      if (isSelected) {
                        _tempFeaturedReviewIds.remove(id);
                      } else {
                        if (_tempFeaturedReviewIds.length < 3) {
                          _tempFeaturedReviewIds.add(id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يمكن اختيار 3 آراء فقط'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    });
                  },
                  child: Container(
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
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (selected) {
                                setStateDialog(() {
                                  if (selected == true) {
                                    if (_tempFeaturedReviewIds.length < 3) {
                                      _tempFeaturedReviewIds.add(id);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'يمكن اختيار 3 آراء فقط',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } else {
                                    _tempFeaturedReviewIds.remove(id);
                                  }
                                });
                              },
                              shape: const CircleBorder(),
                              activeColor: Colors.pink,
                            ),
                          ),
                        ),

                        // عداد الآراء المختارة
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
                                  fontWeight: FontWeight.bold,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildImageUploader(
    String label,
    String currentUrl,
    VoidCallback onUpload,
  ) {
    return Column(
      children: [
        ElevatedButton(onPressed: onUpload, child: Text(label)),
        if (currentUrl.isNotEmpty) const Text('تم الرفع'),
      ],
    );
  }

  Widget _buildImagePreview(String url, String label) {
    return Column(
      children: [
        Text(label),
        CachedNetworkImage(
          imageUrl: url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
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
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildWeeklyScheduleTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('اليوم')),
          DataColumn(label: Text('مفعل')),
          DataColumn(label: Text('الموقع')),
          DataColumn(label: Text('من')),
          DataColumn(label: Text('إلى')),
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
                TextFormField(
                  initialValue: day['startTime'],
                  onChanged: (v) => day['startTime'] = v,
                ),
              ),
              DataCell(
                TextFormField(
                  initialValue: day['endTime'],
                  onChanged: (v) => day['endTime'] = v,
                ),
              ),
            ],
          );
        }).toList(),
      ),
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
          if (field == 'logoUrl') {
            _logoUrl = url;
          } else if (field == 'backgroundUrl') {
            _backgroundUrl = url;
          }
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

    // إعادة تعيين المتغيرات المؤقتة بعد الحفظ
    _tempFeaturedServiceIds = [];
    _tempFeaturedGalleryIds = [];
    _tempFeaturedReviewIds = [];
    _tempFeaturedRatingIds = [];

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
  }

  Widget _buildFeaturedRatingsSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final ratings = snapshot.data!.docs;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final screenWidth = MediaQuery.of(context).size.width;
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
                    setStateDialog(() {
                      if (isSelected) {
                        _tempFeaturedRatingIds.remove(id);
                      } else {
                        if (_tempFeaturedRatingIds.length < 4) {
                          _tempFeaturedRatingIds.add(id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('يمكن اختيار 4 تقييمات فقط'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    });
                  },
                  child: Container(
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
                              setStateDialog(() {
                                if (selected == true) {
                                  if (_tempFeaturedRatingIds.length < 4) {
                                    _tempFeaturedRatingIds.add(id);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'يمكن اختيار 4 تقييمات فقط',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else {
                                  _tempFeaturedRatingIds.remove(id);
                                }
                              });
                            },
                            shape: const CircleBorder(),
                            activeColor: Colors.pink,
                          ),
                        ),
                        // Counter
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
                                  fontWeight: FontWeight.bold,
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
}
