import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'glowing_button.dart';

class BookingForm extends StatefulWidget {
  const BookingForm({super.key});

  @override
  State<BookingForm> createState() => _BookingFormState();

  // Static method لعرض الجدول الأسبوعي في الصفحة الرئيسية
  static Widget buildScheduleSection(
    BuildContext context,
    List<Map<String, dynamic>> weeklySchedule,
  ) {
    // فلترة الأيام المفعلة فقط
    final enabledDays = weeklySchedule
        .where((day) => day['enabled'] == true)
        .toList();

    if (enabledDays.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: Colors.transparent,
      child: Column(
        children: [
          // عنوان القسم
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'مواعيد العمل',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // عرض الجدول
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: enabledDays.map((day) {
                final dayName = day['day'] ?? '';
                final startTime = day['startTime'] ?? '';
                final endTime = day['endTime'] ?? '';
                final location = day['location'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.pink.shade50, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pink.shade100, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withValues(alpha: 0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // أيقونة اليوم
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.pink[800],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // معلومات اليوم
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink[900],
                              ),
                            ),
                            if (location.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: Colors.pink[900],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.pink[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$startTime - $endTime',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // زر الحجز
                      const SizedBox(width: 8),
                      GlowingButton(
                        text: 'احجز الآن',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BookingForm(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // زر الحجز الرئيسي (يمكن إزالته إذا كان زائداً، لكن سأبقيه كخيار عام)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingForm()),
              );
            },
            icon: const Icon(Icons.calendar_month),
            label: const Text('احجز موعدك الآن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  String _name = '', _phone = '', _service = '', _message = '';
  String? _selectedLocation;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;
  List<Map<String, dynamic>> _availableSlots = [];
  bool _isSlotsLoading = true;
  List<String> _locations = [];
  List<Map<String, dynamic>> _weeklySchedule = [];
  String? _backgroundUrl;

  // Cache للاستعلامات
  final Map<String, List<Map<String, dynamic>>> _slotsCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _service = args;
      } else if (args is Map<String, dynamic>) {
        _service = args['title'] ?? '';
      }
      _loadSettingsAndSlots();
    });
  }

  Future<void> _loadSettingsAndSlots() async {
    setState(() => _isSlotsLoading = true);
    try {
      final settingsDoc = await _firestore
          .collection('site_data')
          .doc('settings')
          .get();
      final settings = settingsDoc.data() ?? {};

      _backgroundUrl = settings['backgroundUrl'];

      _weeklySchedule =
          (settings['weeklySchedule'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>()
              .toList() ??
          [];

      _locations = _weeklySchedule
          .where(
            (day) =>
                day['enabled'] == true &&
                day['location'] != null &&
                day['location'].toString().isNotEmpty,
          )
          .map((day) => day['location'].toString())
          .toSet()
          .toList();

      setState(() {});

      if (_locations.isNotEmpty) {
        _selectedLocation = _locations.first;
        await _loadAvailableSlots();
      }
    } catch (e) {
      setState(() => _isSlotsLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل تحميل الإعدادات')));
      }
    }
  }

  Future<void> _loadAvailableSlots({bool forceReload = false}) async {
    if (_selectedLocation == null) return;

    final cacheKey =
        '${_selectedLocation!}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    if (!forceReload && _slotsCache.containsKey(cacheKey)) {
      setState(() {
        _availableSlots = _slotsCache[cacheKey]!;
        _isSlotsLoading = false;
      });
      return;
    }

    setState(() => _isSlotsLoading = true);
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfNextWeek = startOfWeek.add(const Duration(days: 13));

      // تحميل الحجوزات للمكان المحدد فقط
      final bookedSlots = await _loadBookedSlotsForLocation(
        _selectedLocation!,
        startOfWeek,
        endOfNextWeek,
      );

      final slots = <Map<String, dynamic>>[];

      for (int i = 0; i <= 13; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dayName = DateFormat('EEEE', 'ar').format(date);
        final normalizedDayName = _normalizeDay(dayName);

        final daySchedule = _weeklySchedule.firstWhere(
          (d) =>
              d['day'].toString() == normalizedDayName &&
              d['location'] == _selectedLocation &&
              d['enabled'] == true,
          orElse: () => <String, dynamic>{},
        );

        if (daySchedule.isNotEmpty) {
          final start = _parseTime(daySchedule['startTime']);
          final end = _parseTime(daySchedule['endTime']);
          final interval = 30;

          for (int h = start.hour; h <= end.hour; h++) {
            for (int m = 0; m < 60; m += interval) {
              if (h == end.hour && m >= end.minute) break;

              final time = TimeOfDay(hour: h, minute: m);
              final dateTime = DateTime(date.year, date.month, date.day, h, m);

              if (dateTime.isAfter(now)) {
                final dateStr = DateFormat('yyyy-MM-dd').format(dateTime);
                final timeStr = _formatTime(time);
                final slotKey = '$dateStr|$timeStr';

                // التحقق من الحجز باستخدام البيانات المحملة
                if (!bookedSlots.contains(slotKey)) {
                  slots.add({
                    'date': date,
                    'time': time,
                    'location': _selectedLocation,
                    'dateTime': dateTime,
                    'dayName': dayName,
                  });
                }
              }
            }
          }

          // إضافة وقت الإغلاق إذا لم يكن مضافاً
          final endTime = _parseTime(daySchedule['endTime']);
          final endDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            endTime.hour,
            endTime.minute,
          );
          if (endDateTime.isAfter(now)) {
            bool alreadyAdded = slots.any(
              (slot) => slot['dateTime'] == endDateTime,
            );
            if (!alreadyAdded) {
              final dateStr = DateFormat('yyyy-MM-dd').format(endDateTime);
              final timeStr = _formatTime(endTime);
              final slotKey = '$dateStr|$timeStr';

              if (!bookedSlots.contains(slotKey)) {
                slots.add({
                  'date': date,
                  'time': endTime,
                  'location': _selectedLocation,
                  'dateTime': endDateTime,
                  'dayName': dayName,
                });
              }
            }
          }
        }
      }

      // حفظ في الـ cache
      _slotsCache[cacheKey] = slots;

      setState(() {
        _availableSlots = slots;
        _isSlotsLoading = false;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل المواعيد: $e');
      setState(() => _isSlotsLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('فشل تحميل المواعيد')));
      }
    }
  }

  // دالة محسنة لتحميل الحجوزات
  Future<Set<String>> _loadBookedSlotsForLocation(
    String location,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('location', isEqualTo: location)
          .where(
            'date',
            isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startDate),
          )
          .where(
            'date',
            isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endDate),
          )
          .get();

      final bookedSlots = <String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = data['date'] as String;
        final time = data['time'] as String;
        final slotKey = '$date|$time';
        bookedSlots.add(slotKey);
      }

      return bookedSlots;
    } catch (e) {
      debugPrint('خطأ في تحميل الحجوزات: $e');
      return {};
    }
  }

