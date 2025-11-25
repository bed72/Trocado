enum DatabaseConstant {
  databaseName(name: 'tocado'),

  userTableName(name: 'users');

  final String name;

  const DatabaseConstant({required this.name});
}
