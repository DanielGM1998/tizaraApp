import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tizara/main.dart';
import '../../../constants/constants.dart';
import 'package:http/http.dart' as http;

import '../../widgets/side_menu.dart';
import '../home/home_screen.dart';

class ProveedorScreen extends StatefulWidget {
  static const String routeName = 'proveedor';

  final String idapp;

  const ProveedorScreen({
    Key? key,
    required this.idapp,
  }) : super(key: key);

  @override
  State<ProveedorScreen> createState() => _ProveedorScreenState();
}

class _ProveedorScreenState extends State<ProveedorScreen>
    with SingleTickerProviderStateMixin {
  String? _tipoapp;
  String? _userapp;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<dynamic> glucosas = [];
  bool isLoading = false;
  bool finalScreen = false;

  List<dynamic> filteredItems = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  Future<bool?> getVariables() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _tipoapp = prefs.getString("usuario_tipo_id");
    _userapp = prefs.getString("nombre");
    return false;
  }

  bool isFirstLoadRunning = false;
  bool hasNextPage = true;
  bool isLoadMoreRunning = false;
  int page = 1;
  final int limit = 50;
  List items = [];
  late ScrollController controller;

  final colors = <Color>[
    myColorBackground1,
    myColorBackground2,
  ];

  void fistLoad() async {
    setState(() {
      isFirstLoadRunning = true;
    });
    try {
      final response = await http.get(
        Uri(
          scheme: https,
          host: host,
          path: '/proveedor/app/getAll',
        ),
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          items = jsonResponse['data'];
          filteredItems = List.from(items); // Inicializa la lista filtrada
        });
      } else {
        if (kDebugMode) {
          print("Error en la respuesta: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar datos');
      }
    }

    setState(() {
      isFirstLoadRunning = false;
    });
  }

  void loadMore() async {
    if (hasNextPage &&
        !isFirstLoadRunning &&
        !isLoadMoreRunning &&
        controller.position.pixels >=
            controller.position.maxScrollExtent - 100) {
      setState(() {
        isLoadMoreRunning = true;
      });

      page += 1;

      try {
        final response = await http.get(
          Uri(
            scheme: https,
            host: host,
            path: '/proveedor/app/getAll',
          ),
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          List newItems = jsonResponse['data'];

          if (newItems.isNotEmpty) {
            setState(() {
              for (var item in newItems) {
                if (!items
                    .any((existingItem) => existingItem['id'] == item['id'])) {
                  items.add(item);
                }
              }
            });
          } else {
            setState(() {
              hasNextPage = false; // No hay más datos para cargar
            });
          }
        } else {
          if (kDebugMode) {
            print("Error en la respuesta: ${response.statusCode}");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error al cargar más datos');
        }
      }

      setState(() {
        isLoadMoreRunning = false; // Finaliza el estado de carga
      });
    }
  }

  void toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        searchController.clear();
        filteredItems = List.from(items); // Restaura la lista original
      }
    });
  }

  String removeDiacritics(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ç]'), 'c');
  }

  void filterItems(String query) {
    final normalizedQuery = removeDiacritics(query);
    setState(() {
      if (query.isEmpty) {
        filteredItems = List.from(items); // Restaura todos los elementos
      } else {
        filteredItems = items.where((item) {
          final servicio = removeDiacritics(item['servicio'] ?? '');
          final nombreContacto =
              removeDiacritics(item['nombre_contacto'] ?? '');
          return servicio.contains(normalizedQuery) ||
              nombreContacto.contains(normalizedQuery);
        }).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fistLoad();
    controller = ScrollController()..addListener(loadMore);
  }

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return FutureBuilder(
      future: getVariables(),
      builder: (context, snapshot) {
        if (snapshot.data == false) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) { return; }
              Navigator.of(context).pushAndRemoveUntil(
                _buildPageRoute(const HomeScreen()),
                (Route<dynamic> route) =>
                    false, // Remueve todas las páginas previas
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0.0, 1.3),
                  colors: colors,
                  tileMode: TileMode.repeated,
                ),
              ),
              child: Scaffold(
                key: _scaffoldKey,
                backgroundColor: Colors.white.withOpacity(1),
                drawer: SideMenu(userapp: _userapp!, tipoapp: _tipoapp, idapp: widget.idapp),
                appBar: AppBar(
                  title: isSearching
                      ? TextField(
                          controller: searchController,
                          autofocus: true,
                          onChanged: filterItems,
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: "Buscar Servicio o Nombre",
                            hintStyle: TextStyle(color: Colors.black),
                            border: InputBorder.none,
                          ),
                        )
                      : const Text(nameProveedor),
                  elevation: 1,
                  shadowColor: myColor,
                  backgroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: Icon(isSearching ? Icons.close : Icons.search),
                      onPressed: toggleSearch,
                    ),
                  ],
                  iconTheme: const IconThemeData(color: myColor),
                  leading: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.home_outlined),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            _buildPageRoute(const HomeScreen()),
                            (Route<dynamic> route) =>
                                false, // Remueve todas las páginas previas
                          );
                        },
                      ),
                    ],
                  ),
                  leadingWidth: _size.width * 0.28,
                ),
                resizeToAvoidBottomInset: false,
                body: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: const Alignment(0.0, 1.3),
                          colors: colors,
                          tileMode: TileMode.repeated,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 0.0),
                      child: CustomRefreshIndicator(
                        builder: MaterialIndicatorDelegate(
                          builder: (context, controller) {
                            return Icon(
                              Icons.refresh_outlined,
                              color: myColor,
                              size: _size.width * 0.1,
                            );
                          },
                        ),
                        onRefresh: () async {
                          isFirstLoadRunning = false;
                          hasNextPage = true;
                          isLoadMoreRunning = false;
                          items = [];
                          page = 1;
                          fistLoad();
                          controller = ScrollController()..addListener(loadMore);
                          return setState(() {});
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isFirstLoadRunning)
                              const Center(
                                child: CircularProgressIndicator(color: myColor),
                              )
                            else
                              Expanded(
                                child: ListView.builder(
                                  controller: controller,
                                  itemCount: filteredItems.length +
                                      (isLoadMoreRunning ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == items.length) {
                                      return const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                              color: myColor),
                                        ),
                                      );
                                    }
              
                                    final item = filteredItems[index];
                                    return InkWell(
                                      onTap: () async{
                                        await _onWillPop(item['data_id'], item['servicio'], item['nombre_contacto']);
                                        log(item['data_id']);
                                      },
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20.0),
                                        ),
                                        elevation: 5,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: Colors.green,
                                                radius: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.07,
                                                child: const Icon(Icons.person,
                                                    color: Colors.white),
                                              ),
                                              SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.02),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item['servicio'],
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      item['nombre_contacto'],
                                                      style: const TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                    Text(
                                                      item['telefono'] == ""
                                                          ? "S/N"
                                                          : item['telefono'],
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                    Text(
                                                      item['correo'] == ""
                                                          ? "Sin correo electrónico"
                                                          : item['correo'],
                                                      style: const TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<bool> _onWillPop(String id, String servicio, String nombre) async {
    final Size _size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) => AlertDialog(
            title: Text(servicio, textAlign: TextAlign.center),
            content: Text(nombre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green, 
                        ),
                        onPressed: () async{
                          Navigator.of(context).pop(false);
                          await _onWillPop2(id, servicio, nombre);
                        },
                        child: const Text('Entrada'),
                      ),
                      SizedBox(height: _size.height * 0.01),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blueAccent, 
                        ),
                        onPressed: () async{
                          Navigator.of(context).pop(false);
                          await _onWillPop3(id, servicio, nombre);
                        },
                        child: const Text('Salida'),
                      )
                    ],
                  ),
                ],
              )
            ],
          ),
        )) ??
        false;
  }

  Future<bool> _onWillPop2(String id, String servicio, String nombre) async {
    final Size _size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) => AlertDialog(
            title: Text("¿Registrar Entrada de "+servicio+"?", textAlign: TextAlign.center),
            content: Text(nombre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
              SizedBox(height: _size.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green, 
                    ),
                    onPressed: () async{
                      Navigator.of(context).pop(false);
                      showProgressEntrada(context, widget.idapp, id);
                    },
                    child: const Text('Si'),
                  ),
                ],
              )
            ],
          ),
        )) ??
        false;
  }

  Future<bool> _onWillPop3(String id, String servicio, String nombre) async {
    final Size _size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) => AlertDialog(
            title: Text("¿Registrar Salida de "+servicio+"?", textAlign: TextAlign.center),
            content: Text(nombre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
              SizedBox(height: _size.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueAccent, 
                    ),
                    onPressed: () async{
                      Navigator.of(context).pop(false);
                      showProgressSalida(context, widget.idapp, id);
                    },
                    child: const Text('Si'),
                  ),
                ],
              )
            ],
          ),
        )) ??
        false;
  }
}