  // دالة مساعدة للتحقق من حجز وقت معين
  Future<bool> _isTimeBooked(DateTime dateTime, String location) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(dateTime);
    final timeStr = _formatTime(TimeOfDay.fromDateTime(dateTime));

    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('date', isEqualTo: dateStr)
          .where('time', isEqualTo: timeStr)
          .where('location', isEqualTo: location)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  String _normalizeNumbers(String text) {
    return text
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9');
  }

  String _normalizeDay(String day) {
    String normalizedDay = _normalizeNumbers(day);

    final arabicDays = {
      'اثنين': 'الاثنين',
      'ثلاثاء': 'الثلاثاء',
      'أربعاء': 'الأربعاء',
      'خميس': 'الخميس',
      'جمعة': 'الجمعة',
      'سبت': 'السبت',
      'أحد': 'الأحد',
      'الاثنين': 'الاثنين',
      'الثلاثاء': 'الثلاثاء',
      'الاربعاء': 'الأربعاء',
      'الخميس': 'الخميس',
      'الجمعة': 'الجمعة',
      'السبت': 'السبت',
      'الاحد': 'الأحد',
    };

    return arabicDays[normalizedDay] ?? normalizedDay;
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      String normalizedTime = _normalizeNumbers(timeStr);

      final parts = normalizedTime.split(' ');
      final timePart = parts[0];
      final period = parts.length > 1 ? parts[1] : '';

      final timeComponents = timePart.split(RegExp(r'[:\.]'));
      int hour = int.parse(timeComponents[0]);
      int minute = timeComponents.length > 1 ? int.parse(timeComponents[1]) : 0;

      if (period == 'م' && hour != 12) {
        hour += 12;
      } else if (period == 'ص' && hour == 12) {
        hour = 0;
      }

      hour = hour.clamp(0, 23);
      minute = minute.clamp(0, 59);

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      debugPrint('خطأ في تحويل الوقت: "$timeStr" - $e');
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final hasValidBg =
        _backgroundUrl != null && _backgroundUrl!.startsWith('http');

    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز موعد'),
        backgroundColor: Colors.pink[800],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (hasValidBg)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(_backgroundUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(color: Colors.pink[50]),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeaderCard(),
                    _buildTextField('الاسم الكامل', (v) => _name = v),
                    _buildTextField(
                      'رقم الهاتف',
                      (v) => _phone = v,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v!.length != 11 ? 'يجب أن يكون الرقم 11 رقمًا' : null,
                    ),
                    _buildServiceDropdown(),
                    _buildLocationDropdown(),
                    _buildDateSelector(),
                    _buildTimeSelector(),
                    _buildTextField(
                      'رسالة إضافية (اختياري)',
                      (v) => _message = v,
                      maxLines: 3,
                      validator: (v) => null,
                    ),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.pink[800]),
            const SizedBox(height: 8),
            Text(
              'حجز موعد',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'اختر الموقع والموعد المناسب لك',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    Function(String) onChanged, {
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines ?? 1,
          validator: validator ?? (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
        ),
      ),
    );
  }

