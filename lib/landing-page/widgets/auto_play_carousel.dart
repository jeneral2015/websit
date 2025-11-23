import 'dart:async';
import 'package:flutter/material.dart';
import '../responsive_utils.dart';

class AutoPlayCarousel extends StatefulWidget {
  final List<Widget> items;
  final double height;
  final double viewportFraction;
  final bool enableAutoPlay;
  final Duration autoPlayInterval;
  final bool enableScaleEffect;

  const AutoPlayCarousel({
    super.key,
    required this.items,
    this.height = 250,
    this.viewportFraction = 0.85,
    this.enableAutoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.enableScaleEffect = true,
  });

  @override
  State<AutoPlayCarousel> createState() => _AutoPlayCarouselState();
}

class _AutoPlayCarouselState extends State<AutoPlayCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  double _pageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction);
    _pageController.addListener(() {
      setState(() {
        _pageValue = _pageController.page!;
      });
    });
    if (widget.enableAutoPlay) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (_currentPage < widget.items.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.removeListener(() {});
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: GestureDetector(
        onPanDown: (_) => _stopAutoPlay(),
        onPanCancel: () {
          if (widget.enableAutoPlay) _startAutoPlay();
        },
        onPanEnd: (_) {
          if (widget.enableAutoPlay) _startAutoPlay();
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.items.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;

                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                  value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                }

                if (widget.enableScaleEffect) {
                  return Transform(
                    transform: getCarouselTransform(
                      context,
                      _pageValue,
                      index,
                      _currentPage,
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: value.clamp(0.7, 1.0),
                      child: child,
                    ),
                  );
                } else {
                  return Transform.scale(
                    scale: Curves.easeOut.transform(value),
                    child: child,
                  );
                }
              },
              child: widget.items[index],
            );
          },
        ),
      ),
    );
  }
}
