import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' show InAppWebView, InAppWebViewController, InAppWebViewGroupOptions, InAppWebViewOptions, URLRequest, WebUri;
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:modal_progress_indicator/modal_progress_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: AppInitialization(),
  ));
}

class AppInitialization extends StatefulWidget {
  @override
  _AppInitializationState createState() => _AppInitializationState();
}

class _AppInitializationState extends State<AppInitialization> {
  String? iosVersion;
  String? deviceModel;
  String? appsFlyerUID;
  String? firebaseToken;
  late AppsflyerSdk appsFlyerSdk;
  String? fcmToken;
  String? appsFlyerId;
  String? advertisingId;
  String? language;
  String? timezone;
  String? osVersion;
  String? deviceId;
  String queryParams = "";
  String responseMessage = "Нет ответа";
  late InAppWebViewController _controller;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    FCMTokenListener.listenForTokenUpdates((token) {
      setState(() {
        fcmToken = token;
      });
    });

    initializeApp();

    Future.delayed(const Duration(seconds: 3)).then((_) {
      _sendGetRequest();
    });

    Future.delayed(const Duration(seconds: 7)).then((_) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => GameLoadingScreen(queryParams)),
      );
    });



  }

  Future<void> initializeApp() async {
    await Firebase.initializeApp();
    await requestNotificationPermissions();
    initializeAppsFlyer();
    await fetchDeviceInfo();
    await fetchFirebaseToken();
  }

  Future<void> requestNotificationPermissions() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Пользователь разрешил уведомления");
    } else {
      print("Пользователь отказал в разрешении на уведомления");
    }
  }

  void initializeAppsFlyer() {
    AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: "P8Cmc5f5JjkNjQ3haoGbWS",
      appId: "",
      showDebug: true,
    );

    appsFlyerSdk = AppsflyerSdk(options);

    appsFlyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );

    appsFlyerSdk.startSDK(
      onSuccess: () {
        print("AppsFlyer SDK успешно инициализирован.");
      },
      onError: (int errorCode, String errorMessage) {
        print("Ошибка инициализации AppsFlyer SDK: Код $errorCode - $errorMessage");
      },
    );
  }

  Future<void> fetchDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final iosInfo = await deviceInfoPlugin.iosInfo;

    setState(() {
      iosVersion = iosInfo.systemVersion;
      deviceModel = iosInfo.utsname.machine;
    });
  }

  Future<void> fetchFirebaseToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      setState(() {
        firebaseToken = token;
      });
      print("Firebase Token: $firebaseToken");
    } catch (e) {
      print("Ошибка получения Firebase токена: $e");
    }
  }

  Future<void> _sendGetRequest() async {
    appsFlyerId = await appsFlyerSdk.getAppsFlyerUID();
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;
    deviceModel = iosInfo.utsname.machine;
    osVersion = iosInfo.systemVersion;
    language = 'rus';
    timezone = DateTime.now().timeZoneName;
    deviceId = iosInfo.identifierForVendor;

    setState(() {
      queryParams = "device_model=${deviceModel ?? ""}"
          "&os_version=${osVersion ?? ""}"
          "&fcm_token=${fcmToken ?? ""}"
          "&language=${language ?? ""}"
          "&timezone=${timezone ?? ""}"
          "&apps_flyer_id=${appsFlyerId ?? ""}"
          "&advertising_id=${advertisingId ?? ""}"
          "&device_id=${deviceId ?? ""}";
    });

    String fullUrl = "https://lgbt-avia-or-line.online/laor-ios/jmxkcj3r/index.php?$queryParams";
    print("Request URL: $fullUrl");

    try {
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        setState(() {
          responseMessage = "Успех: ${response.body}";
        });
      } else {
        setState(() {
          responseMessage = "Ошибка: ${response.statusCode} - ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        responseMessage = "Ошибка выполнения запроса: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class GameLoadingScreen extends StatefulWidget {
  final String queryParameters;
  GameLoadingScreen(this.queryParameters);

  @override
  _GameLoadingScreenState createState() => _GameLoadingScreenState(queryParameters);
}

class _GameLoadingScreenState extends State<GameLoadingScreen> {
  final String queryParameters;
  late InAppWebViewController _controller;
  _GameLoadingScreenState(this.queryParameters);
  late WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 70.0),
            child: InAppWebView(
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                  clearCache: true,
                ),
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
                _controller.loadUrl(
                    urlRequest: URLRequest(url:WebUri("https://lgbt-avia-or-line.online/laor-ios/")));
              },
              onLoadStart: (controller, url) {
                setState(() {
              //    _pageLoading = true;
                 // currentUrl = url.toString();
                });

     //           print("Loading started: $currentUrl");
              },
              onLoadStop: (controller, url) {
                setState(() {
             //     _pageLoading = false;

                });

             //   print("Loading finished: $currentUrl");
              },
            ),
          ),
        ],
      ),
    );
  }

  WebViewController _createWebViewController() {
    final controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(

        ),
      )
      ..loadRequest(Uri.parse("https://lgbt-avia-or-line.online/laor-ios/"));

    _webViewController = controller;
    return controller;
  }
}

class FCMTokenListener {
  static const MethodChannel _channel = MethodChannel('com.example.fcm/token');

  static void listenForTokenUpdates(Function(String token) onTokenUpdated) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'setToken') {
        final String token = call.arguments as String;
        onTokenUpdated(token);
        print('FCM Token received in Flutter: $token');
      }
    });
  }
}