import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_files/authentication/login_screen.dart';
import 'package:project_files/global/global.dart';
import 'package:project_files/mainScreens/main_screen.dart';

import '../assistants/assistant_methods.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {

  startTimer()
  {
    fAuth.currentUser != null ? AssistantMethods.readCurrentOnlineUserInfo() : null;

    Timer(const Duration(seconds: 3), () async
    {
      if (await fAuth.currentUser != null)
        {
          currentFirebaseUser = fAuth.currentUser;
          if(!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (c)=> MainScreen()));
        }
      else
        {
          if(!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (c)=> const LoginScreen()));
        }

    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    startTimer();
  }
  @override
  Widget build(BuildContext context) {

    return Material(
      child: Container(
        color: Colors.grey[850],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Padding(
                padding: const EdgeInsets.all(70.0),
                child: Image.asset("images/Logo.png"),
              ),

              const SizedBox(height: 10,),

              const Text(
                "Deliveryman App",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                )
              )
            ]
          )
        ),
      ),
    );
  }
}
