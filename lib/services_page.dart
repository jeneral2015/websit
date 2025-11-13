import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'glowing_button.dart'; // Import for GlowingButton

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خدماتنا'),
        backgroundColor: Colors.pink,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('services').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final crossCount = isMobile ? 1 : 2;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: crossCount == 1 ? 1.4 : 1,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service =
                        services[index].data() as Map<String, dynamic>;
                    final imageUrl = service['imageUrl'] ?? '';
                    final title = service['title'] ?? 'خدمة';

                    return GestureDetector(
                      onTap: () => _showServiceDialog(context, service),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.fill,
                                        placeholder: (_, __) => const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.pink,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.medical_services,
                                        size: 60,
                                        color: Colors.pink,
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            GlowingButton(argument: title, text: 'احجز الخدمة'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showServiceDialog(BuildContext context, Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: service['imageUrl'] ?? '',
              fit: BoxFit.fill,
              width: double.infinity,
              height: double.infinity,
              errorWidget: (_, __, ___) => const Icon(
                Icons.medical_services,
                size: 100,
                color: Colors.pink,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    service['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    service['description'] ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  GlowingButton(
                    argument: service['title'],
                    text: 'احجز هذه الخدمة',
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
