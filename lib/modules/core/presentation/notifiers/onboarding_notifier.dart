import 'package:trocado/modules/core/core.dart';

final class OnboardingNotifier extends Notifier<bool> {
  final IStorageRepository _repository;

  OnboardingNotifier({required IStorageRepository repository})
    : _repository = repository,
      super(false);

  bool get enabled => success;

  void toggle(bool data) {
    success = data;
    _save(data);
  }

  Future<void> ensureInitialized() async {
    final data = await _repository.get(key: StorageConstant.onboarding.key);
    if (data == null) return;

    final enabled = bool.tryParse(data);
    if (enabled == null) return;

    success = enabled;
  }

  Future<void> _save(bool data) => _repository.save(
    key: StorageConstant.onboarding.key,
    value: data.toString(),
  );
}
