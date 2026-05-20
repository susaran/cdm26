// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userPredictionsHash() => r'623062e3b18e1e1edac5f1859bbf2a7e09e303ca';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [userPredictions].
@ProviderFor(userPredictions)
const userPredictionsProvider = UserPredictionsFamily();

/// See also [userPredictions].
class UserPredictionsFamily extends Family<AsyncValue<List<PredictionModel>>> {
  /// See also [userPredictions].
  const UserPredictionsFamily();

  /// See also [userPredictions].
  UserPredictionsProvider call(String leagueId) {
    return UserPredictionsProvider(leagueId);
  }

  @override
  UserPredictionsProvider getProviderOverride(
    covariant UserPredictionsProvider provider,
  ) {
    return call(provider.leagueId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userPredictionsProvider';
}

/// See also [userPredictions].
class UserPredictionsProvider
    extends AutoDisposeStreamProvider<List<PredictionModel>> {
  /// See also [userPredictions].
  UserPredictionsProvider(String leagueId)
    : this._internal(
        (ref) => userPredictions(ref as UserPredictionsRef, leagueId),
        from: userPredictionsProvider,
        name: r'userPredictionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userPredictionsHash,
        dependencies: UserPredictionsFamily._dependencies,
        allTransitiveDependencies:
            UserPredictionsFamily._allTransitiveDependencies,
        leagueId: leagueId,
      );

  UserPredictionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.leagueId,
  }) : super.internal();

  final String leagueId;

  @override
  Override overrideWith(
    Stream<List<PredictionModel>> Function(UserPredictionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserPredictionsProvider._internal(
        (ref) => create(ref as UserPredictionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        leagueId: leagueId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PredictionModel>> createElement() {
    return _UserPredictionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserPredictionsProvider && other.leagueId == leagueId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, leagueId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserPredictionsRef
    on AutoDisposeStreamProviderRef<List<PredictionModel>> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;
}

class _UserPredictionsProviderElement
    extends AutoDisposeStreamProviderElement<List<PredictionModel>>
    with UserPredictionsRef {
  _UserPredictionsProviderElement(super.provider);

  @override
  String get leagueId => (origin as UserPredictionsProvider).leagueId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
