// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// CLINETS

@ProviderFor(loggerClient)
final loggerClientProvider = LoggerClientProvider._();

/// CLINETS

final class LoggerClientProvider
    extends $FunctionalProvider<ILoggerClient, ILoggerClient, ILoggerClient>
    with $Provider<ILoggerClient> {
  /// CLINETS
  LoggerClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggerClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggerClientHash();

  @$internal
  @override
  $ProviderElement<ILoggerClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ILoggerClient create(Ref ref) {
    return loggerClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ILoggerClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ILoggerClient>(value),
    );
  }
}

String _$loggerClientHash() => r'634360e07610f84e781c9c2c2f552b719df64a1d';

@ProviderFor(databaseClient)
final databaseClientProvider = DatabaseClientProvider._();

final class DatabaseClientProvider
    extends
        $FunctionalProvider<IDatabaseClient, IDatabaseClient, IDatabaseClient>
    with $Provider<IDatabaseClient> {
  DatabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseClientHash();

  @$internal
  @override
  $ProviderElement<IDatabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IDatabaseClient create(Ref ref) {
    return databaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IDatabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IDatabaseClient>(value),
    );
  }
}

String _$databaseClientHash() => r'cb6a333b42aa30cb67a196074f997e8b77988b4f';

/// MAPPERS

@ProviderFor(transactionToModelMapper)
final transactionToModelMapperProvider = TransactionToModelMapperProvider._();

/// MAPPERS

final class TransactionToModelMapperProvider
    extends
        $FunctionalProvider<
          TransactionToModelMapper,
          TransactionToModelMapper,
          TransactionToModelMapper
        >
    with $Provider<TransactionToModelMapper> {
  /// MAPPERS
  TransactionToModelMapperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionToModelMapperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionToModelMapperHash();

  @$internal
  @override
  $ProviderElement<TransactionToModelMapper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionToModelMapper create(Ref ref) {
    return transactionToModelMapper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionToModelMapper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionToModelMapper>(value),
    );
  }
}

String _$transactionToModelMapperHash() =>
    r'b0e323431b9a702f40430566af9cd34944bbbc4b';

@ProviderFor(transactionToEntityMapper)
final transactionToEntityMapperProvider = TransactionToEntityMapperProvider._();

final class TransactionToEntityMapperProvider
    extends
        $FunctionalProvider<
          TransactionToEntityMapper,
          TransactionToEntityMapper,
          TransactionToEntityMapper
        >
    with $Provider<TransactionToEntityMapper> {
  TransactionToEntityMapperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionToEntityMapperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionToEntityMapperHash();

  @$internal
  @override
  $ProviderElement<TransactionToEntityMapper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionToEntityMapper create(Ref ref) {
    return transactionToEntityMapper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionToEntityMapper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionToEntityMapper>(value),
    );
  }
}

String _$transactionToEntityMapperHash() =>
    r'78df157b36d4c2c5fbe806beff6fb422f96d6ba1';

/// DATASOURCES

@ProviderFor(loggerDataSource)
final loggerDataSourceProvider = LoggerDataSourceProvider._();

/// DATASOURCES

final class LoggerDataSourceProvider
    extends
        $FunctionalProvider<
          ILoggerDataSource,
          ILoggerDataSource,
          ILoggerDataSource
        >
    with $Provider<ILoggerDataSource> {
  /// DATASOURCES
  LoggerDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggerDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggerDataSourceHash();

  @$internal
  @override
  $ProviderElement<ILoggerDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ILoggerDataSource create(Ref ref) {
    return loggerDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ILoggerDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ILoggerDataSource>(value),
    );
  }
}

String _$loggerDataSourceHash() => r'a97eed8595c120eb344470f4abf23d72dc8387ea';

@ProviderFor(transactionDataSource)
final transactionDataSourceProvider = TransactionDataSourceProvider._();

final class TransactionDataSourceProvider
    extends
        $FunctionalProvider<
          ITransactionDataSource,
          ITransactionDataSource,
          ITransactionDataSource
        >
    with $Provider<ITransactionDataSource> {
  TransactionDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionDataSourceHash();

  @$internal
  @override
  $ProviderElement<ITransactionDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ITransactionDataSource create(Ref ref) {
    return transactionDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ITransactionDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ITransactionDataSource>(value),
    );
  }
}

String _$transactionDataSourceHash() =>
    r'0c35e90d530fc019816fbc8036ba2ade9bab8092';

/// REPOSITORIES
// TODO ISSO NÃO E UM REPO IMoneyRepository

@ProviderFor(moneyRepository)
final moneyRepositoryProvider = MoneyRepositoryProvider._();

/// REPOSITORIES
// TODO ISSO NÃO E UM REPO IMoneyRepository

final class MoneyRepositoryProvider
    extends
        $FunctionalProvider<
          IMoneyRepository,
          IMoneyRepository,
          IMoneyRepository
        >
    with $Provider<IMoneyRepository> {
  /// REPOSITORIES
  // TODO ISSO NÃO E UM REPO IMoneyRepository
  MoneyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moneyRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moneyRepositoryHash();

  @$internal
  @override
  $ProviderElement<IMoneyRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IMoneyRepository create(Ref ref) {
    return moneyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IMoneyRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IMoneyRepository>(value),
    );
  }
}

String _$moneyRepositoryHash() => r'f2b23e756f1fb71423bb45a4e16391347cc7b9cc';

@ProviderFor(balanceRepository)
final balanceRepositoryProvider = BalanceRepositoryProvider._();

final class BalanceRepositoryProvider
    extends
        $FunctionalProvider<
          IBalanceRepository,
          IBalanceRepository,
          IBalanceRepository
        >
    with $Provider<IBalanceRepository> {
  BalanceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'balanceRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$balanceRepositoryHash();

  @$internal
  @override
  $ProviderElement<IBalanceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IBalanceRepository create(Ref ref) {
    return balanceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IBalanceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IBalanceRepository>(value),
    );
  }
}

String _$balanceRepositoryHash() => r'01e5eed8681772bb6fe24151576b1a9a8154be66';

@ProviderFor(loggerRepository)
final loggerRepositoryProvider = LoggerRepositoryProvider._();

final class LoggerRepositoryProvider
    extends
        $FunctionalProvider<
          ILoggerRepository,
          ILoggerRepository,
          ILoggerRepository
        >
    with $Provider<ILoggerRepository> {
  LoggerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggerRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggerRepositoryHash();

  @$internal
  @override
  $ProviderElement<ILoggerRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ILoggerRepository create(Ref ref) {
    return loggerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ILoggerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ILoggerRepository>(value),
    );
  }
}

String _$loggerRepositoryHash() => r'd2ee66293038443698e2ca57c82f9a0cd17e6d5c';

@ProviderFor(transactionRepository)
final transactionRepositoryProvider = TransactionRepositoryProvider._();

final class TransactionRepositoryProvider
    extends
        $FunctionalProvider<
          ITransactionRepository,
          ITransactionRepository,
          ITransactionRepository
        >
    with $Provider<ITransactionRepository> {
  TransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<ITransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ITransactionRepository create(Ref ref) {
    return transactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ITransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ITransactionRepository>(value),
    );
  }
}

String _$transactionRepositoryHash() =>
    r'a7d5bc63142b4cbdba0121009759e5afba55011b';
