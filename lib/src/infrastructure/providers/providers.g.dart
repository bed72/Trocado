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

String _$loggerClientHash() => r'04ecfcf7e471137d0008f878b95fe878645929ab';

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
        isAutoDispose: true,
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

String _$databaseClientHash() => r'bc2cc97e695bfc456f92459d01b30e1df678a5ad';

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
    r'f216a3b776f2b27c7b992d96da31ec0965796ce4';

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
    r'b1268a1d564d6784a75398ff40c82028f4653ba8';

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

String _$loggerDataSourceHash() => r'cb0380dc665f407a486c915188d6cdf2c4329552';

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
    r'77a53b517863b9b2777619d6c549462e72b34e1f';

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

String _$moneyRepositoryHash() => r'66e94ef36eb264cd9c1fae8756ac11e3afbd4c2d';

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

String _$balanceRepositoryHash() => r'378ce0bd065c56dda21748ea90a40e0476847a61';

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

String _$loggerRepositoryHash() => r'8bba4ae64b024b686950b642ddac42413983076a';

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
    r'3feaa118e699edcc255468e0cfbad41c31a5afcf';
