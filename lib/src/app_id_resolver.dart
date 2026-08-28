import 'package:package_info_plus/package_info_plus.dart';

/// 앱 식별자 획득 (Android applicationId / iOS Bundle Identifier)
Future<String> resolveAppId(String? configAppId) async {
  if (configAppId != null && configAppId.isNotEmpty) {
    return configAppId;
  }
  final info = await PackageInfo.fromPlatform();
  return info.packageName;
}
