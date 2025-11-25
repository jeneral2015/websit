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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _addService,
            child: const Text('إضافة خدمة جديدة'),
          ),
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
                              setStateDialog(() {
                                images.removeAt(i);
                                if (mainImage == url) {
                                  mainImage = images.isNotEmpty
                                      ? images.first
                                      : null;
                                }
                              });
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
                                setStateDialog(() {
                                  images.removeAt(i);
                                  if (mainImage == url) {
                                    mainImage = images.isNotEmpty
                                        ? images.first
                                        : null;
                                  }
                                });
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

  void _deleteService(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف الخدمة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _firestore.collection('services').doc(id).delete();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
