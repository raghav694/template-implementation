import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:app_template/core/theme/app_colors.dart';

/// A shimmering placeholder box, used anywhere an image is still loading so
/// the app never flashes a flat/blank rectangle.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({this.borderRadius, super.key});

  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceElevated,
      // Bounded loop count: an unbounded shimmer never stops animating for
      // images that fail to load (e.g. offline, dead CDN link), which would
      // otherwise keep scheduling frames forever.
      loop: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
