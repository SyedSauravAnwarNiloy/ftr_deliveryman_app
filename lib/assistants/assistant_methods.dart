import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_files/assistants/request_assistant.dart';
import 'package:provider/provider.dart';

import '../global/global.dart';
import '../global/map_key.dart';
import '../infoHandler/app_info.dart';
import '../models/direction_details_info.dart';
import '../models/directions.dart';
import '../models/user_model.dart';


class AssistantMethods
{
  static Future<String> searchAddressForGeographicCoordinates(Position position, context) async
  {
    String apiUrl = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";
    String humanReadableAddress="";

    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);

    if(requestResponse != "Error occurred. No response.")
      {
        humanReadableAddress = requestResponse["results"][0]["formatted_address"];

        Directions userPickUpAddress = Directions();
        userPickUpAddress.locationLatitude = position.latitude;
        userPickUpAddress.locationLongitude = position.longitude;
        userPickUpAddress.locationName = humanReadableAddress;

        Provider.of<AppInfo>(context, listen: false).updatePickupLocationAddress(userPickUpAddress);

      }

    return humanReadableAddress;
  }

  static void readCurrentOnlineUserInfo() async
  {
    currentFirebaseUser = fAuth.currentUser;

    DatabaseReference usersRef = FirebaseDatabase.instance
      .ref()
      .child("users")
      .child(currentFirebaseUser!.uid);

    usersRef.once().then((snap)
    {
      if(snap.snapshot.value != null)
        {
          userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
        }
    });
  }

  static Future<DirectionDetailsInfo?> obtainOriginToDestinationDirectionDetails(LatLng originPosition, LatLng destinationPosition) async
  {
    String urlOriginToDestinationDirectionDetails = "https://maps.googleapis.com/maps/api/directions/json?origin=${originPosition.latitude},${originPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";

    var responseDirectionApi = await RequestAssistant.receiveRequest(urlOriginToDestinationDirectionDetails);

    if(responseDirectionApi == "Error occurred. No response.")
      {
        return null;
      }

    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
    directionDetailsInfo.e_points = responseDirectionApi["routes"][0]["overview_polyline"]["points"];

    directionDetailsInfo.distance_text = responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    directionDetailsInfo.distance_value = responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];

    directionDetailsInfo.duration_text = responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.duration_value = responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetailsInfo;
  }

  static pauseLiveLocationUpdates()
  {
    streamSubscriptionPosition!.pause();
    Geofire.removeLocation(currentFirebaseUser!.uid);
  }

  static resumeLiveLocationUpdates()
  {
    streamSubscriptionPosition!.resume();
    Geofire.setLocation(currentFirebaseUser!.uid,
        deliverymanCurrentPosition!.latitude,
        deliverymanCurrentPosition!.longitude);
  }
/*
  static double getTotalFee(DirectionDetailsInfo directionDetailsInfo, String courierRequestId)
  {
    double totalFeeAmount=0;

    FirebaseDatabase.instance.ref()
        .child("all courier requests")
        .child(courierRequestId)
        .once().then((snapData)
    {
      if(snapData.snapshot.value != null)
      {
        totalFeeAmount = double.parse((snapData.snapshot.value! as Map)["userFeeAmount"]);
      }
      else
      {
        Fluttertoast.showToast(msg: "Error getting parcelInfo");
      }
    });


    return double.parse(totalFeeAmount.toStringAsFixed(1));
  }*/
}