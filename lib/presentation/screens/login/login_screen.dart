import 'dart:convert';
import 'dart:ui';

import 'package:awesome_top_snackbar/awesome_top_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:tizara/config/navigation/route_observer.dart';
import 'package:tizara/presentation/screens/home/home_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../constants/constants.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = 'login';

  const LoginScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ignore: non_constant_identifier_names
  String _tel_email = "";
  String _contrasena = "";
  bool _passwordVisible = true;
  var textController = TextEditingController();

  // Permisos
  // Future<void> requestPermission() async {
  //   var status = await Permission.notification.request();
  //   if (status == PermissionStatus.granted) {
  //     //print('Permiso otorgado');
  //   } else {
  //     //print('Permiso denegado');
  //   }
  // }

  @override
  void initState() {
    super.initState();
    //requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        bool value = await _onWillPop();
        if (value) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop(value);
        }
      },
      child: RouteAwareWidget(
        screenName: "login",
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment(0.0, 1.3),
                colors: <Color>[
                  myColorBackground1,
                  myColorBackground2,
                ],
                tileMode: TileMode.repeated,
              ),
            ),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 120,
                        ),
                        Image.asset(myLogo, width: size.width * 0.50),
                        SizedBox(
                          height: size.height * 0.12,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: const Text(
                                "Inicio de Sesión",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: myColor,
                                    fontSize: 25),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            SizedBox(height: size.height * 0.02),
                            //////
                            Column(
                              children: <Widget>[
                                SizedBox(
                                  height: size.height * 0.012,
                                ),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ThemeData().colorScheme.copyWith(
                                          primary: myColor,
                                        ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                    child: TextField(
                                      keyboardType:
                                          TextInputType.multiline,
                                      cursorColor: myColor,
                                      onChanged: (valor) {
                                        setState(() {
                                          _tel_email = valor;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10))),
                                          hintText: "Teléfono o Email del usuario",
                                          hintStyle: TextStyle(fontSize: 14),
                                          labelText: "Teléfono o Email",
                                          labelStyle: TextStyle(color: myColor),
                                          suffixIcon: Icon(
                                            Icons.numbers,
                                            size: 30,
                                            color: myColor,
                                          ),
                                          icon: Icon(
                                            Icons.numbers_outlined,
                                            color: myColor,
                                          )),
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: size.height * 0.012,
                                ),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ThemeData().colorScheme.copyWith(
                                          primary: myColor,
                                        ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 10, right: 10),
                                    child: TextField(
                                      obscureText: _passwordVisible,
                                      enableSuggestions: false,
                                      autocorrect: false,
                                      cursorColor: myColor,
                                      onChanged: (valor) {
                                        setState(() {
                                          _contrasena = valor;
                                        });
                                      },
                                      decoration: InputDecoration(
                                          border: const OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10))),
                                          hintText: "Contraseña del usuario",
                                          labelText: "Contraseña",
                                          labelStyle:
                                              const TextStyle(color: myColor),
                                          suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  _passwordVisible =
                                                      !_passwordVisible;
                                                });
                                              },
                                              icon: Icon(
                                                _passwordVisible
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                size: 30,
                                                color: myColor,
                                              )),
                                          icon: const Icon(
                                            Icons.bookmark,
                                            color: myColor,
                                          )),
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (value) async {
                                        if (_tel_email != "" &&
                                            _contrasena != "") {
                                          //bool isValid =
                                          //EmailValidator.validate(_tel_email);
                                          //if (isValid) {
                                          if (_contrasena.length < 5) {
                                            awesomeTopSnackbar(
                                              context,
                                              "La contraseña debe incluir al menos 5 caracteres",
                                              textStyle: const TextStyle(
                                                  color: Colors.white,
                                                  fontStyle: FontStyle.normal,
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 20),
                                              backgroundColor:
                                                  Colors.orangeAccent,
                                              icon: const Icon(Icons.check,
                                                  color: Colors.black),
                                              iconWithDecoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                    color: Colors.black),
                                              ),
                                            );
                                          } else {
                                            showProgress(
                                                context, _tel_email, _contrasena);
                                          }
                                          // } else {
                                          //   awesomeTopSnackbar(
                                          //     context,
                                          //     "Debe ingresar un Email valido",
                                          //     textStyle: const TextStyle(
                                          //         color: Colors.white,
                                          //         fontStyle: FontStyle.normal,
                                          //         fontWeight: FontWeight.w400,
                                          //         fontSize: 20),
                                          //     backgroundColor:
                                          //         Colors.orangeAccent,
                                          //     icon: const Icon(Icons.check,
                                          //         color: Colors.black),
                                          //     iconWithDecoration: BoxDecoration(
                                          //       borderRadius:
                                          //           BorderRadius.circular(20),
                                          //       border: Border.all(
                                          //           color: Colors.black),
                                          //     ),
                                          //   );
                                          // }
                                        } else {
                                          awesomeTopSnackbar(
                                            context,
                                            "Debe ingresar teléfono y contraseña",
                                            textStyle: const TextStyle(
                                                color: Colors.white,
                                                fontStyle: FontStyle.normal,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 20),
                                            backgroundColor: Colors.orangeAccent,
                                            icon: const Icon(Icons.check,
                                                color: Colors.black),
                                            iconWithDecoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border:
                                                  Border.all(color: Colors.black),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: size.height * 0.02,
                                ),
                              ],
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.only(
                                  top: 10, right: 40, left: 40),
                              child: OutlinedButton(
                                onPressed: () async {
                                  if (_tel_email != "" && _contrasena != "") {
                                    if (_contrasena.length < 5) {
                                      awesomeTopSnackbar(
                                        context,
                                        "La contraseña debe incluir al menos 5 caracteres",
                                        textStyle: const TextStyle(
                                            color: Colors.white,
                                            fontStyle: FontStyle.normal,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 16),
                                        backgroundColor: Colors.redAccent,
                                        icon: const Icon(Icons.error,
                                            color: Colors.black),
                                        iconWithDecoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.black),
                                        ),
                                      );
                                    } else {
                                      showProgress(
                                          context, _tel_email, _contrasena);
                                    }
                                  } else {
                                    awesomeTopSnackbar(
                                      context,
                                      "Debe ingresar teléfono y contraseña",
                                      textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontStyle: FontStyle.normal,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16),
                                      backgroundColor: Colors.redAccent,
                                      icon: const Icon(Icons.error,
                                          color: Colors.black),
                                      iconWithDecoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.black),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  "Iniciar sesión",
                                  style: TextStyle(color: myColor),
                                ),
                              ),
                            ),
                            Container(
                                color: Colors.transparent,
                                height: size.height * 0.10),
                          ],
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
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Si'),
              ),
            ],
          ),
        )) ??
        false;
  }
}

