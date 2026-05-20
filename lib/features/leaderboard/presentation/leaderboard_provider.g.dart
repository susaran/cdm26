// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leaderboardHash() => r'e31fb34005a5a1bdf5eead659794b6616afdfb46';

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

/// See also [leaderboard].
@ProviderFor(leaderboard)
const leaderboardProvider = LeaderboardFamily();

/// See also [leaderboard].
class LeaderboardFamily extends Family<AsyncValue<List<LeaderboardEntry>>> {
  /// See also [leaderboard].
  const LeaderboardFamily();

  /// See also [leaderboard].
  LeaderboardProvider call(String leagueId) {
    return LeaderboardProvider(leagueId);
  }

  @override
  LeaderboardProvider getProviderOverride(
    covariant LeaderboardProvider provider,
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
  String? get name => r'leaderboardProvider';
}

/// See also [leaderboard].
class LeaderboardProvider
    extends AutoDisposeStreamProvider<List<LeaderboardEntry>> {
  /// See also [leaderboard].
  LeaderboardProvider(String leagueId)
    : this._internal(
        (ref) => leaderboard(ref as LeaderboardRef, leagueId),
        from: leaderboardProvider,
        name: r'leaderboardProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$leaderboardHash,
        dependencies: LeaderboardFamily._dependencies,
        allTransitiveDependencies: LeaderboardFamily._allTransitiveDependencies,
        leagueId: leagueId,
      );

  LeaderboardProvider._internal(
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
    Stream<List<LeaderboardEntry>> Function(LeaderboardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LeaderboardProvider._internal(
        (ref) => create(ref as LeaderboardRef),
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
  AutoDisposeStreamProviderElement<List<LeaderboardEntry>> createElement() {
    return _LeaderboardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaderboardProvider && other.leagueId == leagueId;
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
mixin LeaderboardRef on AutoDisposeStreamProviderRef<List<LeaderboardEntry>> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;
}

class _LeaderboardProviderElement
    extends AutoDisposeStreamProviderElement<List<LeaderboardEntry>>
    with LeaderboardRef {
  _LeaderboardProviderElement(super.provider);

  @override
  String get leagueId => (origin as LeaderboardProvider).leagueId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
