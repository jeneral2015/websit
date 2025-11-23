import 'package:flutter/material.dart';

double getResponsiveSize(
  BuildContext context,
  double small,
  double medium,
  double large,
) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth < 600) return small;
  if (screenWidth < 1200) return medium;
  return large;
}

double getCarouselScaleValue(
  BuildContext context,
  double pageValue,
  int index,
  int currentPage,
) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 800;

  if (isMobile) {
    // تأثير التكبير للشاشات الصغيرة
    double value = (pageValue - index).abs();
    value = (1 - (value * 0.4)).clamp(0.7, 1.0);
    return value;
  } else {
    // تأثير التكبير للشاشات الكبيرة مع التركيز على العنصر المركزي
    double value = (pageValue - index).abs();
    value = (1 - (value * 0.3)).clamp(0.8, 1.0);
    return value;
  }
}

Matrix4 getCarouselTransform(
  BuildContext context,
  double pageValue,
  int index,
  int currentPage,
) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 800;

  double scale = getCarouselScaleValue(context, pageValue, index, currentPage);

  if (isMobile) {
    // تأثير أكثر دراماتيكية للشاشات الصغيرة
    return Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setTranslationRaw(0.0, ((1 - scale) * 50) * scale, 0.0);
  } else {
    // تأثير أكثر أناقة للشاشات الكبيرة
    return Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setTranslationRaw(((index - pageValue) * 50) * scale, 0.0, 0.0);
  }
}