// ignore: non_constant_identifier_names
Future<String> _check(tel_email, pass) async {
  try {
    var data = {"dato": tel_email, "contrasena": pass};
    final response = await http.post(
      Uri(
        scheme: https,
        host: host,
        path: '/usuario/app/login',
      ),
      body: data,
      // headers: <String, String>{
      //   'Content-Type': 'application/json; charset=UTF-8',
      //   'Access-Control-Allow-Origin': '*'
      // },
    );
    if (response.statusCode == 200) {
      String body3 = utf8.decode(response.bodyBytes);
      var jsonData = jsonDecode(body3);
      //print(jsonData);
      //print(jsonData['result']['nombre']);
      if (jsonData['response'] == true) {
        //return 'Datos Correctos,';
        return "Datos Correctos,${jsonData['result']['id']},${jsonData['result']['nombre']},${jsonData['result']['apellidos']},${jsonData['result']['telefono']},${jsonData['result']['email']},${jsonData['result']['usuario_tipo_id']}";
      } else {
        return 'Verifique sus datos';
      }
    } else {
      return 'Error, verificar conexión a Internet';
    }
  } catch (e) {
    return 'Error, verificar conexión a Internet';
  }
}

showProgress(BuildContext context, String telEmail, String pass) async {
  var result = await showDialog(
    context: context,
    builder: (context) => FutureProgressDialog(_check(telEmail, pass)),
  );
  // ignore: use_build_context_synchronously
  showResultDialog(context, result, telEmail, pass);
}

Future<void> showResultDialog(
    BuildContext context, String result, String telEmail, String pass) async {
  var splitted = result.split(',');
  if (result == 'Error, verificar conexión a Internet') {
    awesomeTopSnackbar(
      context,
      "Error, verificar conexión a Internet",
      textStyle: const TextStyle(
          color: Colors.white,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
          fontSize: 16),
      backgroundColor: Colors.redAccent,
      icon: const Icon(Icons.error, color: Colors.black),
      iconWithDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black),
      ),
    );
  } else if (result == 'Verifique sus datos') {
    awesomeTopSnackbar(
      context,
      "Verifique sus datos",
      textStyle: const TextStyle(
          color: Colors.white,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.w400,
          fontSize: 16),
      backgroundColor: Colors.redAccent,
      icon: const Icon(Icons.error, color: Colors.black),
      iconWithDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black),
      ),
    );
  } else if (splitted[0] == 'Datos Correctos') {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('id', splitted[1]);
    prefs.setString('nombre', "${splitted[2]} ${splitted[3]}");
    prefs.setString('telefono', splitted[4]);
    prefs.setString('email', splitted[5]);
    prefs.setString('usuario_tipo_id', splitted[6]);
    prefs.setString('pass', pass);
    // ignore: use_build_context_synchronously
    Navigator.of(context).push(
      PageRouteBuilder(
        barrierColor: Colors.black.withOpacity(0.6),
        opaque: false,
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10 * animation.value,
              sigmaY: 10 * animation.value,
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
