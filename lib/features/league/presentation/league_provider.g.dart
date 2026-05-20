// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'league_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userLeaguesHash() => r'f2b57704e185d7bd2bcc102c5c8f706f6989f71a';

/// See also [userLeagues].
@ProviderFor(userLeagues)
final userLeaguesProvider =
    AutoDisposeStreamProvider<List<LeagueModel>>.internal(
      userLeagues,
      name: r'userLeaguesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userLeaguesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserLeaguesRef = AutoDisposeStreamProviderRef<List<LeagueModel>>;
String _$leagueMembersHash() => r'b6e7ab28eacdec327aab26c8bfc718f9beae2516';

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

/// See also [leagueMembers].
@ProviderFor(leagueMembers)
const leagueMembersProvider = LeagueMembersFamily();

/// See also [leagueMembers].
class LeagueMembersFamily extends Family<AsyncValue<List<LeagueMemberModel>>> {
  /// See also [leagueMembers].
  const LeagueMembersFamily();

  /// See also [leagueMembers].
  LeagueMembersProvider call(String leagueId) {
    return LeagueMembersProvider(leagueId);
  }

  @override
  LeagueMembersProvider getProviderOverride(
    covariant LeagueMembersProvider provider,
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
  String? get name => r'leagueMembersProvider';
}

/// See also [leagueMembers].
class LeagueMembersProvider
    extends AutoDisposeStreamProvider<List<LeagueMemberModel>> {
  /// See also [leagueMembers].
  LeagueMembersProvider(String leagueId)
    : this._internal(
        (ref) => leagueMembers(ref as LeagueMembersRef, leagueId),
        from: leagueMembersProvider,
        name: r'leagueMembersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$leagueMembersHash,
        dependencies: LeagueMembersFamily._dependencies,
        allTransitiveDependencies:
            LeagueMembersFamily._allTransitiveDependencies,
        leagueId: leagueId,
      );

  LeagueMembersProvider._internal(
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
    Stream<List<LeagueMemberModel>> Function(LeagueMembersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LeagueMembersProvider._internal(
        (ref) => create(ref as LeagueMembersRef),
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
  AutoDisposeStreamProviderElement<List<LeagueMemberModel>> createElement() {
    return _LeagueMembersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeagueMembersProvider && other.leagueId == leagueId;
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
mixin LeagueMembersRef
    on AutoDisposeStreamProviderRef<List<LeagueMemberModel>> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;
}

class _LeagueMembersProviderElement
    extends AutoDisposeStreamProviderElement<List<LeagueMemberModel>>
    with LeagueMembersRef {
  _LeagueMembersProviderElement(super.provider);

  @override
  String get leagueId => (origin as LeagueMembersProvider).leagueId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
