import 'package:flutter/material.dart';
import '../models/ad_model.dart';
import 'countdown_timer.dart';

class AdPopup extends StatefulWidget {
  final AdModel ad;
  final VoidCallback onClose;
  final VoidCallback onBookNow;
  final Function(String)? onAdClick;

  const AdPopup({
    super.key,
    required this.ad,
    required this.onClose,
    required this.onBookNow,
    this.onAdClick,
  });

  @override
  State<AdPopup> createState() => _AdPopupState();
}

class _AdPopupState extends State<AdPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // من أسفل
      end: Offset.zero, // إلى مكانه الطبيعي
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // بدء الرسوم المتحركة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closePopup() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  void _handleBookNow() {
    // زيادة عداد النقرات
    widget.onAdClick?.call(widget.ad.id);

    // إغلاق البوب أب
    _closePopup();

    // استدعاء دالة الحجز
    widget.onBookNow();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.ad.imageUrl != null && widget.ad.imageUrl!.isNotEmpty;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.pink.shade50, Colors.white],
            ),
            border: Border.all(color: Colors.pink.shade200, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with close button and countdown timer
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Countdown timer on the left
                    CountdownTimer(
                      endTime: widget.ad.endDate,
                      backgroundColor: Colors.transparent,
                      textColor: Colors.pink[800],
                    ),

                    // Close button on the right
                    IconButton(
                      onPressed: _closePopup,
                      icon: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content area - different layouts based on image presence
              if (hasImage)
                // Layout with image
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image section - takes half the container
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                          ),
                          child: Image.network(
                            widget.ad.imageUrl!,
                            fit: BoxFit.fill,
                            width: double.infinity,
                            height: 200,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 60,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Text content - takes other half
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  // Centered title
                                  Text(
                                    widget.ad.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.pink,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 8),

                                  // Description
                                  Text(
                                    widget.ad.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),

                              // Booking button - smaller and on left
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton.icon(
                                  onPressed: _handleBookNow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'احجز الآن',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Layout without image - full width content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Centered title
                      Text(
                        widget.ad.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Description
                      Text(
                        widget.ad.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 20),

                      // Booking button - smaller and on left
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: _handleBookNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text(
                            'احجز الآن',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
}
