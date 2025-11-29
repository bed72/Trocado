import 'package:mocktail/mocktail.dart';

import 'package:trocado/modules/core/core.dart';

final class MockUserRepository extends Mock implements IUserRepository {}

final class MockImageRepository extends Mock implements IImageRepository {}

final class MockStorageRepository extends Mock implements IStorageRepository {}
