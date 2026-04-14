import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/data_sources.provider.dart';

import 'package:trocado/src/data/repositories/authentication_repository.dart';

import 'package:trocado/src/domain/repositories/interface_authentication_repository.dart';

part 'repositories_provider.g.dart';

@Riverpod()
IAuthenticationRepository authenticationRepository(Ref ref) =>
    AuthenticationRepository(
      tokenDataSource: ref.watch(localTokenDataSourceProvider),
      authenticationDataSource: ref.watch(
        remoteAuthenticationDataSourceProvider,
      ),
    );
