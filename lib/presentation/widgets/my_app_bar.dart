import 'package:tizara/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constants.dart';
import '../screens/home/home_screen.dart';

AppBar myAppBar(BuildContext context, String name, String idapp) {
  final Size size = MediaQuery.of(context).size;
  Future<bool> onWillPop1() async {
    return (await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              await flutterLocalNotificationsPlugin.cancelAll();
              SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.remove("id");
              await prefs.remove("nombre");
              await prefs.remove("telefono");
              await prefs.remove("email");
              await prefs.remove("usuario_tipo_id");
              await prefs.remove("pass");
              await prefs.remove("token");
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, 'login');
            },
            child: const Text('Si'),
          ),
        ],
      ),
    )) ??
    false;
  }
  
  return AppBar(
    elevation: 1,
    shadowColor: myColor,
    centerTitle: true,
    backgroundColor: Colors.white,
    title: Text(name, style: const TextStyle(color: myColor)),
    iconTheme: const IconThemeData(color: myColor),
    leading: Row(
      children: [
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer(); 
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
            //   (Route<dynamic> route) => false, // Remueve todas las páginas previas
            // );
          },
        ),
      ],
    ),
    leadingWidth: size.width * 0.28,
    actions: <Widget>[
      // IconButton(
      //   onPressed: () async{
      //   },
      //   icon: const Icon(Icons.notifications_rounded),
      //   color: myColor,
      // ),
      PopupMenuButton(
        color: Colors.white,
        icon: const Icon(Icons.more_vert_outlined, color: myColor),
        itemBuilder: (context) {
          return [
            PopupMenuItem<int>(
              value: 1,
              child: Row(
                children: [
                  const Icon(Icons.login),
                  SizedBox(width: size.width * 0.03),
                  const Text("Cerrar sesión", style: TextStyle(color: myColor)),
                ],
              ),
            ),
          ];
        },
        onSelected: (value) {
          if (value == 1) {
            onWillPop1();
          }else if (value == 2) {
            
          }
        },
      ),
    ],
  );
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
