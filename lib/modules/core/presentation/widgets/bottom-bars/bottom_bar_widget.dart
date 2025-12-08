import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:trocado/modules/core/domain/constant/bottom_bar_constant.dart';

import 'package:trocado/modules/core/presentation/widgets/indicator_widget.dart';
import 'package:trocado/modules/core/presentation/extensions/context_extension.dart';
import 'package:trocado/modules/core/presentation/widgets/bottom-bars/bottom_bar_item_widget.dart';

class BottomBarWidget extends StatefulWidget {
  final int index;
  final VoidCallback onExit;
  final void Function({required BuildContext context, required int index})
  onTap;

  const BottomBarWidget({
    super.key,
    required this.index,
    required this.onTap,
    required this.onExit,
  });

  @override
  State<BottomBarWidget> createState() => _BottomBarWidgetState();
}

class _BottomBarWidgetState extends State<BottomBarWidget>
    with TickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TabController(vsync: this, length: 5);
    _controller.index = widget.index;
  }

  @override
  void didUpdateWidget(covariant BottomBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.index != _controller.index) {
      _controller.index = widget.index;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) => widget.onExit(),
      child: TabBar(
        dividerHeight: 0.0,
        enableFeedback: false,
        controller: _controller,
        tabs: _buildTabs(context),
        indicator: IndicatorWidget(),
        dividerColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        padding: .only(bottom: context.bottom),
        overlayColor: .all(Colors.transparent),
        onTap: (index) {
          if (index == BottomBarConstant.transaction.position) {
            _controller.index = widget.index;

            return widget.onTap(context: context, index: index);
          }

          widget.onTap(context: context, index: index);
        },
      ),
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
    final selectedIndex = _controller.index;

    final items = [
      ('Ínicio', LucideIcons.layoutPanelLeft, LucideIcons.layoutPanelTop),
      ('Todas as Transações', LucideIcons.scrollText, LucideIcons.scroll),
      ('Novas Transações', LucideIcons.badgePlus, LucideIcons.badgePlus),
      (
        'Relatórios',
        LucideIcons.chartColumn,
        LucideIcons.chartColumnIncreasing,
      ),
      ('Configurações', LucideIcons.bolt, LucideIcons.hexagon),
    ];

    return List.generate(items.length, (index) {
      final isSelected = selectedIndex == index;
      final (label, unselectedIcon, selectedIcon) = items[index];

      return BottomBarItemWidget(
        semanticLabel: label,
        name: isSelected ? selectedIcon : unselectedIcon,
        color: isSelected ? context.colors.outline : context.colors.outline,
      );
    });
  }
}
