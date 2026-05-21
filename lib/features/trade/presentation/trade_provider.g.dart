// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$leagueTradesHash() => r'f3d98e34264afa42edfc5298b15f06d8b287a50b';

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

/// See also [leagueTrades].
@ProviderFor(leagueTrades)
const leagueTradesProvider = LeagueTradesFamily();

/// See also [leagueTrades].
class LeagueTradesFamily extends Family<AsyncValue<List<TradeModel>>> {
  /// See also [leagueTrades].
  const LeagueTradesFamily();

  /// See also [leagueTrades].
  LeagueTradesProvider call(String leagueId, String userId) {
    return LeagueTradesProvider(leagueId, userId);
  }

  @override
  LeagueTradesProvider getProviderOverride(
    covariant LeagueTradesProvider provider,
  ) {
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
  String? get name => r'leagueTradesProvider';
}

/// See also [leagueTrades].
class LeagueTradesProvider extends AutoDisposeStreamProvider<List<TradeModel>> {
  /// See also [leagueTrades].
  LeagueTradesProvider(String leagueId, String userId)
    : this._internal(
        (ref) => leagueTrades(ref as LeagueTradesRef, leagueId, userId),
        from: leagueTradesProvider,
        name: r'leagueTradesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$leagueTradesHash,
        dependencies: LeagueTradesFamily._dependencies,
        allTransitiveDependencies:
            LeagueTradesFamily._allTransitiveDependencies,
        leagueId: leagueId,
        userId: userId,
      );

  LeagueTradesProvider._internal(
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
    Stream<List<TradeModel>> Function(LeagueTradesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LeagueTradesProvider._internal(
        (ref) => create(ref as LeagueTradesRef),
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
  AutoDisposeStreamProviderElement<List<TradeModel>> createElement() {
    return _LeagueTradesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeagueTradesProvider &&
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
mixin LeagueTradesRef on AutoDisposeStreamProviderRef<List<TradeModel>> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;

  /// The parameter `userId` of this provider.
  String get userId;
}

class _LeagueTradesProviderElement
    extends AutoDisposeStreamProviderElement<List<TradeModel>>
    with LeagueTradesRef {
  _LeagueTradesProviderElement(super.provider);

  @override
  String get leagueId => (origin as LeagueTradesProvider).leagueId;
  @override
  String get userId => (origin as LeagueTradesProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
