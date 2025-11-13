// initial_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';

void addInitialServices() async {
  final services = [
    {
      'title': 'إزالة الشعر بالليزر',
      'description': 'أحدث تقنيات الليزر لإزالة الشعر بشكل دائم وآمن',
      'icon': 'content_cut',
    },
    {
      'title': 'إزالة الجروح والندبات وآثار حب الشباب بالليزر',
      'description': 'تقشير وإزالة آثار حب الشباب بالليزر والتقنيات الحديثة',
      'icon': 'healing',
    },
    {
      'title': 'تقشير البشرة (بلازما - ميزو - ليزر)',
      'description': 'جلسات نضارة البشرة بأنواعها المختلفة',
      'icon': 'spa',
    },
    {
      'title': 'إزالة الزوائد الجلدية والحسنات بالليزر',
      'description': 'إزالة الزوائد الجلدية والحسنات بأمان تام',
      'icon': 'remove_circle',
    },
    {
      'title': 'علاج البهاق والصدفية والإكزيما',
      'description': 'علاج الحالات الجلدية المزمنة باستخدام الإكزيمر ليزر',
      'icon': 'local_hospital',
    },
    {
      'title': 'جلسات البوتكس للتجاعيد',
      'description': 'علاج فرط التعرق والابتسامة اللثوية والتجاعيد',
      'icon': 'face',
    },
    {
      'title': 'الميزو بوتكس لنضارة البشرة',
      'description': 'جلسات لنضارة وتجديد البشرة',
      'icon': 'brightness_high',
    },
    {
      'title': 'جلسات التقشير الكيميائي البارد',
      'description': 'تقشير البشرة بطرق آمنة وفعالة',
      'icon': 'cleaning_services',
    },
    {
      'title': 'ديرمابين مع الميزوثيرابي والبلازما',
      'description': 'تفتيح ونضارة البشرة',
      'icon': 'lightbulb',
    },
    {
      'title': 'حقن البلازما والسكين بوستر',
      'description': 'نضارة وشد الوجه',
      'icon': 'vaccines',
    },
    {
      'title': 'علاج تساقط الشعر بالميزوثيرابي والبلازما',
      'description': 'علاج وتقوية الشعر',
      'icon': 'grass',
    },
    {
      'title': 'حقن الفيلر للخدود والشفاه',
      'description': 'تجميل الوجه والشفاه',
      'icon': 'favorite',
    },
    {
      'title': 'علاج جميع الأمراض الجلدية',
      'description': 'تشخيص وعلاج جميع الأمراض الجلدية والتناسلية',
      'icon': 'medical_services',
    },
    {
      'title': 'الإجراءات التجميلية غير الجراحية',
      'description': 'إجراءات تجميلية آمنة وفعالة',
      'icon': 'brush',
    },
  ];

  for (var service in services) {
    await FirebaseFirestore.instance.collection('services').add(service);
  }
}
