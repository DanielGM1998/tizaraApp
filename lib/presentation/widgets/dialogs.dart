import 'package:flutter/material.dart';
import 'package:tizara/constants/constants.dart';
class Dialogs {
  static Future<void> showLoadingDialog(BuildContext context, GlobalKey key) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async => false,
          child: SimpleDialog(
              key: key,              
              //backgroundColor: Colors.black54,
              children: const <Widget>[
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: myColor,
                      ),
                      // Text("Espere por favor...."/*,style: TextStyle(color: Colors.blueAccent),*/)
                  ]),
                )
              ]
          )
        );
      }
    );
  }

  static Future<void> showTextDialog(BuildContext context, GlobalKey key, String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async => false,
          child: SimpleDialog(
              key: key,
              title: Text(title),
              children: <Widget>[
                Center(
                  child: Column(children: [
                    Text(message)
                  ]),
                )
              ]
          )
        );
      }
    );
  }
}