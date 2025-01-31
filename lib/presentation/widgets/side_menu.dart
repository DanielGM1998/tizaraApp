import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tizara/constants/constants.dart';
import '../screens/home/home_screen.dart';
import '../screens/proveedor/proveedor_screen.dart';

class SideMenu extends StatefulWidget {
  final String userapp;
  final String? tipoapp;
  final String idapp;
  const SideMenu({
    Key? key,
    required this.userapp,
    this.tipoapp,
    required this.idapp,
  }) : super(key: key);

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  int? navDrawerIndex;
  late Future<String> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = _checkVersion();
  }

  Future<String> _checkVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;

    return NavigationDrawer(
      backgroundColor: Colors.white,
      selectedIndex: navDrawerIndex,
      onDestinationSelected: (value) {
        setState(() {
          navDrawerIndex = value;
          switch (navDrawerIndex) {
            case 0:
              Navigator.of(context).pushReplacement(
                _buildPageRoute(const HomeScreen()),
              );
              break;
            case 1:
              Navigator.of(context).pushReplacement(
                _buildPageRoute(ProveedorScreen(idapp: widget.idapp)),
              );
              break;
            default:
              Navigator.of(context).pushReplacement(
                _buildPageRoute(const HomeScreen()),
              );
              break;
          }
        });
      },
      children: [
        FutureBuilder<String>(
          future: _versionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const DrawerHeader(
                decoration: BoxDecoration(color: Colors.white70),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return const DrawerHeader(
                decoration: BoxDecoration(color: Colors.white70),
                child: Center(child: Text("Error al cargar la versión")),
              );
            } else {
              return DrawerHeader(
                decoration: const BoxDecoration(color: Colors.white70),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        myLogo,
                        height: _size.height * 0.09,
                        width: _size.width * 0.5,
                      ),
                    ),
                    SizedBox(height: _size.width * 0.015),
                    Text(widget.userapp,
                        style: const TextStyle(
                            color:myColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(nameVersion + snapshot.data!,
                        style: const TextStyle(
                            color: myColor, fontSize: 16)),
                  ],
                ),
              );
            }
          },
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_filled, color: myColor),
          label: Text("Inicio", style: TextStyle(color: myColor)),
        ),
        const Divider(
          height: 1,
          thickness: 0.1,
          indent: 20,
          endIndent: 20,
          color: myColor,
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.people_sharp, color: myColor),
          label: Text("Proveedor", style: TextStyle(color: myColor)),
        ),
        const Divider(
          height: 1,
          thickness: 0.1,
          indent: 20,
          endIndent: 20,
          color: myColor,
        ),
      ],
    );
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
}
