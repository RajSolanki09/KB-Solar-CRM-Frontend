import 'package:flutter/material.dart';
import 'package:solar_project/Helper/app_colors.dart';

enum LogoSize { small, medium, large, custom }

class AppLogo extends StatelessWidget {
  final LogoSize size;
  final double? customWidth;
  final double? customHeight;
  final double borderRadius;
  final bool withShadow;
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.size = LogoSize.medium,
    this.customWidth,
    this.customHeight,
    this.borderRadius = 12.0,
    this.withShadow = false,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    double width;
    double height;

    final screenWidth = MediaQuery.sizeOf(context).width;
    
    // Scale factor based on screen width
    double scaleFactor = 1.0;
    if (screenWidth >= 1024) {
      scaleFactor = 1.5; // Desktop/Web
    } else if (screenWidth >= 600) {
      scaleFactor = 1.25; // Tablet
    }

    switch (size) {
      case LogoSize.small:
        width = 40 * scaleFactor;
        height = 40 * scaleFactor;
        break;
      case LogoSize.medium:
        width = 80 * scaleFactor;
        height = 80 * scaleFactor;
        break;
      case LogoSize.large:
        width = 150 * scaleFactor;
        height = 150 * scaleFactor;
        break;
      case LogoSize.custom:
        width = customWidth ?? (80 * scaleFactor);
        height = customHeight ?? (80 * scaleFactor);
        break;
    }

    Widget image = Image.asset(
      'assets/images/logo.jpeg',
      width: width,
      height: height,
      fit: fit,
    );

    if (borderRadius > 0) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: image,
      );
    }

    if (withShadow) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: image,
      );
    }

    return image;
  }
}




