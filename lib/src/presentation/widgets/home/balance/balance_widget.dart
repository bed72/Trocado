// import 'package:flutter/material.dart';
// import 'package:animated_digit/animated_digit.dart';

// import 'package:trocado/src/domain/models/entry_model.dart';

// import 'package:trocado/src/presentation/extensions/context_extension.dart';

// import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
// import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

// class BalanceWidget extends StatelessWidget {
//   final bool isSelected;
//   final EntryModel? model;
//   final ValueChanged<EntryModel?> onPress;

//   const BalanceWidget({
//     super.key,
//     required this.model,
//     required this.onPress,
//     required this.isSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = switch (model) {
//       .expense => context.colors.error,
//       .income => context.colors.primary,
//       null => context.colors.onSurfaceVariant,
//     };

//     final icon = switch (model) {
//       .income => Icons.trending_up,
//       .expense => Icons.trending_down,
//       null => Icons.info,
//     };

//     return BounceWidget.withOnPress(
//       onPress: isSelected ? null : () => onPress(model),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         decoration: ShapeDecoration(
//           color: isSelected
//               ? color.withValues(alpha: .4)
//               : context.colors.surface,
//           shape: RoundedRectangleBorder(
//             borderRadius: context.radius.cornerRadius300,
//             side: isSelected
//                 ? BorderSide(width: 1.4, color: color.withValues(alpha: .2))
//                 : BorderSide.none,
//           ),
//         ),
//         child: Card(
//           margin: .zero,
//           shape: RoundedRectangleBorder(
//             borderRadius: context.radius.cornerRadius300,
//           ),
//           child: Padding(
//             padding: const .all(16.0),
//             child: Column(
//               spacing: 16.0,
//               mainAxisSize: .min,
//               crossAxisAlignment: model.isTotal ? .center : .start,
//               children: [
//                 Row(
//                   mainAxisAlignment: model.isTotal ? .center : .spaceBetween,
//                   children: [
//                     _buildLabel(context),
//                     if (!model.isTotal) _buildIcon(color: color, icon: icon),
//                   ],
//                 ),

//                 _buildValue(context),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   BackgroundIconWidget _buildIcon({
//     required Color color,
//     required IconData icon,
//   }) => BackgroundIconWidget(
//     icon: icon,
//     color: color,
//     width: 32.0,
//     height: 32.0,
//     iconSize: 16.0,
//     borderRadius: .circular(12.0),
//   );

//   Text _buildLabel(BuildContext context) => Text(
//     model.label.toUpperCase(),
//     style: model.isTotal
//         ? context.typography.titleMedium?.copyWith(
//             fontWeight: .w600,
//             color: context.colors.onSurfaceVariant.withValues(alpha: 0.8),
//           )
//         : context.typography.labelMedium?.copyWith(
//             fontWeight: .w600,
//             color: context.colors.onSurfaceVariant.withValues(alpha: 0.8),
//           ),
//   );

//   AnimatedDigitWidget _buildValue(BuildContext context) => AnimatedDigitWidget(
//     prefix: 'R\$ ',
//     autoSize: true,
//     value: model.amount,
//     fractionDigits: 2,
//     separateSymbol: '.',
//     decimalSeparator: ',',
//     enableSeparator: true,
//     animateAutoSize: true,
//     duration: const Duration(milliseconds: 600),
//     textStyle: model.isTotal
//         ? context.typography.titleLarge?.copyWith(
//             fontWeight: .w600,
//             color: context.colors.onSurfaceVariant,
//             fontFeatures: const [.tabularFigures()],
//           )
//         : context.typography.titleMedium?.copyWith(
//             fontWeight: .bold,
//             color: context.colors.onSurfaceVariant,
//             fontFeatures: const [.tabularFigures()],
//           ),
//   );
// }
