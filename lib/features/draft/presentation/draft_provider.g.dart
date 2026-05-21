// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$draftHash() => r'a072a56e941b59d8049493167bc2618744ef2b93';

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

/// See also [draft].
@ProviderFor(draft)
const draftProvider = DraftFamily();

/// See also [draft].
class DraftFamily extends Family<AsyncValue<DraftModel?>> {
  /// See also [draft].
  const DraftFamily();

  /// See also [draft].
  DraftProvider call(String leagueId) {
    return DraftProvider(leagueId);
  }

  @override
  DraftProvider getProviderOverride(covariant DraftProvider provider) {
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
  String? get name => r'draftProvider';
}

/// See also [draft].
class DraftProvider extends AutoDisposeStreamProvider<DraftModel?> {
  /// See also [draft].
  DraftProvider(String leagueId)
    : this._internal(
        (ref) => draft(ref as DraftRef, leagueId),
        from: draftProvider,
        name: r'draftProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$draftHash,
        dependencies: DraftFamily._dependencies,
        allTransitiveDependencies: DraftFamily._allTransitiveDependencies,
        leagueId: leagueId,
      );

  DraftProvider._internal(
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
    Stream<DraftModel?> Function(DraftRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DraftProvider._internal(
        (ref) => create(ref as DraftRef),
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
  AutoDisposeStreamProviderElement<DraftModel?> createElement() {
    return _DraftProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DraftProvider && other.leagueId == leagueId;
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
mixin DraftRef on AutoDisposeStreamProviderRef<DraftModel?> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;
}

class _DraftProviderElement
    extends AutoDisposeStreamProviderElement<DraftModel?>
    with DraftRef {
  _DraftProviderElement(super.provider);

  @override
  String get leagueId => (origin as DraftProvider).leagueId;
}

String _$draftPicksHash() => r'c1ab8fe5c4bc5da47c1dfe9352f57211d5cfb157';

/// See also [draftPicks].
@ProviderFor(draftPicks)
const draftPicksProvider = DraftPicksFamily();

/// See also [draftPicks].
class DraftPicksFamily extends Family<AsyncValue<List<DraftPick>>> {
  /// See also [draftPicks].
  const DraftPicksFamily();

  /// See also [draftPicks].
  DraftPicksProvider call(String leagueId) {
    return DraftPicksProvider(leagueId);
  }

  @override
  DraftPicksProvider getProviderOverride(
    covariant DraftPicksProvider provider,
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
  String? get name => r'draftPicksProvider';
}

/// See also [draftPicks].
class DraftPicksProvider extends AutoDisposeStreamProvider<List<DraftPick>> {
  /// See also [draftPicks].
  DraftPicksProvider(String leagueId)
    : this._internal(
        (ref) => draftPicks(ref as DraftPicksRef, leagueId),
        from: draftPicksProvider,
        name: r'draftPicksProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$draftPicksHash,
        dependencies: DraftPicksFamily._dependencies,
        allTransitiveDependencies: DraftPicksFamily._allTransitiveDependencies,
        leagueId: leagueId,
      );

  DraftPicksProvider._internal(
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
    Stream<List<DraftPick>> Function(DraftPicksRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DraftPicksProvider._internal(
        (ref) => create(ref as DraftPicksRef),
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
  AutoDisposeStreamProviderElement<List<DraftPick>> createElement() {
    return _DraftPicksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DraftPicksProvider && other.leagueId == leagueId;
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
mixin DraftPicksRef on AutoDisposeStreamProviderRef<List<DraftPick>> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;
}

class _DraftPicksProviderElement
    extends AutoDisposeStreamProviderElement<List<DraftPick>>
    with DraftPicksRef {
  _DraftPicksProviderElement(super.provider);

  @override
  String get leagueId => (origin as DraftPicksProvider).leagueId;
}

String _$availablePlayersHash() => r'3a054eff6a57d5a381a1cf2b9a1c5300b32aec90';

/// See also [availablePlayers].
@ProviderFor(availablePlayers)
const availablePlayersProvider = AvailablePlayersFamily();

/// See also [availablePlayers].
class AvailablePlayersFamily extends Family<AsyncValue<List<PlayerModel>>> {
  /// See also [availablePlayers].
  const AvailablePlayersFamily();

  /// See also [availablePlayers].
  AvailablePlayersProvider call(String leagueId, List<String> draftedIds) {
    return AvailablePlayersProvider(leagueId, draftedIds);
  }

  @override
  AvailablePlayersProvider getProviderOverride(
    covariant AvailablePlayersProvider provider,
  ) {
    return call(provider.leagueId, provider.draftedIds);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'availablePlayersProvider';
}

/// See also [availablePlayers].
class AvailablePlayersProvider
    extends AutoDisposeStreamProvider<List<PlayerModel>> {
  /// See also [availablePlayers].
  AvailablePlayersProvider(String leagueId, List<String> draftedIds)
    : this._internal(
        (ref) =>
            availablePlayers(ref as AvailablePlayersRef, leagueId, draftedIds),
        from: availablePlayersProvider,
        name: r'availablePlayersProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$availablePlayersHash,
        dependencies: AvailablePlayersFamily._dependencies,
        allTransitiveDependencies:
            AvailablePlayersFamily._allTransitiveDependencies,
        leagueId: leagueId,
        draftedIds: draftedIds,
      );

  AvailablePlayersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.leagueId,
    required this.draftedIds,
  }) : super.internal();

  final String leagueId;
  final List<String> draftedIds;

  @override
  Override overrideWith(
    Stream<List<PlayerModel>> Function(AvailablePlayersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AvailablePlayersProvider._internal(
        (ref) => create(ref as AvailablePlayersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        leagueId: leagueId,
        draftedIds: draftedIds,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PlayerModel>> createElement() {
    return _AvailablePlayersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailablePlayersProvider &&
        other.leagueId == leagueId &&
        other.draftedIds == draftedIds;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, leagueId.hashCode);
    hash = _SystemHash.combine(hash, draftedIds.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AvailablePlayersRef on AutoDisposeStreamProviderRef<List<PlayerModel>> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;

  /// The parameter `draftedIds` of this provider.
  List<String> get draftedIds;
}

class _AvailablePlayersProviderElement
    extends AutoDisposeStreamProviderElement<List<PlayerModel>>
    with AvailablePlayersRef {
  _AvailablePlayersProviderElement(super.provider);

  @override
  String get leagueId => (origin as AvailablePlayersProvider).leagueId;
  @override
  List<String> get draftedIds =>
      (origin as AvailablePlayersProvider).draftedIds;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
