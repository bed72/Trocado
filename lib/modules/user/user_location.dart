import 'package:duck_router/duck_router.dart';

final class UserLocation extends Location {
  // @override
  // void binds() {
  //   i
  //     ..registerFactory<UserMapper>(UserMapper.new)
  //     ..registerCachedFactory<IUserRepository>(
  //       () => UserRepository(
  //         mapper: i.get<UserMapper>(),
  //         datasource: i.get<IDatabaseDatasource>(),
  //       ),
  //     );
  // }

  @override
  String get path => '';
}
