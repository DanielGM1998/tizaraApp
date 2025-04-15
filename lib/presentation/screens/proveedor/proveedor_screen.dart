import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloudflare/cloudflare.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tizara/config/navigation/route_observer.dart';
import 'package:tizara/main.dart';
import '../../../constants/constants.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' as img;

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

  final TextEditingController _comentarioController = TextEditingController();

  File? _pickedImage;
  //bool _loading = false;
  List<String> imagePaths = [];

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
                  Icons.check,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Error, verificar conexión a Internet",
                  style: TextStyle(
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
    }

    if (!mounted) return;

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
                    Icons.check,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Error, verificar conexión a Internet",
                    style: TextStyle(
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

  // carga de imagenes
  void handleMultipleImagesFromCamera(Function setStateDialog) async {
    try {
      final img.ImagePicker picker = img.ImagePicker();
      List<String> capturedImages = [];
        final img.XFile? imageFile = await picker.pickImage(source: img.ImageSource.camera);
        if (imageFile != null) {
          capturedImages.add(imageFile.path);
          setStateDialog(() {
            imagePaths = List.from(imagePaths)..add(imageFile.path);
          });
        }
    } catch (e) {
      //log("Error al tomar la foto: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fistLoad();
    controller = ScrollController()..addListener(loadMore);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return FutureBuilder(
      future: getVariables(),
      builder: (context, snapshot) {
        if (snapshot.data == false) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) { return; }
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                HomeScreen.routeName,
                (Route<dynamic> route) => false,
              );
              // Navigator.of(context).pushAndRemoveUntil(
              //   _buildPageRoute(const HomeScreen()),
              //   (Route<dynamic> route) =>
              //       false, // Remueve todas las páginas previas
              // );
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
              child: RouteAwareWidget(
                screenName: "proveedor",
                child: Scaffold(
                  key: _scaffoldKey,
                  backgroundColor: Colors.white.withOpacity(1),
                  drawer: SideMenu(userapp: _userapp!, tipoapp: _tipoapp!, idapp: widget.idapp),
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
                      isSearching
                      ? const Text("")
                      : IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: (){
                          fistLoad();
                        },
                      ),
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
                            navigatorKey.currentState?.pushNamedAndRemoveUntil(
                              HomeScreen.routeName,
                              (Route<dynamic> route) => false,
                            );
                            // Navigator.of(context).pushAndRemoveUntil(
                            //   _buildPageRoute(const HomeScreen()),
                            //   (Route<dynamic> route) =>
                            //       false, // Remueve todas las páginas previas
                            // );
                          },
                        ),
                      ],
                    ),
                    leadingWidth: size.width * 0.28,
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
                          // ignore: implicit_call_tearoffs
                          builder: MaterialIndicatorDelegate(
                            builder: (context, controller) {
                              return Icon(
                                Icons.refresh_outlined,
                                color: myColor,
                                size: size.width * 0.1,
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
                                        onTap: _tipoapp == "3"
                                        ? () async{
                                            //log(item['data_id']);
                                            await _onWillPop(item['data_id'], item['servicio'], item['nombre_contacto']);
                                          }
                                        : null,
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
                                                      0.06,
                                                  child: const Icon(Icons.person,
                                                      color: Colors.white),
                                                ),
                                                SizedBox(
                                                    width: MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.04),
                                                Expanded(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
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
                                                              overflow: TextOverflow.ellipsis, 
                                                              maxLines: 1,
                                                            ),
                                                            Text(
                                                              item['nombre_contacto'],
                                                              style: const TextStyle(
                                                                  fontSize: 16),
                                                              overflow: TextOverflow.ellipsis, 
                                                              maxLines: 1,
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
                                                              overflow: TextOverflow.ellipsis, 
                                                              maxLines: 1,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Align(
                                                        alignment: Alignment.centerRight,
                                                        child: Padding(
                                                          padding: EdgeInsets.only(right: size.width * 0.01),
                                                          child: Icon(
                                                            Icons.arrow_forward_ios_outlined,
                                                            size: 24,
                                                            color: _tipoapp == "3"
                                                            ? Colors.green
                                                            : Colors.grey
                                                          ),
                                                        ),
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
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<bool> _onWillPop(String id, String servicio, String nombre) async {
    final Size size = MediaQuery.of(context).size;
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
                      SizedBox(height: size.height * 0.01),
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
    final Size size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setStateDialog) =>
            AlertDialog(
              title: Text("¿Registrar Entrada de $servicio?", textAlign: TextAlign.center),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(nombre, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                      SizedBox(height: size.height * 0.02),
                      TextField(
                        controller: _comentarioController,
                        maxLines: 2, 
                        decoration: const InputDecoration(
                          labelText: "Escribe comentarios aquí",
                          border: OutlineInputBorder(), 
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      _pickedImage == null
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            Container(
                              height: size.height * 0.3,
                              decoration: BoxDecoration(
                                  color: myColor,
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: FileImage(_pickedImage as File),
                                  )),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      Column(
                        children: [
                          Container(
                            height: 0,
                            color: Colors.transparent,
                          ),
                          Column(
                            children: <Widget>[
                              Container(
                                height: 10,
                              ),
                              if (imagePaths.isEmpty) const SizedBox(height: 0),
                              if (imagePaths.isNotEmpty)
                                Container(
                                  color: Colors.black12,
                                  child: ImageSlideshow(
                                    width: double.infinity,
                                    height: size.height * 0.2,
                                    initialPage: 0,
                                    indicatorColor: Colors.blueAccent,
                                    indicatorBackgroundColor: Colors.white,
                                    onPageChanged: (value) {},
                                    autoPlayInterval: 0,
                                    isLoop: false,
                                    indicatorRadius: 5,
                                    indicatorPadding: 7,
                                    disableUserScrolling: false,
                                    indicatorBottomPadding: 10,
                                    children: [
                                      for (String image in imagePaths)
                                        Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 0),
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: size.height * 0.4,
                                                child: Image.file(
                                                  File(image),
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (context, error, stackTrace) {
                                                    return Image.file(
                                                      File('assets/images/user.png'),
                                                      fit: BoxFit.contain,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.02),
                      GestureDetector(
                        onTap: () async {
                          handleMultipleImagesFromCamera(setStateDialog);
                        },
                        child: Container(
                          height: size.height * 0.07,
                          width: size.height * 0.07,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.blueAccent,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: size.height * 0.05,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              actions: <Widget>[
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        imagePaths = [];
                        _comentarioController.text="";
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('No'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green, 
                      ),
                      onPressed: () async{
                        // log(widget.idapp);
                        // log(id);
                        // log(_comentarioController.text);
                        //log(imagePaths[0]);

                        showProgressEntrada(context, widget.idapp, id, _comentarioController.text, imagePaths);
                        _comentarioController.text="";
                        setStateDialog(() {
                          imagePaths = [];
                        });
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Si'),
                    ),
                  ],
                )
              ],
            ),
          ),
        )) ??
        false;
  }

Future<bool> _onWillPop3(String id, String local, String solicitante) async {
    final Size size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setStateDialog) =>
            AlertDialog(
              title: Text("¿Registrar Salida de $local?", textAlign: TextAlign.center),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(solicitante, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                      SizedBox(height: size.height * 0.02),
                      TextField(
                        controller: _comentarioController,
                        maxLines: 2, 
                        decoration: const InputDecoration(
                          labelText: "Escribe comentarios aquí",
                          border: OutlineInputBorder(), 
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      _pickedImage == null
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            Container(
                              height: size.height * 0.3,
                              decoration: BoxDecoration(
                                  color: myColor,
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: FileImage(_pickedImage as File),
                                  )),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      Column(
                        children: [
                          Container(
                            height: 0,
                            color: Colors.transparent,
                          ),
                          Column(
                            children: <Widget>[
                              Container(
                                height: 10,
                              ),
                              if (imagePaths.isEmpty) const SizedBox(height: 0),
                              if (imagePaths.isNotEmpty)
                                Container(
                                  color: Colors.black12,
                                  child: ImageSlideshow(
                                    width: double.infinity,
                                    height: size.height * 0.2,
                                    initialPage: 0,
                                    indicatorColor: Colors.blueAccent,
                                    indicatorBackgroundColor: Colors.white,
                                    onPageChanged: (value) {},
                                    autoPlayInterval: 0,
                                    isLoop: false,
                                    indicatorRadius: 5,
                                    indicatorPadding: 7,
                                    disableUserScrolling: false,
                                    indicatorBottomPadding: 10,
                                    children: [
                                      for (String image in imagePaths)
                                        Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 0),
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: size.height * 0.4,
                                                child: Image.file(
                                                  File(image),
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (context, error, stackTrace) {
                                                    return Image.file(
                                                      File('assets/images/user.png'),
                                                      fit: BoxFit.contain,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: size.height * 0.02),
                      GestureDetector(
                        onTap: () async {
                          handleMultipleImagesFromCamera(setStateDialog);
                        },
                        child: Container(
                          height: size.height * 0.07,
                          width: size.height * 0.07,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.blueAccent,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: size.height * 0.05,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0))),
              actions: <Widget>[
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        imagePaths = [];
                        _comentarioController.text="";
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('No'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blueAccent, 
                      ),
                      onPressed: () async{
                        // log(widget.idapp);
                        // log(id);
                        // log(_comentarioController.text);
                        //log(imagePaths[0]);

                        showProgressSalida(context, widget.idapp, id, _comentarioController.text, imagePaths);
                        _comentarioController.text="";
                        setStateDialog(() {
                          imagePaths = [];
                        });
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Si'),
                    ),
                  ],
                )
              ],
            ),
          ),
        )) ??
        false;
  }

  // add Imagen
  Future<String> _addImagen(idUsuario, proveedorId, imagenId, varianteUno, varianteDos, tipo) async {
    try {
      var data = {
        "id": proveedorId, 
        "id_usuario": idUsuario, 
        "imagen_id": imagenId, 
        "variante_uno": varianteUno, 
        "variante_dos": varianteDos,
        "tipo": tipo,
      };

      final response = await http.post(Uri(
        scheme: https,
        host: host,
        path: '/imagen/app/imagenProveedor/',
      ), 
      body: data
      );

      if (response.statusCode == 200) {
        String body3 = utf8.decode(response.bodyBytes);
        var jsonData = jsonDecode(body3);
        if (jsonData['response'] == true) {
          return 'Imagen registrada exitosamente';
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

  Future<void> showResultDialog(BuildContext context, String result) async {  
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
    }else if (result == 'No hay entrada registrada') {
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

  // Entrada
  Future<String> _entrada(idUsuario, proveedorId, notasVigilancia) async {
    // log(idUsuario);
    // log(proveedorId);
    // log(notasVigilancia);
    try {

      var data = {
        "idUsuario": idUsuario, 
        "proveedor_id": proveedorId,
        "notas_entrada": notasVigilancia, 
      };

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

  showProgressEntrada(BuildContext context, String idUsuario, String proveedorId, String notasVigilancia, List<String> imagePaths) async {

    EasyLoading.show(
      status: 'Guardando...',
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );


    for (String image in imagePaths) {
      String customFileName = "Tizara_proveedor_entrada_${DateTime.now().millisecondsSinceEpoch}.jpg";
      String variante0 = "", variante1 = "", imagenId = "";
      CloudflareHTTPResponse<CloudflareImage?> responseFromPath =
        await cloudflare.imageAPI.upload(
          fileName: customFileName,
          contentFromPath: DataTransmit<String>(
            data: image,
            progressCallback: (counter, total) {
              // log('Upload progress: $counter/$total');
            }
          )
        );
      // log(responseFromPath.body!.toString());
      if(responseFromPath.body!.variants[0].substring(responseFromPath.body!.variants[0].length-6) =="public"){
        variante1 = responseFromPath.body!.variants[0];
        variante0 = responseFromPath.body!.variants[1];
        List<String> parts = variante1.split("/");
        if (parts.length > 5) {
          imagenId = parts[parts.length - 2];
        }else{
          imagenId = "";
        }
      }else{
        variante1 = responseFromPath.body!.variants[1];
        variante0 = responseFromPath.body!.variants[0];
        List<String> parts = variante1.split("/");
        if (parts.length > 5) {
          imagenId = parts[parts.length - 2];
        }else{
          imagenId = "";
        }
      }

      // add imagen
      // ignore: unused_local_variable
      var resultado = await _addImagen(idUsuario, proveedorId, imagenId, variante0, variante1, "1");
      // log(resultado);
    }

    var result = await _entrada(idUsuario, proveedorId, notasVigilancia);
    // log(result);

    EasyLoading.dismiss();
    // ignore: use_build_context_synchronously
    showResultDialog(context, result);
  }

  // Salida
  Future<String> _salida(idUsuario, proveedorId, notasVigilancia) async {
    try {

      var data = {
        "idUsuario": idUsuario, 
        "proveedor_id": proveedorId,
        "notas_salida": notasVigilancia, 
      };

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
        } else if(jsonData['message'] == "No hay entrada registrada"){
          return "No hay entrada registrada";
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

  showProgressSalida(BuildContext context, String idUsuario, String proveedorId, String notasVigilancia, List<String> imagePaths) async {

    EasyLoading.show(
      status: 'Guardando...',
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );


    for (String image in imagePaths) {
      String customFileName = "Tizara_proveedor_salida_${DateTime.now().millisecondsSinceEpoch}.jpg";
      String variante0 = "", variante1 = "", imagenId = "";
      CloudflareHTTPResponse<CloudflareImage?> responseFromPath =
        await cloudflare.imageAPI.upload(
          fileName: customFileName,
          contentFromPath: DataTransmit<String>(
            data: image,
            progressCallback: (counter, total) {
              // log('Upload progress: $counter/$total');
            }
          )
        );
      // log(responseFromPath.body!.toString());
      if(responseFromPath.body!.variants[0].substring(responseFromPath.body!.variants[0].length-6) =="public"){
        variante1 = responseFromPath.body!.variants[0];
        variante0 = responseFromPath.body!.variants[1];
        List<String> parts = variante1.split("/");
        if (parts.length > 5) {
          imagenId = parts[parts.length - 2];
        }else{
          imagenId = "";
        }
      }else{
        variante1 = responseFromPath.body!.variants[1];
        variante0 = responseFromPath.body!.variants[0];
        List<String> parts = variante1.split("/");
        if (parts.length > 5) {
          imagenId = parts[parts.length - 2];
        }else{
          imagenId = "";
        }
      }

      // add imagen
      // ignore: unused_local_variable
      var resultado = await _addImagen(idUsuario, proveedorId, imagenId, variante0, variante1, "2");
      // log(resultado);
    }

    var result = await _salida(idUsuario, proveedorId, notasVigilancia);
    // log(result);

    EasyLoading.dismiss();
    // ignore: use_build_context_synchronously
    showResultDialog(context, result);
  }

}