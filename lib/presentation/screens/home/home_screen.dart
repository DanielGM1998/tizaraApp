import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tizara/constants/constants.dart';

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

  @override
  void initState() {
    super.initState();
  }

  // despues de initState
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return FutureBuilder(
      future: getVariables(),
      builder: (context, snapshot) {
        if (snapshot.data == false) {
          modulos = [
            {'nombre': 'Proveedores', 'icono': Icons.people_sharp, 'color': Colors.green, 'ruta': ProveedorScreen(idapp: _idapp!)},
          ];
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) { return; }
              bool value = await _onWillPop();
              if (value) {
                Navigator.of(context).pop(value);
              }
            },
            child: Scaffold(
                backgroundColor: Colors.white.withOpacity(1),
                appBar: myAppBar(context, nameApp, _idapp!),
                drawer: SideMenu(userapp: _userapp!, tipoapp: _tipoapp, idapp: _idapp!),
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
                  padding: EdgeInsets.symmetric(vertical: _size.width*0.02),
                  child: Column(
                    children: [
                      InkWell(
                        child: Stack(
                          children: [
                            ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                child: Container(
                                  height: _size.height*0.10,
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
                                    padding: EdgeInsets.symmetric(horizontal: _size.width * 0.05),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                "Hola " + _userapp!,
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
                                    Navigator.of(context).push(
                                    PageRouteBuilder(
                                      barrierColor: Colors.black.withOpacity(0.6),
                                      opaque: false,
                                      pageBuilder: (_, __, ___) => modulos[index]['ruta'],
                                      transitionDuration: const Duration(milliseconds: 200),
                                      transitionsBuilder: (_, animation, __, child) {
                                        return BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 5 * animation.value,
                                            sigmaY: 5 * animation.value,
                                          ),
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                  },
                                  child: Stack(
                                    children: [
                                      ClipRect(
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                          child: Container(
                                            height: _size.height*0.12,
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
                                            SizedBox(width: _size.width*0.1),
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
                                            SizedBox(width: _size.width*0.05),
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