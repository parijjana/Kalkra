// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playtest_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PlaytestService)
final playtestServiceProvider = PlaytestServiceProvider._();

final class PlaytestServiceProvider
    extends $AsyncNotifierProvider<PlaytestService, void> {
  PlaytestServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'playtestServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$playtestServiceHash();

  @$internal
  @override
  PlaytestService create() => PlaytestService();
}

String _$playtestServiceHash() => r'dede2c86182bcd00a846c3755a64f87a00af60b1';

abstract class _$PlaytestService extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
