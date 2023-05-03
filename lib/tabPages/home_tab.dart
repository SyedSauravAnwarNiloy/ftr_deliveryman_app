import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_files/push_notifications/push_notification_system.dart';

import '../assistants/assistant_methods.dart';
import '../assistants/black_theme_google_map.dart';
import '../global/global.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({Key? key}) : super(key: key);

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}



class _HomeTabPageState extends State<HomeTabPage> {

  GoogleMapController? newGoogleMapController;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );


  var geoLocator = Geolocator();
  LocationPermission? _locationPermission;

  String statusText = "Now Offline";
  Color statusColor = Colors.grey;
  bool isDeliverymanActive = false;


  checkIfLocationPermissionAllowed() async
  {
    _locationPermission = await Geolocator.requestPermission();

    if(_locationPermission == LocationPermission.denied)
    {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  locateDriverPosition() async
  {
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    deliverymanCurrentPosition = cPosition;

    LatLng latLngPosition = LatLng(deliverymanCurrentPosition!.latitude, deliverymanCurrentPosition!.longitude);

    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 14);

    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoordinates(deliverymanCurrentPosition!, context);
    //print("This is your address = " + humanReadableAddress);
  }

  readCurrentDeliverymanInformation() async
  {
    currentFirebaseUser = fAuth.currentUser;

    FirebaseDatabase.instance.ref()
    .child("deliverymen")
    .child(currentFirebaseUser!.uid)
    .once()
    .then((snap)
    {
      if(snap.snapshot.value != null)
        {
          onlineDeliverymanData.id = (snap.snapshot.value as Map)["id"];
          onlineDeliverymanData.name = (snap.snapshot.value as Map)["name"];
          onlineDeliverymanData.phone = (snap.snapshot.value as Map)["phone"];
          onlineDeliverymanData.email = (snap.snapshot.value as Map)["email"];
          onlineDeliverymanData.car_model = (snap.snapshot.value as Map)["car_details"]["car_model"];
          onlineDeliverymanData.car_color = (snap.snapshot.value as Map)["car_details"]["car_color"];
          onlineDeliverymanData.car_number = (snap.snapshot.value as Map)["car_details"]["car_number"];
        }
    });

    PushNotificationSystem pushNotificationSystem = PushNotificationSystem();
    pushNotificationSystem.initializeCloudMessaging(context);
    pushNotificationSystem.generateAndGetToken();
  }

  @override
  void initState() {
    super.initState();

    checkIfLocationPermissionAllowed();
    readCurrentDeliverymanInformation();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller)
            {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              //black theme Google Map
              blackThemeGoogleMap(newGoogleMapController);

              locateDriverPosition();
            },
          ),

          // ui for online offline
          statusText != "Now Online"
              ? Container(
                  height: MediaQuery.of(context).size.height,
                  width: double.infinity,
                  color: Colors.black87,
                )
              : Container(),

          // button for online offline
          Positioned(
            top: statusText != "Now Online"
              ? MediaQuery.of(context).size.height * 0.5
              : 25,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: ()
                  {
                    if(isDeliverymanActive != true) //offline
                    {
                      driverIsOnlineNow();
                      updateDeliverymenLocationAtRealTime();

                      setState(() {
                        statusText = "Now Online";
                        isDeliverymanActive = true;
                      });

                      //display toast
                      Fluttertoast.showToast(msg: "You are Online now");
                    }
                    else
                      {
                        driverIsOfflineNow();
                        setState(() {
                          statusText = "Now Offline";
                          isDeliverymanActive = false;
                        });

                        //display toast
                        Fluttertoast.showToast(msg: "You are Offline now");
                      }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    )
                  ),
                  child: statusText != "Now Online"
                    ? Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                    )
                    : const Icon(
                        Icons.phonelink_ring,
                        color: Colors.black,
                        size: 16,
                    ),
                ),
              ],
            ),
          ),
        ],
    );
  }

  driverIsOnlineNow() async
  {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    deliverymanCurrentPosition = pos;

    Geofire.initialize("activeDeliverymen");
    Geofire.setLocation(
        currentFirebaseUser!.uid,
        deliverymanCurrentPosition!.latitude,
        deliverymanCurrentPosition!.longitude
    );

    DatabaseReference ref = FirebaseDatabase.instance.ref()
        .child("deliverymen")
        .child(currentFirebaseUser!.uid)
        .child("newCourierStatus");

    ref.set("idle"); // searching for parcel request
    ref.onValue.listen((event) { });
  }

  updateDeliverymenLocationAtRealTime()
  {
    streamSubscriptionPosition = Geolocator.getPositionStream()
        .listen((Position position)
    {
      deliverymanCurrentPosition = position;

      if(isDeliverymanActive == true)
        {
          Geofire.setLocation(
              currentFirebaseUser!.uid,
              deliverymanCurrentPosition!.latitude,
              deliverymanCurrentPosition!.longitude
          );
        }

      LatLng latLng = LatLng(
          deliverymanCurrentPosition!.latitude,
          deliverymanCurrentPosition!.longitude
      );

      newGoogleMapController!.animateCamera(CameraUpdate.newLatLng(latLng));
    });
  }

  driverIsOfflineNow()
  {
    Geofire.removeLocation(currentFirebaseUser!.uid);

    DatabaseReference? ref = FirebaseDatabase.instance.ref()
        .child("deliverymen")
        .child(currentFirebaseUser!.uid)
        .child("newCourierStatus");
    ref.onDisconnect();
    ref.remove();
    ref = null;

    Future.delayed(const Duration(milliseconds: 2000), ()
    {
      //SystemChannels.platform.invokeMethod("SystemNavigator.pop");
      SystemNavigator.pop();

    });
  }
}
