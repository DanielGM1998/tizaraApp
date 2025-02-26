import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:cloudflare/cloudflare.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:image_picker/image_picker.dart' as img;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tizara/config/navigation/route_observer.dart';
import 'package:tizara/main.dart';
import '../../../constants/constants.dart';
import 'package:http/http.dart' as http;

import '../../widgets/side_menu.dart';
import '../home/home_screen.dart';

class AutorizadasScreen extends StatefulWidget {
  static const String routeName = 'autorizada';

  final String idapp;

  const AutorizadasScreen({
    Key? key,
    required this.idapp,
  }) : super(key: key);

  @override
  State<AutorizadasScreen> createState() => _AutorizadasScreenState();
}

class _AutorizadasScreenState extends State<AutorizadasScreen> with SingleTickerProviderStateMixin {
  String? _tipoapp;
  String? _userapp;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  List<DateTime?> _dialogCalendarPickerValue = [
    DateTime.now(),
    DateTime.now(),
  ];

  String now = DateFormat('yyyy-MM-dd').format(DateTime.now());

  String inicio = "null", fin = "null";

  final TextEditingController _comentarioController = TextEditingController();

  File? _pickedImage;
  //bool _loading = false;
  List<String> imagePaths = [];

  // llamada a servidor para solicitudes
  void fistLoad() async {
    setState(() {
      isFirstLoadRunning = true;
    });
    try {
      final http.Response response;
      if(inicio == "null" && fin == "null"){
        inicio = DateFormat('yyyy-MM-dd').format(DateTime.now());
        fin = DateFormat('yyyy-MM-dd').format(DateTime.now());
        response = await http.get(
          Uri(
            scheme: https,
            host: host,
            path: '/solicitud/app/getAutorizadas/'+inicio+'/'+fin,
          ),
        );
      }else if(inicio == "null"){
        inicio = fin;
        response = await http.get(
          Uri(
            scheme: https,
            host: host,
            path: '/solicitud/app/getAutorizadas/'+inicio+'/'+fin,
          ),
        );
      }else if(fin == "null"){
        fin = inicio;
        response = await http.get(
          Uri(
            scheme: https,
            host: host,
            path: '/solicitud/app/getAutorizadas/'+inicio+'/'+fin,
          ),
        );
      }else{
        response = await http.get(
          Uri(
            scheme: https,
            host: host,
            path: '/solicitud/app/getAutorizadas/'+inicio+'/'+fin,
          ),
        );
      }
      //log('/solicitud/app/getAutorizadas/'+inicio+'/'+fin);

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
    // if (hasNextPage &&
    //     !isFirstLoadRunning &&
    //     !isLoadMoreRunning &&
    //     controller.position.pixels >=
    //         controller.position.maxScrollExtent - 100) {
    //   setState(() {
    //     isLoadMoreRunning = true;
    //   });

    //   page += 1;

    //   try {
    //     final response = await http.get(
    //       Uri(
    //         scheme: https,
    //         host: host,
    //         path: '/solicitud/app/getAutorizadas/2025-01-01/2025-02-06',
    //       ),
    //     );

    //     if (response.statusCode == 200) {
    //       final jsonResponse = json.decode(response.body);
    //       List newItems = jsonResponse['data'];

    //       if (newItems.isNotEmpty) {
    //         setState(() {
    //           for (var item in newItems) {
    //             if (!items
    //                 .any((existingItem) => existingItem['data_id'] == item['data_id'])) {
    //               items.add(item);
    //             }
    //           }
    //         });
    //       } else {
    //         setState(() {
    //           hasNextPage = false; // No hay más datos para cargar
    //         });
    //       }
    //     } else {
    //       if (kDebugMode) {
    //         print("Error en la respuesta: ${response.statusCode}");
    //       }
    //     }
    //   } catch (e) {
    //     if (kDebugMode) {
    //       print('Error al cargar más datos');
    //     }
    //   }

    //   setState(() {
    //     isLoadMoreRunning = false; // Finaliza el estado de carga
    //   });
    // }
  }

  // busqueda
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
          final solicitante = removeDiacritics(item['solicitante'] ?? '');
          final local =
              removeDiacritics(item['local'] ?? '');
          return solicitante.contains(normalizedQuery) ||
              local.contains(normalizedQuery);
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
    final Size _size = MediaQuery.of(context).size;
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
                screenName: "autorizada",
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
                        : const Text(nameAutorizada),
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
                              if (!isFirstLoadRunning)
                                SizedBox(height: _size.height * 0.005),
                              if (!isFirstLoadRunning)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05), 
                                    borderRadius: BorderRadius.circular(20), 
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      _datePicker();
                                    },
                                    icon: Row(
                                      mainAxisSize: MainAxisSize.min, 
                                      children: [
                                        const Icon(Icons.date_range_outlined),
                                        const SizedBox(width: 8), 
                                        Text(now),
                                      ],
                                    ),
                                  ),
                                ),
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
                                          await _onWillPop(item['data_id'], item['local'], item['solicitante']);
                                          //log(item['data_id']);
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
                                                InkWell(
                                                  onTap: () async{
                                                    await _descripcion(item['local'], item['descripcion']);
                                                  },
                                                  child: CircleAvatar(
                                                    backgroundColor: Colors.blueAccent,
                                                    radius: MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.06,
                                                    child: const Icon(Icons.list_alt,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                                SizedBox(
                                                    width: MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.03),
                                                Expanded(
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            item['solicitante'],
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                          Text(
                                                            item['local'],
                                                            style: const TextStyle(
                                                                fontSize: 16),
                                                          ),
                                                          Text(
                                                            "Fecha de Ejecución: "+item['fecha_ejecucion'],
                                                            style: const TextStyle(
                                                                fontSize: 12),
                                                          ),
                                                          Text(
                                                            item['hora_ejecucion']==""
                                                            ? "Todo el día"
                                                            : "Hora de Ejecución: "+item['hora_ejecucion'],
                                                            style: const TextStyle(
                                                                fontSize: 12),
                                                          ),
                                                        ],
                                                      ),
                                                      Align(
                                                        alignment: Alignment.centerRight,
                                                        child: Padding(
                                                          padding: EdgeInsets.only(right: _size.width * 0.01),
                                                          child: Icon(
                                                            Icons.arrow_forward_ios_outlined,
                                                            size: 24,
                                                            color: _tipoapp == "3"
                                                                   ? Colors.blueAccent
                                                                   : Colors.grey,
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

  Future<bool> _onWillPop(String id, String local, String solicitante) async {
    final Size _size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) => AlertDialog(
            title: Text(local, textAlign: TextAlign.center),
            content: Text(solicitante, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
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
                          await _onWillPop2(id, local, solicitante);
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
                          await _onWillPop3(id, local, solicitante);
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

  Future<bool> _onWillPop2(String id, String local, String solicitante) async {
    final Size _size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setStateDialog) =>
            AlertDialog(
              title: Text("¿Registrar Entrada de "+local+"?", textAlign: TextAlign.center),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(solicitante, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                      SizedBox(height: _size.height * 0.02),
                      TextField(
                        controller: _comentarioController,
                        maxLines: 2, 
                        decoration: const InputDecoration(
                          labelText: "Escribe comentarios aquí",
                          border: OutlineInputBorder(), 
                        ),
                      ),
                      SizedBox(height: _size.height * 0.02),
                      _pickedImage == null
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            Container(
                              height: _size.height * 0.3,
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
                                    height: _size.height * 0.2,
                                    initialPage: 0,
                                    indicatorColor: Colors.blueAccent,
                                    indicatorBackgroundColor: Colors.white,
                                    children: [
                                      for (String image in imagePaths)
                                        Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 0),
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: _size.height * 0.4,
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
                                    onPageChanged: (value) {},
                                    autoPlayInterval: 0,
                                    isLoop: false,
                                    indicatorRadius: 5,
                                    indicatorPadding: 7,
                                    disableUserScrolling: false,
                                    indicatorBottomPadding: 10,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: _size.height * 0.02),
                      GestureDetector(
                        onTap: () async {
                          handleMultipleImagesFromCamera(setStateDialog);
                        },
                        child: Container(
                          height: _size.height * 0.07,
                          width: _size.height * 0.07,
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
                            size: _size.height * 0.05,
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
                SizedBox(height: _size.height * 0.02),
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
    final Size _size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setStateDialog) =>
            AlertDialog(
              title: Text("¿Registrar Salida de "+local+"?", textAlign: TextAlign.center),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(solicitante, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
                      SizedBox(height: _size.height * 0.02),
                      TextField(
                        controller: _comentarioController,
                        maxLines: 2, 
                        decoration: const InputDecoration(
                          labelText: "Escribe comentarios aquí",
                          border: OutlineInputBorder(), 
                        ),
                      ),
                      SizedBox(height: _size.height * 0.02),
                      _pickedImage == null
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            Container(
                              height: _size.height * 0.3,
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
                                    height: _size.height * 0.2,
                                    initialPage: 0,
                                    indicatorColor: Colors.blueAccent,
                                    indicatorBackgroundColor: Colors.white,
                                    children: [
                                      for (String image in imagePaths)
                                        Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 0),
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: _size.height * 0.4,
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
                                    onPageChanged: (value) {},
                                    autoPlayInterval: 0,
                                    isLoop: false,
                                    indicatorRadius: 5,
                                    indicatorPadding: 7,
                                    disableUserScrolling: false,
                                    indicatorBottomPadding: 10,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: _size.height * 0.02),
                      GestureDetector(
                        onTap: () async {
                          handleMultipleImagesFromCamera(setStateDialog);
                        },
                        child: Container(
                          height: _size.height * 0.07,
                          width: _size.height * 0.07,
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
                            size: _size.height * 0.05,
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
                SizedBox(height: _size.height * 0.02),
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

  Future<bool> _descripcion(String locatario, String descripcion) async {
    final Size _size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) => AlertDialog(
            title: Text(locatario, textAlign: TextAlign.center),
            content: SingleChildScrollView(child: HtmlWidget(descripcion, textStyle: const TextStyle(fontSize: 15))),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
              SizedBox(height: _size.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blueAccent, 
                    ),
                    child: const Text('Cerrar'),
                  ),
                ],
              )
            ],
          ),
        )) ??
        false;
  }

  _datePicker() async {
    const dayTextStyle =
        TextStyle(color: Colors.black, fontWeight: FontWeight.w700);
    const weekendTextStyle =
        TextStyle(color: Colors.black, fontWeight: FontWeight.w700);
    final anniversaryTextStyle = TextStyle(
      color: Colors.red[400],
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );
    final config = CalendarDatePicker2WithActionButtonsConfig(
      //firstDate: DateTime.now(),
      dayTextStyle: dayTextStyle,
      calendarType: CalendarDatePicker2Type.range,
      selectedDayHighlightColor: Colors.blueAccent,
      closeDialogOnCancelTapped: true,
      firstDayOfWeek: 1,
      weekdayLabelTextStyle: const TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
      ),
      controlsTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
      centerAlignModePicker: true,
      customModePickerIcon: const SizedBox(),
      selectedDayTextStyle: dayTextStyle.copyWith(color: Colors.white),
      dayTextStylePredicate: ({required date}) {
        TextStyle? textStyle;
        if (date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          textStyle = weekendTextStyle;
        }
        if (DateUtils.isSameDay(date, DateTime(2021, 1, 25))) {
          textStyle = anniversaryTextStyle;
        }
        return textStyle;
      },
      dayBuilder: ({
        required date,
        textStyle,
        decoration,
        isSelected,
        isDisabled,
        isToday,
      }) {
        Widget? dayWidget;
        if (date.day % 3 == 0 && date.day % 9 != 0) {
          dayWidget = Container(
            decoration: decoration,
            child: Center(
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Text(
                    MaterialLocalizations.of(context).formatDecimal(date.day),
                    style: textStyle,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 27.5),
                    child: Container(
                      height: 4,
                      width: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: isSelected == true
                            ? Colors.white
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return dayWidget;
      },
      yearBuilder: ({
        required year,
        decoration,
        isCurrentYear,
        isDisabled,
        isSelected,
        textStyle,
      }) {
        return Center(
          child: Container(
            decoration: decoration,
            height: 36,
            width: 72,
            child: Center(
              child: Semantics(
                selected: isSelected,
                button: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      year.toString(),
                      style: textStyle,
                    ),
                    if (isCurrentYear == true)
                      Container(
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.only(left: 5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    final values = await showCalendarDatePicker2Dialog(
      context: context,
      config: config,
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
      value: _dialogCalendarPickerValue,
      dialogBackgroundColor: Colors.white,
    );
    if (values != null) {
      //log(_getValueText(config.calendarType, values));
      //log(_getValueText2(config.calendarType, values));
      inicio = _getValueText(config.calendarType, values);
      fin = _getValueText2(config.calendarType, values);
      setState(() {
        if(inicio == "null" && fin == "null"){
          now = DateFormat('yyyy-MM-dd').format(DateTime.now());
        }else if(inicio == "null"){
          now = fin;
        }else if(fin == "null"){
          now = inicio;
        }else{
          now = inicio+"al "+fin;
        }
        _dialogCalendarPickerValue = values;
        //_getExcel(inicio, fin);
      });
      fistLoad();
    }
  }

  String _getValueText(
    CalendarDatePicker2Type datePickerType,
    List<DateTime?> values,
  ) {
    values =
        values.map((e) => e != null ? DateUtils.dateOnly(e) : null).toList();
    var valueText = (values.isNotEmpty ? values[0] : null)
        .toString()
        .replaceAll('00:00:00.000', '');

    if (datePickerType == CalendarDatePicker2Type.multi) {
      valueText = values.isNotEmpty
          ? values
              .map((v) => v.toString().replaceAll('00:00:00.000', ''))
              .join(', ')
          : 'null';
    } else if (datePickerType == CalendarDatePicker2Type.range) {
      if (values.isNotEmpty) {
        final startDate = values[0].toString().replaceAll('00:00:00.000', '');
        // final endDate = values.length > 1
        //     ? values[1].toString().replaceAll('00:00:00.000', '')
        //     : 'null';
        // valueText = '$startDate to $endDate';
        valueText = startDate;
      } else {
        return 'null';
      }
    }
    return valueText;
  }

  String _getValueText2(
    CalendarDatePicker2Type datePickerType,
    List<DateTime?> values,
  ) {
    values =
        values.map((e) => e != null ? DateUtils.dateOnly(e) : null).toList();
    var valueText = (values.isNotEmpty ? values[0] : null)
        .toString()
        .replaceAll('00:00:00.000', '');

    if (datePickerType == CalendarDatePicker2Type.multi) {
      valueText = values.isNotEmpty
          ? values
              .map((v) => v.toString().replaceAll('00:00:00.000', ''))
              .join(', ')
          : 'null';
    } else if (datePickerType == CalendarDatePicker2Type.range) {
      if (values.isNotEmpty) {
        // final startDate = values[0].toString().replaceAll('00:00:00.000', '');
        final endDate = values.length > 1
            ? values[1].toString().replaceAll('00:00:00.000', '')
            : 'null';
        valueText = endDate;
      } else {
        return 'null';
      }
    }
    return valueText;
  }

  // add Imagen
  Future<String> _addImagen(idUsuario, solicitudId, imagenId, varianteUno, varianteDos, tipo) async {
    try {
      var data = {
        "id": solicitudId, 
        "id_usuario": idUsuario, 
        "imagen_id": imagenId, 
        "variante_uno": varianteUno, 
        "variante_dos": varianteDos,
        "tipo": tipo,
      };

      final response = await http.post(Uri(
        scheme: https,
        host: host,
        path: '/imagen/app/imagenSolicitud/',
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
  Future<String> _entrada(idUsuario, solicitudId, notasVigilancia) async {
    try {
      var data = {
        "id_usuario": idUsuario, 
        "notas_entrada": notasVigilancia, 
      };

      final response = await http.post(Uri(
        scheme: https,
        host: host,
        path: '/solicitud_bitacora/app/addEntrada/'+solicitudId,
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

  showProgressEntrada(BuildContext context, String idUsuario, String solicitudId, String notasVigilancia, List<String> imagePaths) async {

    EasyLoading.show(
      status: 'Guardando...',
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );


    for (String image in imagePaths) {
      String customFileName = "Tizara_entrada_${DateTime.now().millisecondsSinceEpoch}.jpg";
      String variante0 = "", variante1 = "", imagenId = "";
      CloudflareHTTPResponse<CloudflareImage?> responseFromPath =
        await cloudflare.imageAPI.upload(
          fileName: customFileName,
          contentFromPath: DataTransmit<String>(
            data: image,
            progressCallback: (counter, total) {
              //log('Upload progress: $counter/$total');
            }
          )
        );
      //log(responseFromPath.body!.toString());
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
      var resultado = await _addImagen(idUsuario, solicitudId, imagenId, variante0, variante1, "1");
      //log(resultado);
    }

    var result = await _entrada(idUsuario, solicitudId, notasVigilancia);
    //log(result);

    EasyLoading.dismiss();
    showResultDialog(context, result);
  }

  // Salida
  Future<String> _salida(idUsuario, solicitudId, notasVigilancia) async {
    try {
      var data = {
        "id_usuario": idUsuario, 
        "notas_salida": notasVigilancia, 
      };

      final response = await http.post(Uri(
        scheme: https,
        host: host,
        path: '/solicitud_bitacora/app/editSalida/'+solicitudId,
      ), 
      body: data
      );
      //log(response.body);
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

  showProgressSalida(BuildContext context, String idUsuario, String solicitudId, String notasVigilancia, List<String> imagePaths) async {

    EasyLoading.show(
      status: 'Guardando...',
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );


    for (String image in imagePaths) {
      String customFileName = "Tizara_salida_${DateTime.now().millisecondsSinceEpoch}.jpg";
      String variante0 = "", variante1 = "", imagenId = "";
      CloudflareHTTPResponse<CloudflareImage?> responseFromPath =
        await cloudflare.imageAPI.upload(
          fileName: customFileName,
          contentFromPath: DataTransmit<String>(
            data: image,
            progressCallback: (counter, total) {
              //log('Upload progress: $counter/$total');
            }
          )
        );
      //log(responseFromPath.body!.toString());
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
      var resultado = await _addImagen(idUsuario, solicitudId, imagenId, variante0, variante1, "2");
      //log(resultado);
    }

    var result = await _salida(idUsuario, solicitudId, notasVigilancia);
    //log(result);

    EasyLoading.dismiss();
    showResultDialog(context, result);
  }

}

// PageRouteBuilder _buildPageRoute(Widget page) {
//   return PageRouteBuilder(
//     barrierColor: Colors.black.withOpacity(0.6),
//     opaque: false,
//     pageBuilder: (_, __, ___) => page,
//     transitionDuration: const Duration(milliseconds: 200),
//     transitionsBuilder: (_, animation, __, child) {
//       return BackdropFilter(
//         filter: ImageFilter.blur(
//           sigmaX: 5 * animation.value,
//           sigmaY: 5 * animation.value,
//         ),
//         child: FadeTransition(
//           opacity: animation,
//           child: child,
//         ),
//       );
//     },
//   );
// }