abstract interface class IStorageDatasource {
  Future<String?> get(String key);
  Future<void> delete(String key);
  Future<void> save(String key, String value);
}
