import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:websit/services/firebase_paths.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedPeriod = 'آخر أسبوع';
  final List<String> _periodOptions = [
    'آخر أسبوع',
    'آخر شهر',
    'آخر 3 أشهر',
    'آخر 6 أشهر',
    'تخصيص',
  ];

  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 1100;
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    final int crossAxisCount = isDesktop
        ? 4
        : isTablet
        ? 3
        : 2;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: CustomScrollView(
            slivers: [
              // الهيدر المتحرك
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildAnimatedHeader(),
                ),
              ),

              // فلتر الفترة
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildTimePeriodCard(context),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 30)),

              // قسم المواعيد
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSectionTitle('إحصائيات المواعيد'),
                ),
              ),

              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('appointments').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredDocs = _filterByPeriod(snapshot.data!.docs);
                    final stats = _calculateStats(filteredDocs);

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // الرسم البياني الدائري
                          SizedBox(height: 220, child: _buildPieChart(stats)),
                          const SizedBox(height: 30),

                          // كروت الإحصائيات
                          GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: isDesktop ? 1.8 : 1.4,
                            children: [
                              _buildModernStatCard(
                                'إجمالي الحجوزات',
                                stats['total']!,
                                Icons.event,
                                Colors.blue,
                              ),
                              _buildModernStatCard(
                                'مقبولة',
                                stats['accepted']!,
                                Icons.check_circle,
                                Colors.green,
                              ),
                              _buildModernStatCard(
                                'مرفوضة',
                                stats['rejected']!,
                                Icons.cancel,
                                Colors.red,
                              ),
                              _buildModernStatCard(
                                'في الانتظار',
                                stats['pending']!,
                                Icons.hourglass_empty,
                                Colors.orange,
                              ),
                              _buildModernStatCard(
                                'قادمة',
                                stats['upcoming']!,
                                Icons.event_available,
                                Colors.purple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),

              // الأقسام الأخرى
              ..._buildOtherSections(crossAxisCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink.shade400, Colors.pink.shade600],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Text(
                    'لوحة إحصائيات متطورة',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimePeriodCard(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الفترة الزمنية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriod,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.pink[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: _periodOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedPeriod = val!;
                  if (val != 'تخصيص') {
                    _startDate = null;
                    _endDate = null;
                  }
                });
                if (val == 'تخصيص') _showCustomDatePickerDialog(context);
              },
            ),
            if (_selectedPeriod == 'تخصيص' &&
                _startDate != null &&
                _endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'من ${_dateFormat.format(_startDate!)} إلى ${_dateFormat.format(_endDate!)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCustomDatePickerDialog(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.pink),
          ),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: child,
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  List<QueryDocumentSnapshot> _filterByPeriod(
    List<QueryDocumentSnapshot> docs,
  ) {
    final now = DateTime.now();
    DateTime cutoff;

    switch (_selectedPeriod) {
      case 'آخر أسبوع':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 'آخر شهر':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case 'آخر 3 أشهر':
        cutoff = now.subtract(const Duration(days: 90));
        break;
      case 'آخر 6 أشهر':
        cutoff = now.subtract(const Duration(days: 180));
        break;
      case 'تخصيص':
        if (_startDate == null || _endDate == null) return [];
        return docs.where((doc) {
          final dateStr =
              (doc.data() as Map<String, dynamic>)['date']?.toString() ?? '';
          try {
            final date = DateTime.parse(dateStr);
            return date.isAfter(
                  _startDate!.subtract(const Duration(days: 1)),
                ) &&
                date.isBefore(_endDate!.add(const Duration(days: 1)));
          } catch (_) {
            return false;
          }
        }).toList();
      default:
        cutoff = now.subtract(const Duration(days: 7));
    }

    if (_selectedPeriod == 'تخصيص') return docs;

    return docs.where((doc) {
      final dateStr =
          (doc.data() as Map<String, dynamic>)['date']?.toString() ?? '';
      try {
        final date = DateTime.parse(dateStr);
        return date.isAfter(cutoff.subtract(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Map<String, int> _calculateStats(List<QueryDocumentSnapshot> docs) {
    int accepted = 0, rejected = 0, pending = 0, upcoming = 0;
    final now = DateTime.now();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? '';

      switch (status) {
        case 'accepted':
          accepted++;
          try {
            final date = DateTime.parse(data['date']?.toString() ?? '');
            if (date.isAfter(now)) upcoming++;
          } catch (_) {}
          break;
        case 'rejected':
          rejected++;
          break;
        default:
          pending++;
      }
    }

    return {
      'total': docs.length,
      'accepted': accepted,
      'rejected': rejected,
      'pending': pending,
      'upcoming': upcoming,
    };
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 4, width: 80, color: Colors.pinkAccent),
      ],
    );
  }

  Widget _buildModernStatCard(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), Colors.white],
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> stats) {
    final total = stats['total']!;
    if (total == 0) return const Center(child: Text('لا توجد بيانات'));

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: stats['accepted']!.toDouble(),
            color: Colors.green,
            title: '${stats['accepted']}',
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            value: stats['rejected']!.toDouble(),
            color: Colors.red,
            title: '${stats['rejected']}',
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          PieChartSectionData(
            value: stats['pending']!.toDouble(),
            color: Colors.orange,
            title: '${stats['pending']}',
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOtherSections(int crossAxisCount) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSectionTitle('إحصائيات أخرى'),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverGrid.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCollectionCard(
              'services',
              'عدد الخدمات',
              Icons.medical_services,
              Colors.teal,
            ),
            _buildCollectionCard(
              FirebasePaths.gallery,
              'عدد الصور',
              Icons.photo_library,
              Colors.indigo,
            ),
            _buildCollectionCard(
              'reviews',
              'عدد الآراء',
              Icons.rate_review,
              Colors.amber,
            ),
          ],
        ),
      ),

      // كونتينر التقييمات المفصل
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildRatingsStatisticsCard(),
        ),
      ),
    ];
  }

  Widget _buildRatingsStatisticsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('ratings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final ratings = snapshot.data!.docs;
        final totalRatings = ratings.length;

        if (totalRatings == 0) {
          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.purple.withValues(alpha: 0.1), Colors.white],
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.star_border, size: 60, color: Colors.amber),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد تقييمات بعد',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // حساب الإحصائيات
        double totalStars = 0;
        Map<int, int> starDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

        for (var doc in ratings) {
          final data = doc.data() as Map<String, dynamic>;
          final stars = (data['stars'] ?? 0) as num;
          final starsValue = stars.toDouble();

          totalStars += starsValue;

          final starLevel = starsValue.round();
          if (starLevel >= 1 && starLevel <= 5) {
            starDistribution[starLevel] =
                (starDistribution[starLevel] ?? 0) + 1;
          }
        }

        final averageRating = totalRatings > 0
            ? totalStars / totalRatings
            : 0.0;

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.purple.withValues(alpha: 0.1), Colors.white],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // العنوان
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'إحصائيات التقييمات',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // متوسط التقييم
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < averageRating.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'متوسط التقييم',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 2,
                        height: 80,
                        color: Colors.purple.withValues(alpha: 0.3),
                      ),
                      Column(
                        children: [
                          Text(
                            '$totalRatings',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'إجمالي التقييمات',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // توزيع النجوم
                const Text(
                  'توزيع التقييمات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                ...List.generate(5, (index) {
                  final stars = 5 - index;
                  final count = starDistribution[stars] ?? 0;
                  final percentage = totalRatings > 0
                      ? (count / totalRatings)
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '$stars',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 12,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.purple.shade400,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollectionCard(
    String collection,
    String title,
    IconData icon,
    Color color,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return _buildModernStatCard(title, count, icon, color);
      },
    );
  }
}
