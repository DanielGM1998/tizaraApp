import 'package:flutter/material.dart';

/// Observador de rutas para detectar cambios de pantalla
final RouteObserver<ModalRoute<void>> appRouteObserver = RouteObserver<ModalRoute<void>>();

/// Variable global para guardar la pantalla actual
String? currentScreen;

class RouteAwareWidget extends StatefulWidget {
  final Widget child;
  final String screenName;

  const RouteAwareWidget({Key? key, required this.child, required this.screenName}) : super(key: key);

  @override
  RouteAwareWidgetState createState() => RouteAwareWidgetState();
}

class RouteAwareWidgetState extends State<RouteAwareWidget> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Suscribirse a la pantalla actual
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
    // log("📡 Suscrito a ${widget.screenName}");  // 🔹 Verificar suscripción
  }

  @override
  void dispose() {
    // Desuscribirse de la pantalla anterior
    appRouteObserver.unsubscribe(this);
    // log("❌ Desuscrito de ${widget.screenName}");  // 🔹 Verificar desuscripción
    super.dispose();
  }

  @override
  void didPush() {
    currentScreen = widget.screenName;
    // log("🟢 Entrando a: ${widget.screenName}");  // 🔹 Verificar que el valor cambie
  }

  @override
  void didPop() {
    // log("🔴 Saliendo de: ${widget.screenName}");  // 🔹 Verificar cuando salgas
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
