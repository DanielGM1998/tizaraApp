import 'package:flutter/material.dart';

const colorlist = <Color>[
  Color.fromRGBO(55, 171, 204, 1),
  Color.fromRGBO(0, 0, 77, 0.5),
  Colors.yellow,
  Colors.blue,
  Colors.teal,
  Colors.greenAccent,
  Colors.red,
  Colors.purple,
  Colors.deepPurple,
  Colors.orange,
  Colors.pink,
  Colors.pinkAccent
];

class AppTheme {
  final int selectedColor;

  AppTheme({this.selectedColor = 0})
      : assert(selectedColor >= 0, 'Selected color must be greater then 0'),
        assert(selectedColor < colorlist.length,
            'Selected color must be less or equals than ${colorlist.length}');

  ThemeData getTheme() => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorlist[selectedColor],
      appBarTheme: const AppBarTheme(centerTitle: false));
}