import 'package:trocado/modules/core/core.dart';

final class OnboardingNotifier extends Notifier<bool> {
  final IStorageRepository _repository;

  OnboardingNotifier({required IStorageRepository repository})
    : _repository = repository,
      super(false);

  bool get enabled => state;

  void toggle(bool data) {
    state = data;
    _save(data);
  }

  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.onboarding.key);
    if (data == null) return;

    final enabled = bool.tryParse(data);
    if (enabled == null) return;

    state = enabled;
  }

  Future<void> _save(bool data) => _repository.save(
    key: StorageConstant.onboarding.key,
    value: data.toString(),
  );
}
