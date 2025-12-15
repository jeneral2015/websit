import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/dropbox_uploader.dart';
import '../../services/ad_service.dart';
import '../../models/ad_model.dart';

class AdsTab extends StatefulWidget {
  const AdsTab({super.key});

  @override
  State<AdsTab> createState() => _AdsTabState();
}

class _AdsTabState extends State<AdsTab> {
  final AdService _adService = AdService();
  final DropboxUploader _dropboxUploader = DropboxUploader();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        children: [
          // Header مع زر الإضافة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'الإعلانات النشطة',
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[800],
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 16),
              ElevatedButton.icon(
                onPressed: _addNewAd,
                icon: const Icon(Icons.add),
                label: isMobile ? const SizedBox() : const Text('إعلان جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  minimumSize: Size(isMobile ? 50 : 120, isMobile ? 45 : 48),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // قائمة الإعلانات
          Expanded(
            child: StreamBuilder<List<AdModel>>(
              stream: _adService.getAllAdsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ads = snapshot.data!;

                if (ads.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign,
                            size: isMobile ? 50 : 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد إعلانات حالياً',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isMobile)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _addNewAd,
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة أول إعلان'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: ads.length,
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    return _buildAdCard(ad, isMobile: isMobile);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(AdModel ad, {required bool isMobile}) {
    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
      child: InkWell(
        onTap: () => _showAdDetails(ad),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            children: [
              // الصف العلوي: الصورة والمعلومات الأساسية
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة الإعلان
                  Container(
                    width: isMobile ? 50 : 60,
                    height: isMobile ? 50 : 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: ad.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: ad.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Icon(
                                  Icons.image,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.text_fields,
                              size: 24,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // العنوان ومؤشر الأولوية
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ad.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 16 : 18,
                                  color: ad.isActiveNow
                                      ? Colors.pink[800]
                                      : Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isMobile)
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < ad.priority
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: i < ad.priority
                                        ? Colors.amber
                                        : Colors.grey,
                                  );
                                }),
                              ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 4 : 6),
                        // التواريخ
                        Text(
                          '${DateFormat('yyyy-MM-dd').format(ad.startDate)} إلى ${DateFormat('yyyy-MM-dd').format(ad.endDate)}',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMobile)
                    Column(
                      children: [
                        Switch(
                          value: ad.isActive,
                          onChanged: (value) => _toggleAdStatus(ad.id, value),
                          activeThumbColor: Colors.pink,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < ad.priority ? Icons.star : Icons.star_border,
                              size: 12,
                              color: i < ad.priority
                                  ? Colors.amber
                                  : Colors.grey,
                            );
                          }),
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: isMobile ? 8 : 12),
              // الصف السفلي: الحالة والإحصائيات والأزرار
              Row(
                children: [
                  // حالة النشاط
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 6 : 8,
                      vertical: isMobile ? 2 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: ad.isActiveNow
                          ? Colors.green[50]
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ad.isActiveNow ? Colors.green : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      ad.isActiveNow ? 'نشط' : 'غير نشط',
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: ad.isActiveNow
                            ? Colors.green[800]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  // الإحصائيات
                  Expanded(
                    child: Wrap(
                      spacing: isMobile ? 4 : 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '👁️ ${ad.views}',
                          style: TextStyle(fontSize: isMobile ? 10 : 12),
                        ),
                        Text(
                          '👆 ${ad.clicks}',
                          style: TextStyle(fontSize: isMobile ? 10 : 12),
                        ),
                        if (ad.conversionRate > 0)
                          Text(
                            '${ad.conversionRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 12,
                              color: ad.conversionRate > 5
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Toggle التشغيل/الإيقاف
                        Switch(
                          value: ad.isActive,
                          onChanged: (value) => _toggleAdStatus(ad.id, value),
                          activeThumbColor: Colors.pink,
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editAd(ad),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                        ),
                        SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteAd(ad),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                        ),
                      ],
                    ),
                ],
              ),
              if (isMobile)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editAd(ad),
                        iconSize: 20,
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAd(ad),
                        iconSize: 20,
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

  void _showAdDetails(AdModel ad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bool isMobile = MediaQuery.of(context).size.width < 768;

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ad.title,
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < ad.priority ? Icons.star : Icons.star_border,
                        size: 16,
                        color: i < ad.priority ? Colors.amber : Colors.grey,
                      );
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (ad.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: ad.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              if (ad.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    ad.description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),

              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تاريخ البداية:'),
                  Text(DateFormat('yyyy-MM-dd').format(ad.startDate)),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تاريخ النهاية:'),
                  Text(DateFormat('yyyy-MM-dd').format(ad.endDate)),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [const Text('المشاهدات:'), Text('${ad.views}')],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [const Text('النقرات:'), Text('${ad.clicks}')],
              ),

              if (ad.conversionRate > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('نسبة التحويل:'),
                    Text('${ad.conversionRate.toStringAsFixed(1)}%'),
                  ],
                ),
              ],

              if (ad.targetUrl != null && ad.targetUrl!.isNotEmpty) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('رابط الحجز:'),
                    IconButton(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      onPressed: () async {
                        final Uri url = Uri.parse(ad.targetUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('لا يمكن فتح الرابط'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _editAd(ad);
                      },
                      child: const Text('تعديل'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNewAd() {
    _showAdDialog();
  }

  void _editAd(AdModel ad) {
    _showAdDialog(ad: ad);
  }

  void _toggleAdStatus(String adId, bool newStatus) async {
    try {
      await _adService.updateAd(adId, {'isActive': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'تم تفعيل الإعلان' : 'تم إيقاف الإعلان'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ في تحديث حالة الإعلان'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteAd(AdModel ad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // حذف الصورة من Dropbox إذا كانت موجودة
        if (ad.imageUrl != null) {
          await _dropboxUploader.deleteFile(ad.imageUrl!);
        }

        // حذف الإعلان من Firestore
        await _adService.deleteAd(ad.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الإعلان بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل حذف الإعلان: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAdDialog({AdModel? ad}) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final bool isEditing = ad != null;

    final titleCtrl = TextEditingController(text: ad?.title ?? '');
    final descCtrl = TextEditingController(text: ad?.description ?? '');
    final targetUrlCtrl = TextEditingController(text: ad?.targetUrl ?? '');

    DateTime? startDate = ad?.startDate;
    DateTime? endDate = ad?.endDate;
    String? imageUrl = ad?.imageUrl;
    int priority = ad?.priority ?? 3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: isMobile
                ? const EdgeInsets.all(16)
                : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              width: isMobile ? double.infinity : 600,
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'تعديل إعلان' : 'إعلان جديد',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // صورة الإعلان
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl != null)
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 150,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await FilePicker.platform
                                      .pickFiles(type: FileType.image);

                                  if (result != null &&
                                      result.files.isNotEmpty) {
                                    final file = result.files.first;
                                    if (file.bytes != null) {
                                      // Delete old image from Dropbox if exists
                                      if (imageUrl != null) {
                                        await _dropboxUploader.deleteFile(
                                          imageUrl!,
                                        );
                                      }

                                      final url = await _dropboxUploader
                                          .uploadFile(
                                            file.bytes!,
                                            file.name,
                                            docId: 'ads',
                                            useUniqueName: true,
                                          );

                                      if (url != null) {
                                        setStateDialog(() => imageUrl = url);
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(Icons.image),
                                label: const Text('رفع صورة'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(45),
                                ),
                              ),
                            ),
                            if (imageUrl != null) ...[
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: () async {
                                  // Delete image from Dropbox
                                  if (imageUrl != null) {
                                    await _dropboxUploader.deleteFile(
                                      imageUrl!,
                                    );
                                  }
                                  setStateDialog(() => imageUrl = null);
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(45, 45),
                                  backgroundColor: Colors.red[50],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // العنوان
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'عنوان الإعلان',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 16),

                    // الوصف
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'وصف الإعلان',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),

                    const SizedBox(height: 16),

                    // تاريخ البداية والنهاية
                    if (isMobile)
                      Column(
                        children: [
                          _buildDatePicker(
                            label: 'تاريخ البداية',
                            date: startDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setStateDialog(() => startDate = picked);
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildDatePicker(
                            label: 'تاريخ النهاية',
                            date: endDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    endDate ??
                                    DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setStateDialog(() => endDate = picked);
                              }
                            },
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePicker(
                              label: 'تاريخ البداية',
                              date: startDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setStateDialog(() => startDate = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDatePicker(
                              label: 'تاريخ النهاية',
                              date: endDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      endDate ??
                                      DateTime.now().add(
                                        const Duration(days: 7),
                                      ),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (picked != null) {
                                  setStateDialog(() => endDate = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // الأولوية
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الأولوية (1 = منخفضة, 5 = عالية)'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            return IconButton(
                              onPressed: () {
                                setStateDialog(() => priority = starIndex);
                              },
                              icon: Icon(
                                starIndex <= priority
                                    ? Icons.star
                                    : Icons.star_border,
                                size: isMobile ? 28 : 32,
                                color: starIndex <= priority
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                            );
                          }),
                        ),
                        Center(
                          child: Text(
                            '$priority / 5',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // الرابط المستهدف
                    TextField(
                      controller: targetUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: 'رابط الحجز (اختياري)',
                        border: OutlineInputBorder(),
                        hintText: 'سيتم استخدام صفحة الحجز الافتراضية',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // أزرار الحفظ/الإلغاء
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (titleCtrl.text.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('يرجى إدخال عنوان الإعلان'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }

                            if (startDate == null || endDate == null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'يرجى تحديد تواريخ البداية والنهاية',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }

                            final startDateNonNull = startDate!;
                            final endDateNonNull = endDate!;

                            if (endDateNonNull.isBefore(startDateNonNull)) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'تاريخ النهاية يجب أن يكون بعد تاريخ البداية',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }

                            final adData = AdModel(
                              id: ad?.id ?? '',
                              title: titleCtrl.text,
                              description: descCtrl.text,
                              imageUrl: imageUrl,
                              startDate: startDateNonNull,
                              endDate: endDateNonNull,
                              priority: priority,
                              isActive: ad?.isActive ?? true,
                              targetUrl: targetUrlCtrl.text.isNotEmpty
                                  ? targetUrlCtrl.text
                                  : null,
                              views: ad?.views ?? 0,
                              clicks: ad?.clicks ?? 0,
                              createdAt: ad?.createdAt ?? Timestamp.now(),
                            );

                            try {
                              if (isEditing) {
                                await _adService.updateAd(
                                  ad.id,
                                  adData.toMap(),
                                );
                              } else {
                                await _adService.addAd(adData);
                              }

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEditing
                                          ? 'تم تحديث الإعلان بنجاح'
                                          : 'تم إضافة الإعلان بنجاح',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('حدث خطأ: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            minimumSize: Size(
                              isMobile ? 120 : 140,
                              isMobile ? 45 : 48,
                            ),
                          ),
                          child: Text(isEditing ? 'حفظ' : 'إضافة'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('yyyy-MM-dd').format(date)
                      : 'اختر التاريخ',
                  style: TextStyle(
                    color: date != null ? Colors.black : Colors.grey,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
