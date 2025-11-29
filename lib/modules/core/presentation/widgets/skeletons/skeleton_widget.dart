import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SkeletonWidget extends StatelessWidget {
  final Widget child;
  final bool? enabled;

  const SkeletonWidget({super.key, required this.child, this.enabled});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(enabled: enabled ?? true, child: child);
  }
}