PageRouteBuilder _buildPageRoute(Widget page) {
  return PageRouteBuilder(
    barrierColor: Colors.black.withOpacity(0.6),
    opaque: false,
    pageBuilder: (_, __, ___) => page,
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
  );
}

// Entrada
Future<String> _entrada(idUsuario, proveedorId) async {
  try {
    var data = {"idUsuario": idUsuario, "proveedor_id": proveedorId};
    final response = await http.post(Uri(
      scheme: https,
      host: host,
      path: '/proveedor/app/addEntradaBitacora/',
    ), 
    body: data
    );

    if (response.statusCode == 200) {
      String body3 = utf8.decode(response.bodyBytes);
      var jsonData = jsonDecode(body3);
      if (jsonData['response'] == true) {
        return 'Entrada registrada exitosamente';
      } else {
        return 'Error, verificar conexión a Internet';
      }
    } else {
      return 'Error, verificar conexión a Internet';
    }
  } catch (e) {
    return 'Error, verificar conexión a Internet';
  }
}

showProgressEntrada(BuildContext context, String idUsuario, String proveedorId) async {
  var result = await showDialog(
    context: context,
    builder: (context) => FutureProgressDialog(_entrada(idUsuario, proveedorId)),
  );
  showResultDialogEntrada(context, result);
}

