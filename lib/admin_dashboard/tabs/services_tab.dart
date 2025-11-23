import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/dropbox_uploader.dart';

class ServicesTab extends StatefulWidget {
  const ServicesTab({super.key});

  @override
  _ServicesTabState createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DropboxUploader _dropboxUploader = DropboxUploader();
  final ImagePicker _imagePicker = ImagePicker();

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
