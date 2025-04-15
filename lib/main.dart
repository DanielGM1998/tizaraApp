import 'dart:convert';

import 'package:cloudflare/cloudflare.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tizara/config/navigation/route_observer.dart';
import 'package:tizara/constants/constants.dart';
import 'package:tizara/presentation/screens/aviso/aviso_screen.dart';
import 'package:tizara/presentation/screens/home/home_screen.dart';
import 'package:tizara/presentation/screens/login/login_screen.dart';
import 'package:tizara/presentation/screens/solicitud/solicitud_screen.dart';
import 'package:tizara/presentation/screens/proveedor/proveedor_screen.dart';
import 'package:tizara/presentation/screens/autorizada/autorizada_screen.dart';
import 'package:tizara/presentation/screens/solicitud_locatarios/solicitud_locatarios_screen.dart';
import 'package:tizara/presentation/screens/splash/splash_screen.dart';

import 'config/theme/app_theme.dart';
import 'presentation/screens/solicitud_locatarios/crear_solicitud_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

String? initialPayload;

// Cloudflare
late Cloudflare cloudflare;
String? cloudflareInitMessage;

void configEasyLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.circle
    ..loadingStyle = EasyLoadingStyle.light
    ..maskColor = myColor
    ..progressColor = myColor
    ..textColor = myColor
    ..dismissOnTap = false
    ..userInteractions = false;
}

// Manejador de mensajes en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Maneja el mensaje en segundo plano
  // log('Notificación en segundo plano: ${message.messageId}');
  // log('${message.notification?.body}');
  final data = message.data;
        String? title = data['title'];
        String? body = data['body'];

        // log(title!);
        // log(body!);

        if(title=="Nuevo Aviso"){
        await flutterLocalNotificationsPlugin.show(
          0,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'your_channel_id', 'your_channel_name',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon', 
              largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'), 
              color: myColor, 
              styleInformation: BigTextStyleInformation(
                message.notification?.body ?? "",
                contentTitle: message.notification?.title,
                htmlFormatContent: true,
                htmlFormatContentTitle: true,
              ),
              playSound: true, 
              ticker: 'ticker',
              enableVibration: true,
            ),
          ),
          payload: jsonEncode({
            "tipo": "avisoNotificacion",
          }), 
        );
      }else if(title=="Eliminar Aviso"){
        await flutterLocalNotificationsPlugin.cancelAll();
      }
}

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Configura el manejador de mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // inicializar notificaciones locales
  const InitializationSettings initializationSettings = InitializationSettings( 
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async{  
      // log("Notificación interactuada: ${response.payload}");
      // Si tienes un payload (puedes usarlo para navegar o procesar algo)
      if (response.payload != null && response.payload!.isNotEmpty) {

        initialPayload = response.payload!;

        final data = jsonDecode(response.payload!);  // convierte el payload a mapa
        if (data['tipo'] == "avisoNotificacion") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          int idApp = int.parse(prefs.getString('id') ?? '0');
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => AvisosScreen(idapp: idApp.toString()),
            ),
            (Route<dynamic> route) => false,
          );
        }        
      }
    }
  );

  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
  await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    initialPayload = notificationAppLaunchDetails!.notificationResponse?.payload;
  }

    
  await initializeDateFormatting('es', null); // Inicializa para español
  Intl.defaultLocale = 'es'; // Configura el locale predeterminado

  // CloudFlare
  try {
    cloudflare = Cloudflare(
      apiUrl: apiUrl,
      accountId: accountId,
      token: tokenCloudflare,
      apiKey: apiKey,
      accountEmail: accountEmail,
      userServiceKey: userServiceKey,
    );
    await cloudflare.init();
  } catch (e) {
    cloudflareInitMessage = '''
    Check your environment definitions for Cloudflare.
    Make sure to run this app with:  
    
    flutter run
    --dart-define=CLOUDFLARE_API_URL=https://api.cloudflare.com/client/v4
    --dart-define=CLOUDFLARE_ACCOUNT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxxx
    --dart-define=CLOUDFLARE_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxx
    --dart-define=CLOUDFLARE_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxx
    --dart-define=CLOUDFLARE_ACCOUNT_EMAIL=xxxxxxxxxxxxxxxxxxxxxxxxxxx
    --dart-define=CLOUDFLARE_USER_SERVICE_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxx
    
    Exception details:
    ${e.toString()}
    ''';
  }

  // Limpia la caché para evitar errores de migración
  await DefaultCacheManager().emptyCache();

  // Config progressdialog
  configEasyLoading();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (initialPayload != null) {
        final data = jsonDecode(initialPayload!);
        if (data['tipo'] == "avisoNotificacion") {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          int idApp = int.parse(prefs.getString('id') ?? '0');
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => AvisosScreen(idapp: idApp.toString()),
            ),
            (route) => false,
          );
        }
        initialPayload = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: nameApp,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme(selectedColor: 0).getTheme(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
        Locale('he', ''),
        Locale('es', ''),
        Locale('ru', ''),
        Locale('ko', ''),
        Locale('hi', ''),
      ],
      builder: EasyLoading.init(),
      navigatorObservers: [appRouteObserver],
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (BuildContext context) => const SplashScreen(),
        LoginScreen.routeName: (BuildContext context) => const LoginScreen(),
        HomeScreen.routeName: (BuildContext context) => const HomeScreen(),
        ProveedorScreen.routeName: (context) => const ProveedorScreen(idapp: ""),
        AutorizadasScreen.routeName: (context) => const AutorizadasScreen(idapp: ""),
        SolicitudesScreen.routeName: (context) => const SolicitudesScreen(idapp: ""),
        SolicitudLocatariosScreen.routeName: (context) => const SolicitudLocatariosScreen(idapp: ""),
        CrearSolicitudScreen.routeName: (context) => const CrearSolicitudScreen(idapp: ""),
        AvisosScreen.routeName: (context) => const AvisosScreen(idapp: ""),
      },
    );
  }
}
