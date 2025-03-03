import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tizara/config/navigation/route_observer.dart';
import 'package:tizara/constants/constants.dart';
import 'package:tizara/main.dart';
import 'package:tizara/presentation/screens/autorizada/autorizada_screen.dart';
import 'package:http/http.dart' as http;
import 'package:tizara/presentation/screens/solicitud/solicitud_screen.dart';
import 'package:tizara/presentation/screens/solicitud_locatarios/solicitud_locatarios_screen.dart';

import '../../widgets/my_app_bar.dart';
import '../../widgets/side_menu.dart';
import '../proveedor/proveedor_screen.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = 'home';

  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String? _tipoapp;
  String? _userapp;
  String? _idapp;

  late List<Map<String, dynamic>> modulos;

  Future<bool?> getVariables() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();    
    _tipoapp = prefs.getString("usuario_tipo_id");
    _userapp = prefs.getString("nombre");
    _idapp = prefs.getString("id");
    return false;
  }

  final colors = <Color>[
    myColorBackground1,
    myColorBackground2,
  ];

  void _initializeFCM() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Obtiene el token de FCM
    String? token = await FirebaseMessaging.instance.getToken();
    _tipoapp = prefs.getString("usuario_tipo_id");
    _idapp = prefs.getString("id");
    log("Token de FCM: $token");

    String? storedToken = prefs.getString("token");

    // Obtener el nuevo token de FCM
    String? newToken = await FirebaseMessaging.instance.getToken();


    if (newToken != null && newToken != storedToken) {      
      bool success = await _saveToken(_idapp, newToken, _tipoapp);
      if (success) {
        await prefs.setString("token", newToken);
      }
    }

    // Maneja la actualización del token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async{
      log("Nuevo token de FCM: $newToken");
      String? storedToken = prefs.getString("token");
      _tipoapp = prefs.getString("usuario_tipo_id");
      _idapp = prefs.getString("id");
      if (newToken != storedToken) {        
        bool success = await _saveToken(_idapp, newToken, _tipoapp);
        if (success) {
          await prefs.setString("token", newToken); 
        }
      }
    });
    
  }

  // Save Token
  Future<bool> _saveToken(idUsuario, token, usuarioTipoId) async {
    try {
      var data = {
        "usuario_id": idUsuario, 
        "usuario_tipo_id": usuarioTipoId,
        "token": token, 
      };

      final response = await http.post(Uri(
        scheme: https,
        host: host,
        path: '/notificacion/app/saveToken/',
      ), 
      body: data
      );

      if (response.statusCode == 200) {
        String body3 = utf8.decode(response.bodyBytes);
        var jsonData = jsonDecode(body3);
        if (jsonData['response'] == true) {
          log("token registrado correctamente");
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    _initializeFCM();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //log("Pantalla actual suscrita: $currentScreen");
    });

    // Configura los listeners para los diferentes estados de la aplicación
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async{
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _idapp = prefs.getString("id");
      // Maneja el mensaje cuando la aplicación está en primer plano
      log("Primer plano");
      log('${message.notification?.body}');

      if (currentScreen == AutorizadasScreen.routeName) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AutorizadasScreen.routeName,
          (Route<dynamic> route) => false,
          arguments: _idapp,
        );
      }else if (currentScreen == SolicitudesScreen.routeName) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          SolicitudesScreen.routeName,
          (Route<dynamic> route) => false,
          arguments: _idapp,
        );
      }else {
        log("No estamos en SolicitudesScreen o PendientesScreen, pantalla actual: $currentScreen");
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Maneja el mensaje cuando la aplicación se abre desde una notificación
      log("Segundo plano");
      log('${message.notification?.body}');
    });

    // Verifica si la aplicación fue abierta desde una notificación cuando estaba terminada
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        // Maneja el mensaje
        log("Terminada");
        log('${message.notification?.body}');
      }
    });

  }

  // despues de initState
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    //  log("Pantalla actual: $currentScreen");
    return FutureBuilder(
      future: getVariables(),
      builder: (context, snapshot) {
        if (snapshot.data == false) {
          if(_tipoapp =="1"){
            modulos = [
              {'nombre': 'Proveedores', 'icono': Icons.people_sharp, 'color': Colors.green, 'ruta':  (String id) => ProveedorScreen(idapp: id)},
              {'nombre': 'Sol. Autorizadas', 'icono': Icons.list_alt, 'color': Colors.blueAccent, 'ruta': (String id) => AutorizadasScreen(idapp: id)},
              {'nombre': 'Solicitudes', 'icono': Icons.list_alt, 'color': Colors.orangeAccent, 'ruta': (String id) => SolicitudesScreen(idapp: id)},
            ];
          }else if(_tipoapp =="2"){
            modulos = [
              {'nombre': 'Mis Solicitudes', 'icono': Icons.list_alt, 'color': Colors.grey, 'ruta': (String id) => SolicitudLocatariosScreen(idapp: id)},
            ];
          }else if(_tipoapp =="3"){
            modulos = [
              {'nombre': 'Proveedores', 'icono': Icons.people_sharp, 'color': Colors.green, 'ruta':  (String id) => ProveedorScreen(idapp: id)},
              {'nombre': 'Sol. Autorizadas', 'icono': Icons.list_alt, 'color': Colors.blueAccent, 'ruta': (String id) => AutorizadasScreen(idapp: id)},
            ];
          }else{
            modulos = [
            ];
          }
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) { return; }
              bool value = await _onWillPop();
              if (value) {
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(value);
              }
            },
            child: RouteAwareWidget(
              screenName: "home",
              child: Scaffold(
                  backgroundColor: Colors.white.withOpacity(1),
                  appBar: myAppBar(context, nameApp, _idapp!),
                  drawer: SideMenu(userapp: _userapp!, tipoapp: _tipoapp!, idapp: _idapp!),
                  resizeToAvoidBottomInset: false,
                  body: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: const Alignment(0.0, 1.3),
                        colors: colors,
                        tileMode: TileMode.repeated,
                      ),
                    ),
                    child: Padding(
                    padding: EdgeInsets.symmetric(vertical: size.width*0.02),
                    child: Column(
                      children: [
                        InkWell(
                          child: Stack(
                            children: [
                              ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                  child: Container(
                                    height: size.height*0.10,
                                    margin: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white24.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),                                        
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "Hola ${_userapp!}",
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    color: myColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2, 
                                                  overflow: TextOverflow.ellipsis, 
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: modulos.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) => modulos[index]['ruta'](_idapp!),
                                        ),
                                      );
                                      // Navigator.of(context).push(
                                      // PageRouteBuilder(
                                      //   barrierColor: Colors.black.withOpacity(0.6),
                                      //   opaque: false,
                                      //   pageBuilder: (_, __, ___) => modulos[index]['ruta'],
                                      //   transitionDuration: const Duration(milliseconds: 200),
                                      //   transitionsBuilder: (_, animation, __, child) {
                                      //     return BackdropFilter(
                                      //       filter: ImageFilter.blur(
                                      //         sigmaX: 5 * animation.value,
                                      //         sigmaY: 5 * animation.value,
                                      //       ),
                                      //       child: FadeTransition(
                                      //         opacity: animation,
                                      //         child: child,
                                      //       ),
                                      //     );
                                      //   },
                                      // ),
                                      // );
                                    },
                                    child: Stack(
                                      children: [
                                        ClipRect(
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                            child: Container(
                                              height: size.height*0.12,
                                              margin: const EdgeInsets.all(15),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(20),                                        
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Row(
                                            children: [
                                              SizedBox(width: size.width*0.1),
                                              Container(
                                                padding: const EdgeInsets.all(12.0),
                                                decoration: BoxDecoration(
                                                  color: modulos[index]['color'],
                                                  borderRadius: BorderRadius.circular(10.0),
                                                ),
                                                child: Icon(
                                                  modulos[index]['icono'],
                                                  size: 40,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: size.width*0.05),
                                              Text(
                                                modulos[index]['nombre'],
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  color: myColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ); 
                            },
                          ),
                        ),
                      ],
                    ),
                    )
                  ),
                ),
            ),
          );
        } else if (snapshot.data == true) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const SizedBox(height: 0, width: 0);
          }
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return const SizedBox(height: 0, width: 0);
      },
    );
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar aplicación'),
            content: const Text('¿Deseas salir de la aplicación?'),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Si'),
              ),
            ],
          ),
        )) ??
        false;
  }
}