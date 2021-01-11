import 'package:flutter/material.dart';

class ErrorDialogWidget extends StatelessWidget {
  final String errorMessage;

  ErrorDialogWidget(this.errorMessage);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AlertDialog(
        title: Text('Error'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('The following error occurred:'),
              Text(errorMessage),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Dismiss'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
