import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/presentation/notifiers/user_notifier.dart';
import 'package:trocado/src/presentation/notifiers/couple_notifier.dart';
import 'package:trocado/src/presentation/extensions/name_initial_extension.dart';

import 'package:trocado/src/presentation/ui/home/data/home_app_bar_presentation_data.dart';

part 'home_app_bar_notifier.g.dart';

@Riverpod()
final class HomeAppBarNotifier extends _$HomeAppBarNotifier {
  @override
  Future<HomeAppBarPresentationData> build() async {
    final user = await ref.watch(userProvider.future);
    final couple = await ref.watch(coupleProvider.future);

    if (couple == null) {
      return HomeAppBarSoloPresentationData(name: user.name);
    }

    return HomeAppBarCouplePresentationData(
      currentInitial: user.name.toInitial(),
      partnerInitial: couple.partner.name.toInitial(),
      title:
          '${user.name.toFirstName()} & ${couple.partner.name.toFirstName()}',
    );
  }
}
