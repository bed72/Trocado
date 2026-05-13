import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/screen_header_widget.dart';

import 'package:trocado/src/presentation/ui/notifications/notifiers/notifications_state.dart';
import 'package:trocado/src/presentation/ui/notifications/notifiers/notifications_notifier.dart';

import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_list_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_empty_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_failure_widget.dart';
import 'package:trocado/src/presentation/ui/notifications/widgets/notifications_loading_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  VoidCallback _onLoadMore = () {};

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

  @override
  Widget build(BuildContext context) => Consumer(
    builder: (_, ref, _) {
      final state = ref.watch(notificationsProvider);
      final notifier = ref.read(notificationsProvider.notifier);
      _onLoadMore = notifier.loadMore;

      return ScaffoldWidget(
        appBar: AppBarWidget(leading: const GoBackWidget()),
        child: RefreshIndicator(
          onRefresh: notifier.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: .symmetric(horizontal: 16.0, vertical: 8.0),
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
      ),
    ],
  };
}
