// تم التحديث بواسطة Grok - دعم صور متعددة للخدمات + اختيار 3 خدمات وصور معرض في الصفحة الرئيسية
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:websit/services/dropbox_uploader.dart';
import 'package:websit/services/firebase_paths.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DropboxUploader _dropboxUploader = DropboxUploader();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم - عيادة د/ سارة'),
          backgroundColor: Colors.pink[800],
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.pink[200],
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'الإعدادات'),
              Tab(text: 'الخدمات'),
              Tab(text: 'المعرض'),
              Tab(text: 'التقييمات'),
              Tab(text: 'المواعيد'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSettingsTab(),
            _buildServicesTab(),
            _buildGalleryTab(),
            _buildReviewsTab(),
            _buildAppointmentsTab(),
          ],
        ),
      ),
    );
  }

  // === الإعدادات ===
  Widget _buildSettingsTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('site_data').doc('settings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var settings = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String logoUrl = settings['logoUrl'] ?? '';
        String backgroundUrl = settings['backgroundUrl'] ?? '';
        String doctorName = settings['doctorName'] ?? 'د/ سارة أحمد حامد';
        String specialty =
            settings['specialty'] ?? 'استشاري جلدية وتجميل وليزر';
        String experience =
            settings['experience'] ?? 'بخبرة اكثر من 15 عام فى احدث التقنيات';
        String aboutText =
            settings['aboutText'] ?? 'طبيبة متخصصة في أمراض الجلدية...';
        String phone = settings['phone'] ?? '+201234567890';
        String location = settings['location'] ?? 'https://maps.google.com';
        String facebookUrl = settings['facebookUrl'] ?? '';
        String instagramUrl = settings['instagramUrl'] ?? '';
        String tiktokUrl = settings['tiktokUrl'] ?? '';
        String whatsappUrl = settings['whatsappUrl'] ?? '';

        List<String> featuredServiceIds = List<String>.from(
          settings['featuredServiceIds'] ?? [],
        );
        List<String> featuredGalleryIds = List<String>.from(
          settings['featuredGalleryIds'] ?? [],
        );

        List<Map<String, dynamic>> weeklySchedule =
            (settings['weeklySchedule'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .toList() ??
            [];

        if (weeklySchedule.isEmpty) {
          List<String> days = [
            'السبت',
            'الأحد',
            'الاثنين',
            'الثلاثاء',
            'الأربعاء',
            'الخميس',
            'الجمعة',
          ];
          weeklySchedule = List.generate(
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

        List<Map<String, dynamic>> localSchedule = weeklySchedule
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

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
                      logoUrl,
                      () => _uploadFile('logoUrl', logoUrl),
                    ),
                    const SizedBox(width: 16),
                    _buildImageUploader(
                      'تغيير الخلفية',
                      backgroundUrl,
                      () => _uploadFile('backgroundUrl', backgroundUrl),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    if (logoUrl.isNotEmpty)
                      _buildImagePreview(logoUrl, 'اللوجو'),
                    if (backgroundUrl.isNotEmpty)
                      _buildImagePreview(backgroundUrl, 'الخلفية'),
                  ],
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('بيانات الطبيب'),
                _buildTextField(
                  'اسم الطبيب',
                  doctorName,
                  (v) => doctorName = v,
                ),
                _buildTextField('التخصص', specialty, (v) => specialty = v),
                _buildTextField('الخبرة', experience, (v) => experience = v),
                _buildTextField(
                  'نبذة عن الطبيب',
                  aboutText,
                  (v) => aboutText = v,
                  maxLines: 4,
                ),
                _buildTextField('رقم الهاتف', phone, (v) => phone = v),
                _buildTextField(
                  'رابط الموقع (Google Maps)',
                  location,
                  (v) => location = v,
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('روابط وسائل التواصل الاجتماعي'),
                _buildTextField(
                  'رابط فيسبوك',
                  facebookUrl,
                  (v) => facebookUrl = v,
                  icon: Icons.facebook,
                ),
                _buildTextField(
                  'رابط إنستغرام',
                  instagramUrl,
                  (v) => instagramUrl = v,
                  icon: FontAwesomeIcons.instagram,
                ),
                _buildTextField(
                  'رابط تيك توك',
                  tiktokUrl,
                  (v) => tiktokUrl = v,
                  icon: FontAwesomeIcons.tiktok,
                ),
                _buildTextField(
                  'رقم واتساب',
                  whatsappUrl,
                  (v) => whatsappUrl = v,
                  icon: FontAwesomeIcons.whatsapp,
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('جدول العمل الأسبوعي'),
                _buildWeeklyScheduleTable(localSchedule),
                const SizedBox(height: 30),
                _buildSectionTitle(
                  'الخدمات المميزة في الصفحة الرئيسية (3 فقط)',
                ),
                _buildFeaturedServicesSelector(featuredServiceIds),
                const SizedBox(height: 20),
                _buildSectionTitle(
                  'صور المعرض المميزة في الصفحة الرئيسية (6 فقط)',
                ),
                _buildFeaturedGallerySelector(featuredGalleryIds),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => _saveSettings(
                    logoUrl,
                    backgroundUrl,
                    doctorName,
                    specialty,
                    experience,
                    aboutText,
                    phone,
                    location,
                    facebookUrl,
                    instagramUrl,
                    tiktokUrl,
                    whatsappUrl,
                    localSchedule,
                    featuredServiceIds,
                    featuredGalleryIds,
                  ),
                  child: const Text('حفظ التغييرات'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedServicesSelector(List<String> selectedIds) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final services = snapshot.data!.docs;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: services.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            final isSelected = selectedIds.contains(id);
            return FilterChip(
              label: Text(data['title']),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (selectedIds.length < 3) selectedIds.add(id);
                  } else {
                    selectedIds.remove(id);
                  }
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFeaturedGallerySelector(List<String> selectedIds) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(FirebasePaths.gallery).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final images = snapshot.data!.docs;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: images.map((doc) {
            final id = doc.id;
            final isSelected = selectedIds.contains(id);
            return FilterChip(
              avatar: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(doc['url']),
              ),
              label: const Text('صورة'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (selectedIds.length < 6) selectedIds.add(id);
                  } else {
                    selectedIds.remove(id);
                  }
                });
              },
            );
          }).toList(),
        );
      },
    );
  }

  // === الخدمات ===
  Widget _buildServicesTab() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _addService,
          child: const Text('إضافة خدمة جديدة'),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('services').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  final doc = snapshot.data!.docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final images = List<String>.from(data['images'] ?? []);
                  final mainImage = data['mainImage'] ?? images.isNotEmpty
                      ? images[0]
                      : '';
                  return Card(
                    child: ListTile(
                      leading: mainImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: mainImage,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image),
                      title: Text(data['title']),
                      subtitle: Text('صور: ${images.length}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image),
                            onPressed: () =>
                                _manageServiceImages(doc.id, images, mainImage),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editService(doc.id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteService(doc.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _manageServiceImages(
    String serviceId,
    List<String> currentImages,
    String currentMain,
  ) {
    List<String> images = List.from(currentImages);
    String? mainImage = currentMain;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('إدارة صور الخدمة'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: true,
                    );
                    if (result != null) {
                      for (var file in result.files) {
                        if (file.bytes != null) {
                          final url = await _dropboxUploader.uploadFile(
                            file.bytes!,
                            file.name,
                            docId: 'services',
                          );
                          if (url != null) {
                            setStateDialog(() => images.add(url));
                          }
                        }
                      }
                    }
                  },
                  child: const Text('رفع صور متعددة'),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: images.length,
                    itemBuilder: (context, i) {
                      final url = images[i];
                      final isMain = url == mainImage;
                      return Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          if (isMain)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(Icons.star, color: Colors.amber),
                            ),
                          Positioned(
                            top: 4,
                            left: 4,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setStateDialog(() => images.removeAt(i)),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Radio<String>(
                              value: url,
                              groupValue: mainImage,
                              onChanged: (v) =>
                                  setStateDialog(() => mainImage = v),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('services').doc(serviceId).update({
                  'images': images,
                  'mainImage': mainImage,
                });
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _addService() => _showServiceDialog();
  void _editService(String id, Map<String, dynamic> data) =>
      _showServiceDialog(id: id, initialData: data);

  void _showServiceDialog({String? id, Map<String, dynamic>? initialData}) {
    final titleCtrl = TextEditingController(text: initialData?['title'] ?? '');
    final descCtrl = TextEditingController(
      text: initialData?['description'] ?? '',
    );
    List<String> images = List<String>.from(initialData?['images'] ?? []);
    String? mainImage = initialData?['mainImage'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(id == null ? 'إضافة خدمة' : 'تعديل خدمة'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: true,
                    );
                    if (result != null) {
                      for (var file in result.files) {
                        if (file.bytes != null) {
                          final url = await _dropboxUploader.uploadFile(
                            file.bytes!,
                            file.name,
                            docId: 'services',
                          );
                          if (url != null) {
                            setStateDialog(() => images.add(url));
                          }
                        }
                      }
                    }
                  },
                  child: const Text('رفع صور متعددة'),
                ),
                const SizedBox(height: 16),
                if (images.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, i) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CachedNetworkImage(
                                imageUrl: images[i],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    setStateDialog(() => images.removeAt(i)),
                              ),
                            ),
                            if (images[i] == mainImage)
                              const Positioned(
                                bottom: 0,
                                left: 0,
                                child: Icon(Icons.star, color: Colors.amber),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Radio<String>(
                                value: images[i],
                                groupValue: mainImage,
                                onChanged: (v) =>
                                    setStateDialog(() => mainImage = v),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'images': images,
                  'mainImage':
                      mainImage ?? (images.isNotEmpty ? images[0] : ''),
                };
                if (id == null) {
                  await _firestore.collection('services').add(data);
                } else {
                  await _firestore.collection('services').doc(id).update(data);
                }
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteService(String id) =>
      _firestore.collection('services').doc(id).delete();

  // === المعرض ===
  Widget _buildGalleryTab() {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.add_a_photo),
          label: const Text('إضافة صورة'),
          onPressed: _uploadImage,
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection(FirebasePaths.gallery).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, i) {
                  final doc = snapshot.data!.docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  return Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: data['url'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteImage(doc.id),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _uploadImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      final url = await _dropboxUploader.uploadFile(
        result.files.single.bytes!,
        result.files.single.name,
        docId: FirebasePaths.gallery,
      );
      if (url != null) {
        await _firestore.collection(FirebasePaths.gallery).add({
          'url': url,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _deleteImage(String id) =>
      _firestore.collection(FirebasePaths.gallery).doc(id).delete();

  // === التقييمات والمواعيد ===
  Widget _buildReviewsTab() =>
      const Center(child: Text('إدارة التقييمات - قيد التطوير'));

  Widget _buildAppointmentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, i) {
            final data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(data['name']),
                subtitle: Text(
                  '${data['service']} - ${data['date']} ${data['time']}',
                ),
                trailing: Text(data['phone']),
              ),
            );
          },
        );
      },
    );
  }

  // === أدوات مساعدة ===
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

  Widget _buildWeeklyScheduleTable(List<Map<String, dynamic>> schedule) {
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
        rows: schedule.map((day) {
          return DataRow(
            cells: [
              DataCell(Text(day['day'])),
              DataCell(
                Checkbox(
                  value: day['enabled'],
                  onChanged: (v) => setState(() => day['enabled'] = v),
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

  Future<void> _uploadFile(String field, String currentUrl) async {
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
      }
    }
  }

  Future<void> _saveSettings(
    String logoUrl,
    String backgroundUrl,
    String doctorName,
    String specialty,
    String experience,
    String aboutText,
    String phone,
    String location,
    String facebookUrl,
    String instagramUrl,
    String tiktokUrl,
    String whatsappUrl,
    List<Map<String, dynamic>> schedule,
    List<String> featuredServiceIds,
    List<String> featuredGalleryIds,
  ) async {
    await _firestore.collection('site_data').doc('settings').set({
      'logoUrl': logoUrl,
      'backgroundUrl': backgroundUrl,
      'doctorName': doctorName,
      'specialty': specialty,
      'experience': experience,
      'aboutText': aboutText,
      'phone': phone,
      'location': location,
      'facebookUrl': facebookUrl,
      'instagramUrl': instagramUrl,
      'tiktokUrl': tiktokUrl,
      'whatsappUrl': whatsappUrl,
      'weeklySchedule': schedule,
      'featuredServiceIds': featuredServiceIds,
      'featuredGalleryIds': featuredGalleryIds,
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
  }
}
