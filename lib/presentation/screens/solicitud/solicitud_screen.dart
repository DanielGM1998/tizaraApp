import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tizara/config/navigation/route_observer.dart';
import 'package:tizara/main.dart';
import '../../../constants/constants.dart';
import 'package:http/http.dart' as http;

import '../../widgets/side_menu.dart';
import '../home/home_screen.dart';

class SolicitudesScreen extends StatefulWidget {
  static const String routeName = 'solicitud';

  final String idapp;

  const SolicitudesScreen({
    Key? key,
    required this.idapp,
  }) : super(key: key);

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> with SingleTickerProviderStateMixin {
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
    DateTime.now().add(const Duration(days: -15)),
    DateTime.now(),
  ];

  String now = "${DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: -15)))} a ${DateFormat('yyyy-MM-dd').format(DateTime.now())}";

  String inicio = "null", fin = "null";

  final TextEditingController _comentarioController = TextEditingController();

  // llamada a servidor para solicitudes
  void fistLoad() async {
    setState(() {
      isFirstLoadRunning = true;
    });
    try {
      final http.Response response;
      if(inicio == "null" && fin == "null"){
        inicio = DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: -15)));
        fin = DateFormat('yyyy-MM-dd').format(DateTime.now());
        response = await http.get(
          Uri(
            scheme: https,
            host: host,
            path: '/solicitud/app/getAll/$inicio/$fin',
          ),
        );
      }else if(inicio == "null"){
        inicio = fin;
        response = await http.get(
          Uri(
            scheme: https,
            host: host,
            path: '/solicitud/app/getAll/$inicio/$fin',
          ),
        );
      }else if(fin == "null"){
        fin = inicio;
        response = await http.get(
          Uri(
            scheme: https,
            host: host,
            path: '/solicitud/app/getAll/$inicio/$fin',
          ),
        );
      }else{
        response = await http.get(
          Uri(
            scheme: https,
            host: host,
            path: '/solicitud/app/getAll/$inicio/$fin',
          ),
        );
      }
      //log('/solicitud/app/getAll/'+inicio+'/'+fin);

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
    //         path: '/solicitud/app/getAll/2025-01-01/2025-02-06',
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
                screenName: "solicitud",
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
                        : const Text(nameSolicitud),
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
                              if (!isFirstLoadRunning)
                                SizedBox(height: size.height * 0.005),
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
                                        onTap: _tipoapp == "1"
                                        ? item["status"] == "2"
                                          ? () async{
                                              await _onWillPop(item['data_id'], item['local'], item["status"]);
                                            }
                                          : null
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
                                                    backgroundColor: Colors.orangeAccent,
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
                                                            overflow: TextOverflow.ellipsis, 
                                                            maxLines: 1,
                                                          ),
                                                          Text(
                                                            item['local'],
                                                            style: const TextStyle(
                                                                fontSize: 16),
                                                            overflow: TextOverflow.ellipsis, 
                                                            maxLines: 1,
                                                          ),
                                                          Text(
                                                            "Fecha solicitud: ${item['fecha_solicita']}",
                                                            style: const TextStyle(
                                                                fontSize: 12),
                                                          ),
                                                          Text(
                                                            item['status'] == "0"
                                                            ? "CANCELADA"
                                                            : item['status'] == "1"
                                                              ? "AUTORIZADA"
                                                              : "PENDIENTE",
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold
                                                            ),
                                                          ),
                                                          Text(
                                                            "Fecha de Ejecución: ${item['fecha_ejecucion']}",
                                                            style: const TextStyle(
                                                                fontSize: 12),
                                                          ),
                                                          Text(
                                                            item['hora_ejecucion']==""
                                                            ? "Todo el día"
                                                            : "Hora de Ejecución: ${item['hora_ejecucion']}",
                                                            style: const TextStyle(
                                                                fontSize: 12),
                                                          ),
                                                        ],
                                                      ),
                                                      Align(
                                                        alignment: Alignment.centerRight,
                                                        child: Padding(
                                                          padding: EdgeInsets.only(right: size.width * 0.01),
                                                          child: Icon(
                                                            Icons.arrow_forward_ios_outlined,
                                                            size: 24,
                                                            color: item["status"] == "2"
                                                                   ? Colors.orangeAccent
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

  Future<bool> _onWillPop(String id, String local, String status) async {
    final Size size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Solicitud de $local", textAlign: TextAlign.center),
            //content: Text("", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                    ),
                    onPressed: () async{
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      String? idapp = prefs.getString("id");
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop(false);
                      // ignore: use_build_context_synchronously
                      await _motivo(context, idapp!, id);
                    },
                    child: const Text('Denegar'),
                  ),
                  SizedBox(height: size.height * 0.01),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orangeAccent, 
                    ),
                    onPressed: () async{
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      String? idapp = prefs.getString("id");
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop(false);
                      // ignore: use_build_context_synchronously
                      await showProgressAutorizada(context, idapp!, id);
                    },
                    child: const Text('Autorizar'),
                  ),
                ],
              )
            ],
          ),
        )) ??
        false;
  }

  Future<bool> _motivo(BuildContext context, String idUsuario, String solicitudId) async {
    final Size size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Denegar permiso", textAlign: TextAlign.center),
            content: TextField(
                      controller: _comentarioController,
                      maxLines: 2, 
                      decoration: const InputDecoration(
                        labelText: "Escribe el motivo por el\nque se niega el permiso",
                        labelStyle: TextStyle(fontSize: 15),
                        floatingLabelAlignment: FloatingLabelAlignment.center,
                        border: OutlineInputBorder(),
                      ),
                    ),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                    ),
                    onPressed: () async{
                      _comentarioController.text="";
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('Cancelar'),
                  ),
                  SizedBox(height: size.height * 0.01),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orangeAccent, 
                    ),
                    onPressed: () async{
                      Navigator.of(context).pop(false);
                      await showProgressDenegada(context, idUsuario, solicitudId, _comentarioController.text);
                      _comentarioController.text="";
                    },
                    child: const Text('Denegar'),
                  ),
                ],
              )
            ],
          ),
        )) ??
        false;
  }

  Future<bool> _descripcion(String locatario, String descripcion) async {
    final Size size = MediaQuery.of(context).size;
    return (await showDialog(
          barrierDismissible: true,
          context: context,
          builder: (context) => AlertDialog(
            title: Text(locatario, textAlign: TextAlign.center),
            content: SingleChildScrollView(child: HtmlWidget(descripcion, textStyle: const TextStyle(fontSize: 15))),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32.0))),
            actions: <Widget>[
              SizedBox(height: size.height * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orangeAccent, 
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
      dayTextStyle: dayTextStyle,
      calendarType: CalendarDatePicker2Type.range,
      selectedDayHighlightColor: Colors.orangeAccent,
      closeDialogOnCancelTapped: true,
      firstDayOfWeek: 1,
      weekdayLabelTextStyle: const TextStyle(
        color: Colors.orangeAccent,
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
          now = "${inicio}al $fin";
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

  // Autorizacion
  Future<String> _autorizacion(idUsuario, solicitudId) async {
    try {
      var data = {
        "usuario_id": idUsuario, 
      };

      final response = await http.post(Uri(
        scheme: https,
        host: host,
        path: "/solicitud/app/cambioStatus/$solicitudId",
      ), 
      body: data
      );

      if (response.statusCode == 200) {
        String body3 = utf8.decode(response.bodyBytes);
        var jsonData = jsonDecode(body3);
        if (jsonData['response'] == true) {
          return 'Solicitud Autorizada exitosamente';
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

  showProgressAutorizada(BuildContext context, String idUsuario, String solicitudId) async {

    EasyLoading.show(
      status: 'Autorizando...',
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );

    var result = await _autorizacion(idUsuario, solicitudId);
    log(result);

    EasyLoading.dismiss();
    // ignore: use_build_context_synchronously
    showResultDialog(context, result);
  }

  // Denegación
  Future<String> _denegacion(idUsuario, solicitudId, motivo) async {
    try {
      var data = {
        "usuario_id" : idUsuario, 
        "motivo" : motivo
      };

      final response = await http.post(Uri(
        scheme: https,
        host: host,
        path: "/solicitud/app/cambioStatus/$solicitudId",
      ), 
      body: data
      );

      if (response.statusCode == 200) {
        String body3 = utf8.decode(response.bodyBytes);
        var jsonData = jsonDecode(body3);
        if (jsonData['response'] == true) {
          return 'Solicitud Denegada exitosamente';
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

  showProgressDenegada(BuildContext context, String idUsuario, String solicitudId, String motivo) async {

    EasyLoading.show(
      status: 'Denegando...',
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.clear,
    );

    var result = await _denegacion(idUsuario, solicitudId, motivo);
    log(result);

    EasyLoading.dismiss();
    // ignore: use_build_context_synchronously
    showResultDialog(context, result);
  }

}