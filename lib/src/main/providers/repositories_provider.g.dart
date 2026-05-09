// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repositories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authenticationRepository)
final authenticationRepositoryProvider = AuthenticationRepositoryProvider._();

final class AuthenticationRepositoryProvider
    extends
        $FunctionalProvider<
          IAuthenticationRepository,
          IAuthenticationRepository,
          IAuthenticationRepository
        >
    with $Provider<IAuthenticationRepository> {
  AuthenticationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authenticationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authenticationRepositoryHash();

  @$internal
  @override
  $ProviderElement<IAuthenticationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IAuthenticationRepository create(Ref ref) {
    return authenticationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IAuthenticationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IAuthenticationRepository>(value),
    );
  }
}

String _$authenticationRepositoryHash() =>
    r'694d6d8805366c5d56952b88fd4a2899b09ac962';

@ProviderFor(userRepository)
final userRepositoryProvider = UserRepositoryProvider._();

final class UserRepositoryProvider
    extends
        $FunctionalProvider<IUserRepository, IUserRepository, IUserRepository>
    with $Provider<IUserRepository> {
  UserRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRepositoryHash();

  @$internal
  @override
  $ProviderElement<IUserRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IUserRepository create(Ref ref) {
    return userRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IUserRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IUserRepository>(value),
    );
  }
}

String _$userRepositoryHash() => r'361228c46f3ac687193af7245296c1b4671aae0e';

@ProviderFor(budgetRepository)
final budgetRepositoryProvider = BudgetRepositoryProvider._();

final class BudgetRepositoryProvider
    extends
        $FunctionalProvider<
          IBudgetRepository,
          IBudgetRepository,
          IBudgetRepository
        >
    with $Provider<IBudgetRepository> {
  BudgetRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetRepositoryHash();

  @$internal
  @override
  $ProviderElement<IBudgetRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IBudgetRepository create(Ref ref) {
    return budgetRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IBudgetRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IBudgetRepository>(value),
    );
  }
}

String _$budgetRepositoryHash() => r'42d5a21b14db14fb631690657bdd3809280e5465';

@ProviderFor(expenseRepository)
final expenseRepositoryProvider = ExpenseRepositoryProvider._();

final class ExpenseRepositoryProvider
    extends
        $FunctionalProvider<
          IExpenseRepository,
          IExpenseRepository,
          IExpenseRepository
        >
    with $Provider<IExpenseRepository> {
  ExpenseRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseRepositoryHash();

  @$internal
  @override
  $ProviderElement<IExpenseRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IExpenseRepository create(Ref ref) {
    return expenseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IExpenseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IExpenseRepository>(value),
    );
  }
}

String _$expenseRepositoryHash() => r'e2a597dc9126906d2b331d2d63ed99e838e087e2';

@ProviderFor(insightsRepository)
final insightsRepositoryProvider = InsightsRepositoryProvider._();

final class InsightsRepositoryProvider
    extends
        $FunctionalProvider<
          IInsightsRepository,
          IInsightsRepository,
          IInsightsRepository
        >
    with $Provider<IInsightsRepository> {
  InsightsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'insightsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$insightsRepositoryHash();

  @$internal
  @override
  $ProviderElement<IInsightsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IInsightsRepository create(Ref ref) {
    return insightsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IInsightsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IInsightsRepository>(value),
    );
  }
}

String _$insightsRepositoryHash() =>
    r'902a07b8a0bb85d8e9031ef1540f15869a2ec82c';
