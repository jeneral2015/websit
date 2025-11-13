// تم التصحيح بواسطة Blackbox AI - مطابق لـ https://dr-sara-clinic.web.app/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingForm extends StatefulWidget {
  const BookingForm({super.key});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  String _name = '', _phone = '', _service = '', _message = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;
  List<Map<String, dynamic>> _availableSlots = [];
  bool _isSlotsLoading = true;

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
      _loadAvailableSlots();
    });
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isSlotsLoading = true);
    try {
      final settingsDoc = await _firestore
          .collection('site_data')
          .doc('settings')
          .get();
      final settings = settingsDoc.data() ?? {};
      final schedule =
          (settings['weeklySchedule'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>()
              .toList() ??
          [];

      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfNextWeek = startOfWeek.add(const Duration(days: 13));

      final slots = <Map<String, dynamic>>[];

      for (int i = 0; i <= 13; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final dayName = DateFormat('EEEE', 'ar').format(date);

        final daySchedule = schedule.firstWhere(
          (d) => d['day'].toString().contains(_normalizeDay(dayName)),
          orElse: () => <String, dynamic>{},
        );

        if (daySchedule.isNotEmpty && daySchedule['enabled'] == true) {
          final start = _parseTime(daySchedule['startTime']);
          final end = _parseTime(daySchedule['endTime']);
          final interval = 30;

          for (int h = start.hour; h < end.hour; h++) {
            for (int m = 0; m < 60; m += interval) {
              if (h == end.hour && m >= end.minute) break;
              final time = TimeOfDay(hour: h, minute: m);
              final dateTime = DateTime(date.year, date.month, date.day, h, m);

              if (dateTime.isAfter(now)) {
                final isBooked = await _isTimeBooked(dateTime);
                if (!isBooked) {
                  slots.add({
                    'date': date,
                    'time': time,
                    'location': daySchedule['location'],
                    'dateTime': dateTime,
                  });
                }
              }
            }
          }
        }
      }

      setState(() {
        _availableSlots = slots;
        _isSlotsLoading = false;
      });
    } catch (e) {
      setState(() => _isSlotsLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل تحميل المواعيد')));
    }
  }

  String _normalizeDay(String day) {
    return day.replaceAll('ال', '').trim();
  }

  Future<bool> _isTimeBooked(DateTime dateTime) async {
    final snapshot = await _firestore
        .collection('appointments')
        .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(dateTime))
        .where(
          'time',
          isEqualTo: TimeOfDay.fromDateTime(dateTime).format(context),
        )
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(' ');
    final time = parts[0].split(':');
    int hour = int.parse(time[0]);
    final minute = int.parse(time[1]);
    if (parts.length > 1 && parts[1] == 'م' && hour != 12) hour += 12;
    if (parts.length > 1 && parts[1] == 'ص' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حجز موعد'),
        backgroundColor: Colors.pink[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTextField('الاسم الكامل', (v) => _name = v),
                _buildTextField(
                  'رقم الهاتف',
                  (v) => _phone = v,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.length != 11 ? '11 رقم' : null,
                ),
                _buildServiceDropdown(),
                _buildDateTimePicker(),
                _buildTextField(
                  'رسالة إضافية (اختياري)',
                  (v) => _message = v,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إرسال الحجز',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        validator: validator ?? (v) => v!.isEmpty ? 'مطلوب' : null,
      ),
    );
  }

  Widget _buildServiceDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('services').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final services = snapshot.data!.docs
            .map((d) => d['title'] as String)
            .toList();
        return DropdownButtonFormField<String>(
          initialValue: _service.isEmpty ? null : _service,
          decoration: InputDecoration(
            labelText: 'الخدمة',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: services
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => setState(() => _service = v!),
          validator: (v) => v == null ? 'اختر الخدمة' : null,
        );
      },
    );
  }

  Widget _buildDateTimePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر موعد متاح',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _isSlotsLoading
                ? const Center(child: CircularProgressIndicator())
                : _availableSlots.isEmpty
                ? const Text('لا توجد مواعيد متاحة حاليًا')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSlots.map((slot) {
                      final isSelected =
                          _selectedDate?.day == slot['date'].day &&
                          _selectedDate?.month == slot['date'].month &&
                          _selectedTime == slot['time'];
                      return ChoiceChip(
                        label: Text(
                          '${DateFormat('d MMM').format(slot['date'])} - ${slot['time'].format(context)}',
                        ),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedDate = slot['date'];
                            _selectedTime = slot['time'];
                          });
                        },
                        selectedColor: Colors.pink[100],
                        backgroundColor: Colors.grey[200],
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول واختيار موعد')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('appointments').add({
        'name': _name,
        'phone': _phone,
        'service': _service,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'time': _selectedTime!.format(context),
        'message': _message,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم الحجز بنجاح!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('فشل الحجز، حاول لاحقًا')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
