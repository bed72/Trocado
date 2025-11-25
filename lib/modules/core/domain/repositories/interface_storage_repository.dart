abstract interface class IStorageRepository {
  Future<String?> get({required String key});
  Future<void> delete({required String key});
  Future<void> save({required String key, required String value});
}
