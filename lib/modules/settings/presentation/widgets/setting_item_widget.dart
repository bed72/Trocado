import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/core.dart';

class SettingItemWidget extends StatelessWidget {
  final String title;
  final String? value;
  final bool hasArrow;
  final bool isDanger;
  final IconData icon;
  final bool? switchValue;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onChanged;

  const SettingItemWidget._({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.onChanged,
    this.switchValue,
    this.isDanger = false,
    this.hasArrow = false,
  });

  factory SettingItemWidget.switchTile({
    required bool value,
    required String title,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) => SettingItemWidget._(
    icon: icon,
    title: title,
    switchValue: value,
    onChanged: onChanged,
  );

  factory SettingItemWidget.valueTile({
    required String value,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      SettingItemWidget._(icon: icon, title: title, value: value, onTap: onTap);

  factory SettingItemWidget.arrowTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) => SettingItemWidget._(
    icon: icon,
    title: title,
    hasArrow: true,
    onTap: onTap,
  );

  factory SettingItemWidget.dangerTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) => SettingItemWidget._(
    icon: icon,
    title: title,
    onTap: onTap,
    isDanger: true,
  );

  @override
  Widget build(BuildContext context) {
    return switchValue != null
        ? _buildContent(context)
        : BounceWidget.withTap(
            onTap: onTap ?? () {},
            child: _buildContent(context),
          );
  }

  Container _buildContent(BuildContext context) => Container(
    height: 58.0,
    padding: const .symmetric(horizontal: 16.0, vertical: 12.0),
    decoration: BoxDecoration(
      borderRadius: context.radius.cornerRadius300,
      border: .all(
        color: isDanger
            ? context.colors.error
            : context.colors.onInverseSurface,
      ),
    ),
    child: Row(
      spacing: 16.0,
      children: [
        IconWidget(
          name: icon,
          color: isDanger
              ? context.colors.error
              : context.colors.inversePrimary,
        ),
        Expanded(
          child: Text(
            title,
            style: context.typography.bodyMedium?.copyWith(
              fontWeight: .w500,
              color: isDanger ? context.colors.error : context.colors.onSurface,
            ),
          ),
        ),

        if (switchValue != null)
          SwitchWidget(value: switchValue!, onChanged: onChanged!),

        if (value != null)
          Text(
            value!,
            style: context.typography.bodyMedium?.copyWith(
              fontWeight: .w500,
              color: isDanger
                  ? context.colors.errorContainer.withAlpha(400)
                  : context.colors.onSurface.withAlpha(400),
            ),
          ),

        if (hasArrow) IconWidget(name: LucideIcons.chevronRight),
      ],
    ),
  );
}
