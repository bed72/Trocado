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

String _$loggerClientHash() => r'bc0bbc82cbd4ef5c1bf58ba9cf12639a03b05e8d';

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

String _$databaseClientHash() => r'4b2535a4412e0297c9f3457303cffdeb5b0757f4';

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
    r'1ff49a64e04c6717d336f626dc8882cf869b61f2';

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
    r'6dc037396f23fc839fe726377f6fcac8b6442884';

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

String _$loggerDataSourceHash() => r'66ec47200f8ba0dd2d40ad3d2c37516da5d9e093';

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
    r'3597d31467af097498f21cb105b1b543358876c1';

/// REPOSITORIES

@ProviderFor(moneyRepository)
final moneyRepositoryProvider = MoneyRepositoryProvider._();

/// REPOSITORIES

final class MoneyRepositoryProvider
    extends
        $FunctionalProvider<
          IMoneyRepository,
          IMoneyRepository,
          IMoneyRepository
        >
    with $Provider<IMoneyRepository> {
  /// REPOSITORIES
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

String _$moneyRepositoryHash() => r'b890ea5776b771a28f963a2d8bc20fcf1559dc60';

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

String _$loggerRepositoryHash() => r'f802530530f59ffe26fea03f3751b9bdfde7a632';

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
    r'a54cb3760bcebe62cd202ebe045f37b796ba91ed';
