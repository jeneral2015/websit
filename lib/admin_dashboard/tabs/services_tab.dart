import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/dropbox_uploader.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DropboxUploader _dropboxUploader = DropboxUploader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo),
                label: const Text('إضافة خدمة جديدة'),
                onPressed: _addService,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
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
                  final images = (data['images'] is List)
                      ? (data['images'] as List<dynamic>)
                            .map((e) => e.toString())
                            .toList()
                      : <String>[];
                  final mainImage = (data['mainImage'] is String)
                      ? data['mainImage']
                      : (images.isNotEmpty ? images[0] : '');
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: mainImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: mainImage,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image),
                            )
                          : const Icon(Icons.image),
                      title: Text(data['title'] ?? ''),
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
                            useUniqueName: true,
                          );
                          if (url != null && context.mounted) {
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
                  child: RadioGroup<String>(
                    groupValue: mainImage,
                    onChanged: (val) {
                      setStateDialog(() {
                        mainImage = val;
                      });
                    },
                    child: ListView.separated(
                      itemCount: images.length,
                      separatorBuilder: (ctx, i) => const Divider(),
                      itemBuilder: (context, i) {
                        final url = images[i];
                        final isMain = url == mainImage;
                        return RadioListTile<String>(
                          value: url,
                          title: SizedBox(
                            height: 100,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (isMain)
                                  const Icon(Icons.star, color: Colors.amber),
                              ],
                            ),
                          ),
                          secondary: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('تأكيد الحذف'),
                                  content: const Text(
                                    'هل أنت متأكد من حذف هذه الصورة؟',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('إلغاء'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        // حذف الصورة الفردية فوراً
                                        await _deleteSingleImage(url);
                                        setStateDialog(() {
                                          images.removeAt(i);
                                          if (mainImage == url) {
                                            mainImage = images.isNotEmpty
                                                ? images.first
                                                : null;
                                          }
                                        });
                                      },
                                      child: const Text('حذف'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
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
                // 3. تحديث Firestore
                await _firestore.collection('services').doc(serviceId).update({
                  'images': images,
                  'mainImage': mainImage,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSingleImage(String imageUrl) async {
    try {
      await _dropboxUploader.deleteFile(imageUrl);
      debugPrint('DEBUG: Successfully deleted single image: $imageUrl');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الصورة من التخزين'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('ERROR: Failed to delete image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addService() => _showServiceDialog();

  void _editService(String id, Map<String, dynamic> data) =>
      _showServiceDialog(id: id, initialData: data);

  void _showServiceDialog({String? id, Map<String, dynamic>? initialData}) {
    final titleCtrl = TextEditingController(text: initialData?['title'] ?? '');
    final descCtrl = TextEditingController(
      text: initialData?['description'] ?? '',
    );
    List<String> images = (initialData?['images'] is List)
        ? (initialData!['images'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
        : [];
    String? mainImage = (initialData?['mainImage'] is String)
        ? initialData!['mainImage']
        : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(id == null ? 'إضافة خدمة' : 'تعديل خدمة'),
          content: SizedBox(
            width: 500,
            height: 500,
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
                            useUniqueName: true,
                          );
                          if (url != null && context.mounted) {
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
                  Expanded(
                    child: RadioGroup<String>(
                      groupValue: mainImage,
                      onChanged: (val) {
                        setStateDialog(() {
                          mainImage = val;
                        });
                      },
                      child: ListView.separated(
                        itemCount: images.length,
                        separatorBuilder: (ctx, i) => const Divider(),
                        itemBuilder: (context, i) {
                          final url = images[i];
                          final isMain = url == mainImage;
                          return RadioListTile<String>(
                            value: url,
                            title: SizedBox(
                              height: 80,
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                  if (isMain) ...[
                                    const SizedBox(width: 16),
                                    const Icon(Icons.star, color: Colors.amber),
                                  ],
                                ],
                              ),
                            ),
                            secondary: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('تأكيد الحذف'),
                                    content: const Text(
                                      'هل أنت متأكد من حذف هذه الصورة؟',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('إلغاء'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await _deleteSingleImage(url);
                                          setStateDialog(() {
                                            images.removeAt(i);
                                            if (mainImage == url) {
                                              mainImage = images.isNotEmpty
                                                  ? images.first
                                                  : null;
                                            }
                                          });
                                        },
                                        child: const Text('حذف'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
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
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteService(String id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف الخدمة وجميع صورها؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. جلب بيانات الخدمة لحذف الصور
              final doc = await _firestore.collection('services').doc(id).get();
              if (doc.exists) {
                final data = doc.data() as Map<String, dynamic>;
                final images = (data['images'] is List)
                    ? (data['images'] as List<dynamic>)
                          .map((e) => e.toString())
                          .toList()
                    : <String>[];

                // 2. حذف كل الصور من Dropbox
                for (final url in images) {
                  await _dropboxUploader.deleteFile(url);
                  debugPrint('DEBUG: Deleted image from Dropbox: $url');
                }

                // 3. حذف الصورة الرئيسية إذا كانت مختلفة
                final mainImage = data['mainImage']?.toString();
                if (mainImage != null &&
                    mainImage.isNotEmpty &&
                    !images.contains(mainImage)) {
                  await _dropboxUploader.deleteFile(mainImage);
                  debugPrint(
                    'DEBUG: Deleted main image from Dropbox: $mainImage',
                  );
                }
              }

              // 4. حذف المستند من Firestore
              await _firestore.collection('services').doc(id).delete();

              if (ctx.mounted) Navigator.pop(ctx);

              // إشعار بنجاح العملية
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الخدمة وجميع صورها بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
