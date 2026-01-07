import 'package:flutter/material.dart';

class ButtonBack extends StatelessWidget {

  const ButtonBack({Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          if(Navigator.canPop(context)){
            Navigator.of(context).pop();
          }else{
            Navigator.of(context, rootNavigator: true).pop(context);
          }
        },
        child: const Text('Back'),
    );
  }
}
