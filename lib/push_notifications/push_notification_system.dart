import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_files/global/global.dart';
import 'package:project_files/models/user_courier_request_information.dart';
import 'package:project_files/push_notifications/notification_dialog_box.dart';

class PushNotificationSystem
{
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializeCloudMessaging(BuildContext context) async
  {
    // 1. Terminated
    // When the app is completely closed and directly opened from the push notifications
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? remoteMessage)
    {
      if(remoteMessage != null)
         {
           // display the courier request information - user information who has requested courier
           readUserCourierRequestInformation(remoteMessage.data["courierRequestId"], context);
         }
    });

    // 2. Foreground
    // When the app is open and it receives a push notification
    FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage)
    {
      // display the courier request information - user information who has requested courier
      readUserCourierRequestInformation(remoteMessage!.data["courierRequestId"], context);
    });

    // 3. Background
    // When the app is in the background and opened directly from the push notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage)
    {
      // display the courier request information - user information who has requested courier
      readUserCourierRequestInformation(remoteMessage!.data["courierRequestId"], context);
    });
  }

  readUserCourierRequestInformation(String courierRequestId, BuildContext context)
  {
    FirebaseDatabase.instance.ref()
        .child("all courier requests")
        .child(courierRequestId)
        .once().then((snapData)
    {
      if(snapData.snapshot.value != null)
        {
          double originLat = double.parse((snapData.snapshot.value! as Map)["origin"]["latitude"]);
          double originLng = double.parse((snapData.snapshot.value! as Map)["origin"]["longitude"]);
          String originAddress = (snapData.snapshot.value! as Map)["originAddress"];

          double destinationLat = double.parse((snapData.snapshot.value! as Map)["destination"]["latitude"]);
          double destinationLng = double.parse((snapData.snapshot.value! as Map)["destination"]["longitude"]);
          String destinationAddress = (snapData.snapshot.value! as Map)["destinationAddress"];

          String userName = (snapData.snapshot.value! as Map)["userName"];
          String userPhone = (snapData.snapshot.value! as Map)["userPhone"];

          String parcelType = (snapData.snapshot.value! as Map)["parcelInformation"]["parcel_type"];
          String parcelMass = (snapData.snapshot.value! as Map)["parcelInformation"]["parcel_mass"];
          String parcelVolume = (snapData.snapshot.value! as Map)["parcelInformation"]["parcel_volume"];

          String? courierRequestId = snapData.snapshot.key;

          UserCourierRequestInformation userCourierRequestDetails = UserCourierRequestInformation();
          userCourierRequestDetails.originLatLng = LatLng(originLat, originLng);
          userCourierRequestDetails.originAddress = originAddress;

          userCourierRequestDetails.destinationLatLng = LatLng(destinationLat, destinationLng);
          userCourierRequestDetails.destinationAddress = destinationAddress;

          userCourierRequestDetails.userName = userName;
          userCourierRequestDetails.userPhone = userPhone;

          userCourierRequestDetails.parcelType = parcelType;
          userCourierRequestDetails.parcelMass = parcelMass;
          userCourierRequestDetails.parcelVolume = parcelVolume;

          userCourierRequestDetails.courierRequestId = courierRequestId;

          showDialog(
              context: context,
              builder: (BuildContext context) => NotificationDialogBox(
                userCourierRequestDetails: userCourierRequestDetails,
              ),
          );
        }
      else
        {
          Fluttertoast.showToast(msg: "This ride request does not exist.");
        }
    });
  }

  Future generateAndGetToken() async
  {
    String? registrationToken = await messaging.getToken();
    FirebaseDatabase.instance.ref()
        .child("deliverymen")
        .child(currentFirebaseUser!.uid)
        .child("token")
        .set(registrationToken);

    messaging.subscribeToTopic("allDeliverymen");
    messaging.subscribeToTopic("allUsers");
  }
}