import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/toast_widget.dart';
import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';
import 'package:trocado/src/presentation/widgets/dialog/confirm_dialog_widget.dart';

import 'package:trocado/src/presentation/ui/notifications/notifiers/notifications_state.dart';
import 'package:trocado/src/presentation/ui/notifications/notifiers/notifications_notifier.dart';

import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_list_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_empty_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_failure_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_loading_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_delete_all_button_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  VoidCallback _onLoadMore = () {};

  static const int _deleteAllThreshold = 10;

  final double _loadMoreThreshold = 200.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _onLoadMore();
    }
  }

  Future<void> _onDeleteAllPressed(NotificationsNotifier notifier) async {
    final confirmed = await showConfirmDialog(
      context: context,
      confirmLabel: 'Excluir',
      title: 'Excluir notificações',
      description:
          'Esta ação vai excluir todas as notificações e não pode ser desfeita .',
    );
    if (!confirmed) return;

    await notifier.deleteAll();
  }

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      ref.listen(notificationsProvider, (previous, next) {
        final nextDeleteAllFailure = next.value?.deleteAllFailure;
        final previousDeleteAllFailure = previous?.value?.deleteAllFailure;

        if (nextDeleteAllFailure != null &&
            nextDeleteAllFailure != previousDeleteAllFailure) {
          showToastWidget(
            context: context,
            title: 'Opps',
            type: .failure,
            description: nextDeleteAllFailure.message,
          );
        }

        final nextDeleteFailure = next.value?.deleteFailure;
        final previousDeleteFailure = previous?.value?.deleteFailure;

        if (nextDeleteFailure != null &&
            nextDeleteFailure != previousDeleteFailure) {
          showToastWidget(
            context: context,
            title: 'Opps',
            type: .failure,
            description: nextDeleteFailure.message,
          );
        }
      });

      final state = ref.watch(notificationsProvider);
      final notifier = ref.read(notificationsProvider.notifier);
      _onLoadMore = notifier.loadMore;

      final itemsCount = state.value?.items.length ?? 0;
      final showDeleteAll = itemsCount > _deleteAllThreshold;

      return ScaffoldWidget(
        appBar: AppBarWidget(
          leading: const GoBackWidget(),
          actions: showDeleteAll
              ? [
                  Padding(
                    padding: const .only(right: 16.0),
                    child: NotificationsDeleteAllButtonWidget(
                      onPress: () => _onDeleteAllPressed(notifier),
                    ),
                  ),
                ]
              : null,
        ),
        child: RefreshIndicator(
          onRefresh: notifier.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: .symmetric(horizontal: 16.0, vertical: 24.0),
                  child: ScreenHeaderWidget(
                    title: 'Notificações',
                    description: 'Acompanhe os alertas e avisos da sua conta.',
                  ),
                ),
              ),
              ..._contentSlivers(notifier, state),
            ],
          ),
        ),
      );
    },
  );

  List<Widget> _contentSlivers(
    NotificationsNotifier notifier,
    AsyncValue<NotificationsState> state,
  ) => switch (state) {
    AsyncLoading() => const [
      SliverToBoxAdapter(child: NotificationsLoadingWidget()),
    ],
    AsyncError() => [
      SliverFillRemaining(
        hasScrollBody: false,
        child: NotificationsFailureWidget(onRetry: notifier.refresh),
      ),
    ],
    AsyncData(:final NotificationsState value) when value.items.isEmpty =>
      const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: NotificationsEmptyWidget(),
        ),
      ],
    AsyncData(:final NotificationsState value) => [
      NotificationsListWidget(
        state: value,
        groups: value.groups,
        onLoadMore: _onLoadMore,
        onDelete: notifier.deleteById,
      ),
    ],
  };
}
