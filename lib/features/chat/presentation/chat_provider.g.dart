// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatThreadsHash() => r'4231ad89f1ffdd0a94fa3eceba4d0357ad1d0c2e';

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

/// See also [chatThreads].
@ProviderFor(chatThreads)
const chatThreadsProvider = ChatThreadsFamily();

/// See also [chatThreads].
class ChatThreadsFamily extends Family<AsyncValue<List<ChatThread>>> {
  /// See also [chatThreads].
  const ChatThreadsFamily();

  /// See also [chatThreads].
  ChatThreadsProvider call(String leagueId, String userId) {
    return ChatThreadsProvider(leagueId, userId);
  }

  @override
  ChatThreadsProvider getProviderOverride(
    covariant ChatThreadsProvider provider,
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
  String? get name => r'chatThreadsProvider';
}

/// See also [chatThreads].
class ChatThreadsProvider extends AutoDisposeStreamProvider<List<ChatThread>> {
  /// See also [chatThreads].
  ChatThreadsProvider(String leagueId, String userId)
    : this._internal(
        (ref) => chatThreads(ref as ChatThreadsRef, leagueId, userId),
        from: chatThreadsProvider,
        name: r'chatThreadsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatThreadsHash,
        dependencies: ChatThreadsFamily._dependencies,
        allTransitiveDependencies: ChatThreadsFamily._allTransitiveDependencies,
        leagueId: leagueId,
        userId: userId,
      );

  ChatThreadsProvider._internal(
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
    Stream<List<ChatThread>> Function(ChatThreadsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatThreadsProvider._internal(
        (ref) => create(ref as ChatThreadsRef),
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
  AutoDisposeStreamProviderElement<List<ChatThread>> createElement() {
    return _ChatThreadsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatThreadsProvider &&
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
mixin ChatThreadsRef on AutoDisposeStreamProviderRef<List<ChatThread>> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;

  /// The parameter `userId` of this provider.
  String get userId;
}

class _ChatThreadsProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatThread>>
    with ChatThreadsRef {
  _ChatThreadsProviderElement(super.provider);

  @override
  String get leagueId => (origin as ChatThreadsProvider).leagueId;
  @override
  String get userId => (origin as ChatThreadsProvider).userId;
}

String _$chatMessagesHash() => r'b6d8126de62c0520efa3a78661f99fa8d384cf09';

/// See also [chatMessages].
@ProviderFor(chatMessages)
const chatMessagesProvider = ChatMessagesFamily();

/// See also [chatMessages].
class ChatMessagesFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// See also [chatMessages].
  const ChatMessagesFamily();

  /// See also [chatMessages].
  ChatMessagesProvider call(String leagueId, String threadId) {
    return ChatMessagesProvider(leagueId, threadId);
  }

  @override
  ChatMessagesProvider getProviderOverride(
    covariant ChatMessagesProvider provider,
  ) {
    return call(provider.leagueId, provider.threadId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chatMessagesProvider';
}

/// See also [chatMessages].
class ChatMessagesProvider
    extends AutoDisposeStreamProvider<List<ChatMessage>> {
  /// See also [chatMessages].
  ChatMessagesProvider(String leagueId, String threadId)
    : this._internal(
        (ref) => chatMessages(ref as ChatMessagesRef, leagueId, threadId),
        from: chatMessagesProvider,
        name: r'chatMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatMessagesHash,
        dependencies: ChatMessagesFamily._dependencies,
        allTransitiveDependencies:
            ChatMessagesFamily._allTransitiveDependencies,
        leagueId: leagueId,
        threadId: threadId,
      );

  ChatMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.leagueId,
    required this.threadId,
  }) : super.internal();

  final String leagueId;
  final String threadId;

  @override
  Override overrideWith(
    Stream<List<ChatMessage>> Function(ChatMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatMessagesProvider._internal(
        (ref) => create(ref as ChatMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        leagueId: leagueId,
        threadId: threadId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ChatMessage>> createElement() {
    return _ChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider &&
        other.leagueId == leagueId &&
        other.threadId == threadId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, leagueId.hashCode);
    hash = _SystemHash.combine(hash, threadId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChatMessagesRef on AutoDisposeStreamProviderRef<List<ChatMessage>> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;

  /// The parameter `threadId` of this provider.
  String get threadId;
}

class _ChatMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatMessage>>
    with ChatMessagesRef {
  _ChatMessagesProviderElement(super.provider);

  @override
  String get leagueId => (origin as ChatMessagesProvider).leagueId;
  @override
  String get threadId => (origin as ChatMessagesProvider).threadId;
}

String _$leagueUnreadCountHash() => r'05576cc3822755e8e701673d17cd3fa1882a54f6';

/// See also [leagueUnreadCount].
@ProviderFor(leagueUnreadCount)
const leagueUnreadCountProvider = LeagueUnreadCountFamily();

/// See also [leagueUnreadCount].
class LeagueUnreadCountFamily extends Family<AsyncValue<int>> {
  /// See also [leagueUnreadCount].
  const LeagueUnreadCountFamily();

  /// See also [leagueUnreadCount].
  LeagueUnreadCountProvider call(String leagueId, String userId) {
    return LeagueUnreadCountProvider(leagueId, userId);
  }

  @override
  LeagueUnreadCountProvider getProviderOverride(
    covariant LeagueUnreadCountProvider provider,
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
  String? get name => r'leagueUnreadCountProvider';
}

/// See also [leagueUnreadCount].
class LeagueUnreadCountProvider extends AutoDisposeStreamProvider<int> {
  /// See also [leagueUnreadCount].
  LeagueUnreadCountProvider(String leagueId, String userId)
    : this._internal(
        (ref) =>
            leagueUnreadCount(ref as LeagueUnreadCountRef, leagueId, userId),
        from: leagueUnreadCountProvider,
        name: r'leagueUnreadCountProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$leagueUnreadCountHash,
        dependencies: LeagueUnreadCountFamily._dependencies,
        allTransitiveDependencies:
            LeagueUnreadCountFamily._allTransitiveDependencies,
        leagueId: leagueId,
        userId: userId,
      );

  LeagueUnreadCountProvider._internal(
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
    Stream<int> Function(LeagueUnreadCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LeagueUnreadCountProvider._internal(
        (ref) => create(ref as LeagueUnreadCountRef),
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
  AutoDisposeStreamProviderElement<int> createElement() {
    return _LeagueUnreadCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeagueUnreadCountProvider &&
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
mixin LeagueUnreadCountRef on AutoDisposeStreamProviderRef<int> {
  /// The parameter `leagueId` of this provider.
  String get leagueId;

  /// The parameter `userId` of this provider.
  String get userId;
}

class _LeagueUnreadCountProviderElement
    extends AutoDisposeStreamProviderElement<int>
    with LeagueUnreadCountRef {
  _LeagueUnreadCountProviderElement(super.provider);

  @override
  String get leagueId => (origin as LeagueUnreadCountProvider).leagueId;
  @override
  String get userId => (origin as LeagueUnreadCountProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
