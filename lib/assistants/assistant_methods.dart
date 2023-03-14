import 'package:firebase_database/firebase_database.dart';

import '../global/global.dart';
import '../models/user_model.dart';


class AssistantMethods
{
  static void readCurrentOnlineUserInfo() async
  {
    currentFirebaseUser = fAuth.currentUser;

    DatabaseReference deliverymenRef = FirebaseDatabase.instance
        .ref()
        .child("deliverymen")
        .child(currentFirebaseUser!.uid);

    deliverymenRef.once().then((snap)
        {
          if(snap.snapshot.value != null)
            {
              userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
            }
        });
  }
}