import 'package:flutter/material.dart';
import '../global/global.dart';

import '../splashScreen/splash_screen.dart';

class ProfileTabPage extends StatefulWidget {
/*
  String? name;
  String? email;
*/
  ProfileTabPage(/*{this.name, this.email}*/);

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}



class _ProfileTabPageState extends State<ProfileTabPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
        children: [

          const SizedBox(height: 150,),

          Text(
            "Name: ", //${widget.name.toString()}",
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black,
              //fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15,),

          Text(
            "Email: ", //${widget.email.toString()}",
            style: const TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 35,),

          ElevatedButton(
            onPressed: ()
            {
              fAuth.signOut();
              Navigator.push(context, MaterialPageRoute(builder: (c)=> const MySplashScreen()));
            },
            child: const Text(
              "Logout",
            ),
          ),


        ]
    );
  }
}
