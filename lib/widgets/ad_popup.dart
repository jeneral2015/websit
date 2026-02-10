import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../models/ad_model.dart';
import 'countdown_timer.dart';

/// A responsive ad popup widget that displays an advertisement with animations,
/// confetti effects, and responsive design for various screen sizes.
/// The confetti is golden and shiny, covering the full screen area for a celebratory feel.
/// The popup is positioned at the bottom of the screen.
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
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller for slide and fade effects
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Slide animation from bottom to position
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Opacity animation for smooth appearance
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize confetti controller with longer duration for better visibility
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    // Start animations and confetti after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  /// Handles closing the popup with reverse animation
  void _closePopup() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  /// Handles the 'Book Now' action: increments click count, closes popup, and calls onBookNow
  void _handleBookNow() {
    widget.onAdClick?.call(widget.ad.id);
    _closePopup();
    widget.onBookNow();
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen size for responsiveness
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    final isTabletOrLaptop = screenSize.width > 600;

    // Responsive maxWidth: Full width for laptops/desktops, constrained for mobile
    final double maxWidth = isTabletOrLaptop
        ? double.infinity
        : screenSize.width * 0.95;

    // Reduced height for laptops to stay slim
    final double imageHeight = isTabletOrLaptop
        ? (screenSize.height * 0.35).clamp(150.0, 280.0)
        : (isLandscape ? (screenSize.height * 0.5).clamp(200.0, 400.0) : 220.0);

    final hasImage =
        widget.ad.imageUrl != null && widget.ad.imageUrl!.isNotEmpty;

    // Full-screen stack to allow confetti to cover the entire screen
    return Stack(
      children: [
        // Background overlay for dimming the screen behind the popup
        GestureDetector(onTap: _closePopup, child: Container()),
        // Popup content positioned at the bottom with animations
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  margin: isTabletOrLaptop
                      ? const EdgeInsets.only(bottom: 24.0)
                      : const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: isTabletOrLaptop
                        ? const BorderRadius.vertical(
                            top: Radius.circular(30.0),
                          )
                        : BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15.0,
                        spreadRadius: 5.0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.pink.shade50, Colors.white],
                    ),
                    border: Border.all(color: Colors.pink.shade200, width: 2.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with countdown and close button
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CountdownTimer(
                              endTime: widget.ad.endDate,
                              backgroundColor: Colors.transparent,
                              textColor: Colors.pink[800],
                            ),
                            IconButton(
                              onPressed: _closePopup,
                              icon: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade200,
                                ),
                                padding: const EdgeInsets.all(6.0),
                                child: const Icon(
                                  Icons.close,
                                  size: 20.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Content based on image presence
                      if (hasImage)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Image section (responsive width)
                              Expanded(
                                flex: isLandscape ? 2 : 1,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(20.0),
                                  ),
                                  child: Image.network(
                                    widget.ad.imageUrl!,
                                    fit: BoxFit
                                        .fill, // Changed to fill as requested
                                    height: imageHeight,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: imageHeight,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                          size: 80.0,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Text content section
                              Expanded(
                                flex: isLandscape ? 3 : 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            widget.ad.title,
                                            style: TextStyle(
                                              fontSize: isTabletOrLaptop
                                                  ? 22.0
                                                  : 18.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.pink,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                            height: isTabletOrLaptop
                                                ? 12.0
                                                : 8.0,
                                          ),
                                          Text(
                                            widget.ad.description,
                                            style: TextStyle(
                                              fontSize: isTabletOrLaptop
                                                  ? 16.0
                                                  : 14.0,
                                              color: Colors.grey[700],
                                              height: 1.4,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16.0),
                                      Align(
                                        alignment: Alignment.center,
                                        child: ElevatedButton.icon(
                                          onPressed: _handleBookNow,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pink,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isTabletOrLaptop
                                                  ? 24.0
                                                  : 16.0,
                                              vertical: isTabletOrLaptop
                                                  ? 12.0
                                                  : 8.0,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                            elevation: 5.0,
                                          ),
                                          icon: const Icon(
                                            Icons.calendar_today,
                                            size: 18.0,
                                          ),
                                          label: Text(
                                            'احجز الآن',
                                            style: TextStyle(
                                              fontSize: isTabletOrLaptop
                                                  ? 16.0
                                                  : 14.0,
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            0,
                            16.0,
                            24.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.ad.title,
                                style: TextStyle(
                                  fontSize: isTabletOrLaptop ? 24.0 : 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isTabletOrLaptop ? 16.0 : 12.0),
                              Text(
                                widget.ad.description,
                                style: TextStyle(
                                  fontSize: isTabletOrLaptop ? 17.0 : 15.0,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isTabletOrLaptop ? 24.0 : 20.0),
                              Align(
                                alignment: Alignment.center,
                                child: ElevatedButton.icon(
                                  onPressed: _handleBookNow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTabletOrLaptop
                                          ? 24.0
                                          : 16.0,
                                      vertical: isTabletOrLaptop ? 12.0 : 8.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    elevation: 5.0,
                                  ),
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    size: 18.0,
                                  ),
                                  label: Text(
                                    'احجز الآن',
                                    style: TextStyle(
                                      fontSize: isTabletOrLaptop ? 16.0 : 14.0,
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
            ),
          ),
        ),
        // Confetti widget positioned to cover the full screen for immersive effect
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.yellow,
              Colors.amber,
              Colors.orangeAccent,
              Colors.yellowAccent,
              Colors.amberAccent,
            ], // Golden shiny colors
            createParticlePath: drawStar,
            numberOfParticles:
                140, // Significantly increased for a richer effect
            emissionFrequency: 0.06, // More continuous flow of stars
            minBlastForce: 10.0, // Wider range of force
            maxBlastForce: 60.0, // Stronger burst
            gravity: 0.1,
            particleDrag: 0.06, // Slightly higher gravity for "falling"
            canvas: MediaQuery.of(context).size * 2,
          ),
        ),
      ],
    );
  }

  /// Custom path for star-shaped particles
  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (math.pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * math.cos(step),
        halfWidth + externalRadius * math.sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * math.cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * math.sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }
}
