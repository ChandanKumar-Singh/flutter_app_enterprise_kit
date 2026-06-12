import 'package:get_it/get_it.dart';
import 'package:enterprise_kit/core/network/api_client.dart';
import 'package:enterprise_kit/core/storage/pref_storage_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  await PrefStorageService.instance.init();

  if (!getIt.isRegistered<ApiClient>()) {
    getIt.registerLazySingleton<ApiClient>(ApiClient.new);
  }
}
