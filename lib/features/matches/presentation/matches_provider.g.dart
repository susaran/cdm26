// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matches_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$upcomingMatchesHash() => r'b3c5e62ec2fe418097467e5c100d9912bd090eb3';

/// See also [upcomingMatches].
@ProviderFor(upcomingMatches)
final upcomingMatchesProvider =
    AutoDisposeStreamProvider<List<MatchModel>>.internal(
      upcomingMatches,
      name: r'upcomingMatchesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$upcomingMatchesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpcomingMatchesRef = AutoDisposeStreamProviderRef<List<MatchModel>>;
String _$matchDetailHash() => r'dfb7ca34ac1504c3c23cf1b8cfa8b76ab2258709';

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

/// See also [matchDetail].
@ProviderFor(matchDetail)
const matchDetailProvider = MatchDetailFamily();

/// See also [matchDetail].
class MatchDetailFamily extends Family<AsyncValue<MatchModel?>> {
  /// See also [matchDetail].
  const MatchDetailFamily();

  /// See also [matchDetail].
  MatchDetailProvider call(String matchId) {
    return MatchDetailProvider(matchId);
  }

  @override
  MatchDetailProvider getProviderOverride(
    covariant MatchDetailProvider provider,
  ) {
    return call(provider.matchId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'matchDetailProvider';
}

/// See also [matchDetail].
class MatchDetailProvider extends AutoDisposeStreamProvider<MatchModel?> {
  /// See also [matchDetail].
  MatchDetailProvider(String matchId)
    : this._internal(
        (ref) => matchDetail(ref as MatchDetailRef, matchId),
        from: matchDetailProvider,
        name: r'matchDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$matchDetailHash,
        dependencies: MatchDetailFamily._dependencies,
        allTransitiveDependencies: MatchDetailFamily._allTransitiveDependencies,
        matchId: matchId,
      );

  MatchDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.matchId,
  }) : super.internal();

  final String matchId;

  @override
  Override overrideWith(
    Stream<MatchModel?> Function(MatchDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MatchDetailProvider._internal(
        (ref) => create(ref as MatchDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        matchId: matchId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<MatchModel?> createElement() {
    return _MatchDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchDetailProvider && other.matchId == matchId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, matchId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MatchDetailRef on AutoDisposeStreamProviderRef<MatchModel?> {
  /// The parameter `matchId` of this provider.
  String get matchId;
}

class _MatchDetailProviderElement
    extends AutoDisposeStreamProviderElement<MatchModel?>
    with MatchDetailRef {
  _MatchDetailProviderElement(super.provider);

  @override
  String get matchId => (origin as MatchDetailProvider).matchId;
}

String _$matchEventsHash() => r'b4afa2ea2cdb668fefc21584b185edebe1168ef6';

/// See also [matchEvents].
@ProviderFor(matchEvents)
const matchEventsProvider = MatchEventsFamily();

/// See also [matchEvents].
class MatchEventsFamily extends Family<AsyncValue<List<MatchEvent>>> {
  /// See also [matchEvents].
  const MatchEventsFamily();

  /// See also [matchEvents].
  MatchEventsProvider call(String matchId) {
    return MatchEventsProvider(matchId);
  }

  @override
  MatchEventsProvider getProviderOverride(
    covariant MatchEventsProvider provider,
  ) {
    return call(provider.matchId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'matchEventsProvider';
}

/// See also [matchEvents].
class MatchEventsProvider extends AutoDisposeStreamProvider<List<MatchEvent>> {
  /// See also [matchEvents].
  MatchEventsProvider(String matchId)
    : this._internal(
        (ref) => matchEvents(ref as MatchEventsRef, matchId),
        from: matchEventsProvider,
        name: r'matchEventsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$matchEventsHash,
        dependencies: MatchEventsFamily._dependencies,
        allTransitiveDependencies: MatchEventsFamily._allTransitiveDependencies,
        matchId: matchId,
      );

  MatchEventsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.matchId,
  }) : super.internal();

  final String matchId;

  @override
  Override overrideWith(
    Stream<List<MatchEvent>> Function(MatchEventsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MatchEventsProvider._internal(
        (ref) => create(ref as MatchEventsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        matchId: matchId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MatchEvent>> createElement() {
    return _MatchEventsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchEventsProvider && other.matchId == matchId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, matchId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MatchEventsRef on AutoDisposeStreamProviderRef<List<MatchEvent>> {
  /// The parameter `matchId` of this provider.
  String get matchId;
}

class _MatchEventsProviderElement
    extends AutoDisposeStreamProviderElement<List<MatchEvent>>
    with MatchEventsRef {
  _MatchEventsProviderElement(super.provider);

  @override
  String get matchId => (origin as MatchEventsProvider).matchId;
}

String _$allPlayersHash() => r'6e3e4689424bab8b92cf5ab07ecb561a8416b2ef';

/// See also [allPlayers].
@ProviderFor(allPlayers)
final allPlayersProvider =
    AutoDisposeFutureProvider<List<PlayerModel>>.internal(
      allPlayers,
      name: r'allPlayersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$allPlayersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllPlayersRef = AutoDisposeFutureProviderRef<List<PlayerModel>>;
String _$nationalTeamsHash() => r'ca8fe8dbd483d2bd96806330b12fdbe502e98389';

/// See also [nationalTeams].
@ProviderFor(nationalTeams)
final nationalTeamsProvider =
    AutoDisposeStreamProvider<List<NationalTeam>>.internal(
      nationalTeams,
      name: r'nationalTeamsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$nationalTeamsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NationalTeamsRef = AutoDisposeStreamProviderRef<List<NationalTeam>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
