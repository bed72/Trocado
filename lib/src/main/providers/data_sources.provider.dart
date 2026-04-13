import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/clients_provider.dart';

import 'package:trocado/src/infrastructure/datasources/local/local_token_data_source.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_authentication_data_source.dart';

part 'data_sources.provider.g.dart';

@Riverpod()
ILocalTokenDataSource localTokenDataSource(Ref ref) =>
    LocalTokenDataSource(client: ref.watch(storageClientProvider));

@Riverpod()
IRemoteAuthenticationDataSource remoteAuthenticationDataSource(Ref ref) =>
    RemoteAuthenticationDataSource(client: ref.watch(httpClientProvider));