Future<void> showResultDialogEntrada(BuildContext context, String result) async {  
  if (result == 'Error, verificar conexión a Internet') {
      HapticFeedback.heavyImpact();
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent, 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black),
                ),
                child: const Icon(
                  Icons.error,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result,
                  style: const TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 10,
          duration: const Duration(seconds: 3),
        ),
      );
  } else {
    HapticFeedback.heavyImpact();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green, 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result,
                style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 10,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Salida
Future<String> _salida(idUsuario, proveedorId) async {
  try {
    var data = {"idUsuario": idUsuario, "proveedor_id": proveedorId};
    final response = await http.post(Uri(
      scheme: https,
      host: host,
      path: '/proveedor/app/editSalidaBitacora/',
    ), 
    body: data
    );

    if (response.statusCode == 200) {
      String body3 = utf8.decode(response.bodyBytes);
      var jsonData = jsonDecode(body3);
      if (jsonData['response'] == true) {
        return 'Salida registrada exitosamente';
      } else {
        return 'Error, verificar conexión a Internet';
      }
    } else {
      return 'Error, verificar conexión a Internet';
    }
  } catch (e) {
    return 'Error, verificar conexión a Internet';
  }
}

showProgressSalida(BuildContext context, String idUsuario, String proveedorId) async {
  var result = await showDialog(
    context: context,
    builder: (context) => FutureProgressDialog(_salida(idUsuario, proveedorId)),
  );
  showResultDialogSalida(context, result);
}

Future<void> showResultDialogSalida(BuildContext context, String result) async {  
  if (result == 'Error, verificar conexión a Internet') {
      HapticFeedback.heavyImpact();
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent, 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black),
                ),
                child: const Icon(
                  Icons.error,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result,
                  style: const TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 10,
          duration: const Duration(seconds: 3),
        ),
      );
  } else {
    HapticFeedback.heavyImpact();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent, 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result,
                style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 10,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
