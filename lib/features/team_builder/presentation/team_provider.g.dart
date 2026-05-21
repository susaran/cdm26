// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$myTeamHash() => r'e5f5c32046d029089854c34cdc51c91384dee106';

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

/// See also [myTeam].
@ProviderFor(myTeam)
const myTeamProvider = MyTeamFamily();

/// See also [myTeam].
class MyTeamFamily extends Family<AsyncValue<TeamModel?>> {
  /// See also [myTeam].
  const MyTeamFamily();

  /// See also [myTeam].
  MyTeamProvider call(String leagueId) {
    return MyTeamProvider(leagueId);
  }

  @override
  MyTeamProvider getProviderOverride(covariant MyTeamProvider provider) {
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
  String? get name => r'myTeamProvider';
}

/// See also [myTeam].
class MyTeamProvider extends AutoDisposeStreamProvider<TeamModel?> {
  /// See also [myTeam].
  MyTeamProvider(String leagueId)
    : this._internal(
        (ref) => myTeam(ref as MyTeamRef, leagueId),
        from: myTeamProvider,
        name: r'myTeamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$myTeamHash,
        dependencies: MyTeamFamily._dependencies,
        allTransitiveDependencies: MyTeamFamily._allTransitiveDependencies,
        leagueId: leagueId,
      );

  MyTeamProvider._internal(
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
    Stream<TeamModel?> Function(MyTeamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MyTeamProvider._internal(
        (ref) => create(ref as MyTeamRef),
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
  AutoDisposeStreamProviderElement<TeamModel?> createElement() {
    return _MyTeamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MyTeamProvider && other.leagueId == leagueId;
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
mixin MyTeamRef on AutoDisposeStreamProviderRef<TeamModel?> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;
}

class _MyTeamProviderElement
    extends AutoDisposeStreamProviderElement<TeamModel?>
    with MyTeamRef {
  _MyTeamProviderElement(super.provider);

  @override
  String get leagueId => (origin as MyTeamProvider).leagueId;
}

String _$watchTeamHash() => r'c5338f886eeb933799e093d04069f133fd964d46';

/// See also [watchTeam].
@ProviderFor(watchTeam)
const watchTeamProvider = WatchTeamFamily();

/// See also [watchTeam].
class WatchTeamFamily extends Family<AsyncValue<TeamModel?>> {
  /// See also [watchTeam].
  const WatchTeamFamily();

  /// See also [watchTeam].
  WatchTeamProvider call(String leagueId, String userId) {
    return WatchTeamProvider(leagueId, userId);
  }

  @override
  WatchTeamProvider getProviderOverride(covariant WatchTeamProvider provider) {
    return call(provider.leagueId, provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'watchTeamProvider';
}

/// See also [watchTeam].
class WatchTeamProvider extends AutoDisposeStreamProvider<TeamModel?> {
  /// See also [watchTeam].
  WatchTeamProvider(String leagueId, String userId)
    : this._internal(
        (ref) => watchTeam(ref as WatchTeamRef, leagueId, userId),
        from: watchTeamProvider,
        name: r'watchTeamProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$watchTeamHash,
        dependencies: WatchTeamFamily._dependencies,
        allTransitiveDependencies: WatchTeamFamily._allTransitiveDependencies,
        leagueId: leagueId,
        userId: userId,
      );

  WatchTeamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.leagueId,
    required this.userId,
  }) : super.internal();

  final String leagueId;
  final String userId;

  @override
  Override overrideWith(
    Stream<TeamModel?> Function(WatchTeamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WatchTeamProvider._internal(
        (ref) => create(ref as WatchTeamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        leagueId: leagueId,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<TeamModel?> createElement() {
    return _WatchTeamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchTeamProvider &&
        other.leagueId == leagueId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, leagueId.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WatchTeamRef on AutoDisposeStreamProviderRef<TeamModel?> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;

  /// The parameter `userId` of this provider.
  String get userId;
}

class _WatchTeamProviderElement
    extends AutoDisposeStreamProviderElement<TeamModel?>
    with WatchTeamRef {
  _WatchTeamProviderElement(super.provider);

  @override
  String get leagueId => (origin as WatchTeamProvider).leagueId;
  @override
  String get userId => (origin as WatchTeamProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
