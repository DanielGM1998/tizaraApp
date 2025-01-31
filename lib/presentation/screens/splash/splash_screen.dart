import 'package:easy_splash_screen/easy_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:tizara/presentation/screens/home/home_screen.dart';
import 'package:tizara/presentation/screens/login/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/constants.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = 'splash';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? userIsLoggedIn;

  getLoggedInState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(prefs.getString('telefono') != null || prefs.getString('pass') != null){
      if (mounted) {
        setState(() {
          userIsLoggedIn = "inicio";
        });
      }
    }else{
      if (mounted) {
        setState(() {
          userIsLoggedIn = "login";
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return FutureBuilder(
      future: getLoggedInState(),
      builder: (context, snapshot) {
        if (userIsLoggedIn == "inicio") {
          return EasySplashScreen(
            gradientBackground: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(0.0, 1.3),
              colors: <Color>[
                myColorBackground1,
                myColorBackground2
              ],
              tileMode: TileMode.repeated,
            ),
            logo: Image.asset(myLogo, scale: 5),
            logoWidth: _size.height*0.2,
            showLoader: true,
            loaderColor: myColor,
            navigator: const HomeScreen(),
            durationInSeconds: 2,
          );
        } else if (userIsLoggedIn == "login") {
          return EasySplashScreen(
            gradientBackground: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment(0.0, 1.3),
              colors: <Color>[
                myColorBackground1,
                myColorBackground2
              ],
              tileMode: TileMode.repeated,
            ),
            logo: Image.asset(myLogo, scale: 5),
            logoWidth: _size.height*0.2,
            showLoader: true,
            loaderColor: myColor,
            navigator: const LoginScreen(),
            durationInSeconds: 2,
          );
        }
        return const SizedBox(height: 0, width: 0);
      }
    );
  }
}
