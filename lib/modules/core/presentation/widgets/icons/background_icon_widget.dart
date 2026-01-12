import 'package:flutter/widgets.dart';
import 'package:trocado/modules/core/core.dart';

import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';

class BackgroundIconWidget extends StatelessWidget {
  final Color color;
  final IconData name;

  const BackgroundIconWidget({
    super.key,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 48.0,
      alignment: .center,
      decoration: BoxDecoration(
        borderRadius: context.radius.cornerRadius100,
        color: color.withValues(alpha: 0.2),
      ),
      child: IconWidget(name: name, color: color),
    );
  }
}
