import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../config.dart';
import '../../data/repositories/taskflow_repository.dart';
import '../../data/services/api_client.dart';

part 'api_client.g.dart';

/// The app's [ApiClient] — base URL from compile-time config (DESIGN.md §9).
///
/// Generated as `@riverpod class ApiClientProvider`, so the provider
/// identifier is `apiClientProviderProvider` (class name + `Provider`
/// suffix). Tests override it with a MockClient-backed instance:
/// `apiClientProviderProvider.overrideWithValue(ApiClient(...))`.
@Riverpod(keepAlive: true)
class ApiClientProvider extends _$ApiClientProvider {
  @override
  ApiClient build() => ApiClient(apiBaseUrl);
}

/// Shared [TaskflowRepository] over the injected [ApiClient].
final taskflowRepositoryProvider = Provider<TaskflowRepository>((Ref ref) {
  return TaskflowRepository(ref.watch(apiClientProviderProvider));
});