  Widget _buildServiceDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final servicesMap = <String, String>{};
        for (var doc in snapshot.data!.docs) {
          final title = doc['title'] as String;
          servicesMap[title] = title;
        }
        final services = servicesMap.keys.toList();

        final selectedValue = _service.isEmpty || !services.contains(_service)
            ? null
            : _service;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: selectedValue,
              decoration: const InputDecoration(
                labelText: 'الخدمة',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: services
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _service = v!),
              validator: (v) => v == null ? 'يرجى اختيار الخدمة' : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationDropdown() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          initialValue: _selectedLocation,
          decoration: const InputDecoration(
            labelText: 'المكان',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          items: _locations
              .map(
                (location) =>
                    DropdownMenuItem(value: location, child: Text(location)),
              )
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedLocation = v;
              _selectedDate = null;
              _selectedTime = null;
            });
            _loadAvailableSlots();
          },
          validator: (v) => v == null ? 'يرجى اختيار المكان' : null,
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    if (_selectedLocation == null) return const SizedBox();

    final availableDates =
        _availableSlots.map((slot) => slot['date'] as DateTime).toSet().toList()
          ..sort((a, b) => a.compareTo(b));

    final hasEnabledDays = _weeklySchedule.any((day) => day['enabled'] == true);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر اليوم',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _isSlotsLoading
                ? const Center(child: CircularProgressIndicator())
                : !hasEnabledDays
                ? const Text(
                    'لا توجد أيام عمل مفعلة في الإعدادات',
                    style: TextStyle(color: Colors.grey),
                  )
                : availableDates.isEmpty
                ? const Text(
                    'لا توجد أيام متاحة حالياً',
                    style: TextStyle(color: Colors.grey),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableDates.map((date) {
                      final dayName = DateFormat('EEEE', 'ar').format(date);
                      final dateStr = DateFormat('d MMM', 'ar').format(date);
                      final isSelected =
                          _selectedDate?.day == date.day &&
                          _selectedDate?.month == date.month;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = date;
                            _selectedTime = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.pink[100]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.pink
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.pink[800]
                                      : Colors.black,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.pink[800]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    if (_selectedDate == null) return const SizedBox();

    final availableTimes =
        _availableSlots
            .where(
              (slot) =>
                  slot['date'].day == _selectedDate!.day &&
                  slot['date'].month == _selectedDate!.month,
            )
            .map((slot) => slot['time'] as TimeOfDay)
            .toList()
          ..sort((a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute));

    final daySchedule = _weeklySchedule.firstWhere(
      (d) =>
          d['day'].toString().contains(
            _normalizeDay(DateFormat('EEEE', 'ar').format(_selectedDate!)),
          ) &&
          d['location'] == _selectedLocation,
      orElse: () => <String, dynamic>{},
    );

    final endTime = daySchedule.isNotEmpty
        ? _parseTime(daySchedule['endTime'])
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'اختر الوقت',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (endTime != null) ...[
                  const Spacer(),
                  Text(
                    'ينتهي الساعة ${_formatTime(endTime)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            availableTimes.isEmpty
                ? const Text(
                    'لا توجد أوقات متاحة لهذا اليوم',
                    style: TextStyle(color: Colors.grey),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTimes.map((time) {
                      final isSelected = _selectedTime == time;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTime = time;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.pink[100]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.pink
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _formatTime(time),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.pink[800]
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _confirmAndSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send),
                SizedBox(width: 8),
                Text('إرسال الحجز', style: TextStyle(fontSize: 16)),
              ],
            ),
    );
  }

  Future<void> _confirmAndSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      final confirmed = await _showNoTimeConfirmation();
      if (!confirmed) return;
    } else {
      final selectedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final isStillAvailable = !(await _isTimeBooked(
        selectedDateTime,
        _selectedLocation!,
      ));
      if (!isStillAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'عذراً، هذا الوقت تم حجزه من قبل شخص آخر. يرجى اختيار وقت آخر.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        await _loadAvailableSlots(forceReload: true);
        return;
      }
    }

    await _showBookingConfirmation();
  }

  Future<bool> _showNoTimeConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحجز'),
            content: const Text(
              'لم تختر وقت محدد. سيتم حجز الموعد في وقت الإغلاق. هل تريد المتابعة؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[800],
                ),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showBookingConfirmation() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد الحجز'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildConfirmationItem('الاسم:', _name),
                  _buildConfirmationItem('الهاتف:', _phone),
                  _buildConfirmationItem('الخدمة:', _service),
                  _buildConfirmationItem('المكان:', _selectedLocation ?? ''),
                  if (_selectedDate != null && _selectedTime != null)
                    _buildConfirmationItem(
                      'الموعد:',
                      '${DateFormat('EEEE d MMM', 'ar').format(_selectedDate!)} - ${_formatTime(_selectedTime!)}',
                    )
                  else
                    _buildConfirmationItem('الموعد:', 'سيتم تحديده لاحقاً'),
                  if (_message.isNotEmpty)
                    _buildConfirmationItem('الرسالة:', _message),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('تعديل'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[800],
                ),
                child: const Text('تأكيد الحجز'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await _submitBooking();
    }
  }

  Widget _buildConfirmationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);
    try {
      DateTime? bookingDateTime;
      String? bookingTime;

      if (_selectedDate != null && _selectedTime != null) {
        bookingDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        bookingTime = _formatTime(_selectedTime!);
      } else if (_selectedDate != null) {
        final daySchedule = _weeklySchedule.firstWhere(
          (d) =>
              d['day'].toString().contains(
                _normalizeDay(DateFormat('EEEE', 'ar').format(_selectedDate!)),
              ) &&
              d['location'] == _selectedLocation,
          orElse: () => <String, dynamic>{},
        );

        if (daySchedule.isNotEmpty) {
          final endTime = _parseTime(daySchedule['endTime']);
          bookingDateTime = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            endTime.hour,
            endTime.minute,
          );
          bookingTime = _formatTime(endTime);
        }
      }

      // 🔒 Use Transaction to ensure atomicity: appointment + notification
      await _firestore.runTransaction((transaction) async {
        // 1. Create appointment
        final appointmentData = {
          'name': _name,
          'phone': _phone,
          'service': _service,
          'location': _selectedLocation,
          'date': bookingDateTime != null
              ? DateFormat('yyyy-MM-dd').format(bookingDateTime)
              : 'سيتم التحديد',
          'time': bookingTime ?? 'سيتم التحديد',
          'message': _message,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        };
        final docRef = _firestore.collection('appointments').doc();
        transaction.set(docRef, appointmentData);

        // 2. Trigger notification creation (via manager)
        // We pass the data + ID for consistency
        appointmentData['id'] = docRef.id;
        await _firestore.collection('notifications').add({
          'appointmentId': docRef.id,
          'message': 'موعد جديد: $_name - $_service',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        return docRef;
      });

      // ✅ Show success
      await _showSuccessDialog();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ خطأ في الحجز: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل الحجز، يرجى المحاولة مرة أخرى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.pink[50]!, Colors.white, Colors.pink[50]!],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade300, width: 3),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'تم الحجز بنجاح!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[800],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'شكراً لك $_name على حجزك',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: Column(
                  children: [
                    _buildSuccessItem('الخدمة:', _service),
                    _buildSuccessItem('المكان:', _selectedLocation ?? ''),
                    if (_selectedDate != null && _selectedTime != null)
                      _buildSuccessItem(
                        'الموعد:',
                        '${DateFormat('EEEE d MMM', 'ar').format(_selectedDate!)} - ${_formatTime(_selectedTime!)}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'سيتم التواصل معك لتأكيد الحجز',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('تم', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.pink[800],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
