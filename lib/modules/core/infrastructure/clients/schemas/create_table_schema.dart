// ignore_for_file: non_constant_identifier_names

final CREATE_USER_TABLE = '''
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  image TEXT CHECK (LENGTH(image) <= 254),
  name TEXT UNIQUE CHECK (LENGTH(name) <= 32)
);
''';
