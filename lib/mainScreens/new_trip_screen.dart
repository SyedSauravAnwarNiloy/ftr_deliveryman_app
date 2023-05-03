import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:project_files/global/global.dart';
import 'package:project_files/models/user_courier_request_information.dart';

import '../assistants/assistant_methods.dart';
import '../assistants/black_theme_google_map.dart';
import '../widgets/progress_dialog.dart';

class NewTripScreen extends StatefulWidget {
  UserCourierRequestInformation? userCourierRequestDetails;

  NewTripScreen({this.userCourierRequestDetails,});

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}



class _NewTripScreenState extends State<NewTripScreen> {

  GoogleMapController? newTripGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  String? buttonTitle = "Arrived";
  Color? buttonColor = Colors.blueGrey[600];

  Set<Marker> setOfMarkers = Set<Marker>();
  Set<Circle> setOfCircles = Set<Circle>();
  Set<Polyline> setOfPolyline = Set<Polyline>();
  List<LatLng> polyLinePositionCoordinates = [];
  PolylinePoints polyLinePoints = PolylinePoints();

  double mapPadding = 0;
  BitmapDescriptor? iconAnimatedMarker;
  var geoLocator = Geolocator();
  Position? onlineDeliverymanCurrentPosition;

  String courierRequestStatus = "accepted";

  String durationFromOriginToDestination = "";

  bool isRequestDirectionDetails = false;

  Future<void> drawPolyLineFromOriginToDestination(LatLng originLatLng, LatLng destinationLatLng) async
  {
    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(message: "Please wait...",),
    );

    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);

    if (!mounted) return;
    Navigator.pop(context);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList = pPoints.decodePolyline(directionDetailsInfo!.e_points!);

    polyLinePositionCoordinates.clear();

    if(decodedPolyLinePointsResultList.isNotEmpty)
    {
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng) {
        polyLinePositionCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    setOfPolyline.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.white,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: polyLinePositionCoordinates,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      setOfPolyline.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude)
    {
      boundsLatLng = LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    }
    else if(originLatLng.longitude > destinationLatLng.longitude)
    {
      boundsLatLng = LatLngBounds(
          southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude)
      );
    }
    else if(originLatLng.latitude > destinationLatLng.latitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    }
    else
    {
      boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newTripGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: const MarkerId("originID"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );

    setState(() {
      setOfMarkers.add(originMarker);
      setOfMarkers.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId("originID"),
      fillColor: Colors.white,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.red,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Colors.white,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.blue,
      center: destinationLatLng,
    );

    setState(() {
      setOfCircles.add(originCircle);
      setOfCircles.add(destinationCircle);
    });
  }

  @override
  void initState() {
    super.initState();

    saveAssignedDeliverymanDetailsToUserCourierRequest();
  }

  createDeliverymanIconMarker()
  {
    if(iconAnimatedMarker == null)
    {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/DeliverymanMarker.png").then((value)
      {
        iconAnimatedMarker = value;
      });
    }
  }

  getDeliverymenLocationUpdatesAtRealTime()
  {
    LatLng oldLatLng = LatLng(0, 0);
    streamSubscriptionDeliverymanLivePosition = Geolocator.getPositionStream()
        .listen((Position position)
    {
      deliverymanCurrentPosition = position;
      onlineDeliverymanCurrentPosition = position;

      LatLng latLngLiveDeliverymanPosition = LatLng(
          onlineDeliverymanCurrentPosition!.latitude,
          onlineDeliverymanCurrentPosition!.longitude
      );

      Marker animatingMarker = Marker(
        markerId: const MarkerId("AnimatedMarker"),
        position: latLngLiveDeliverymanPosition,
        icon: iconAnimatedMarker!,
        infoWindow: const InfoWindow(title: "This is your position"),
      );

      setState(() {
        CameraPosition cameraPosition = CameraPosition(target: latLngLiveDeliverymanPosition, zoom: 16);
        newTripGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        setOfMarkers.removeWhere((element) => element.markerId.value == "AnimatedMarker");
        setOfMarkers.add(animatingMarker);
      });

      oldLatLng = latLngLiveDeliverymanPosition;
      updateDurationTimeAtRealTime();

      // updating deliveryman location in real time in database
      Map deliverymanLatLngDataMap =
          {
            "latitude": onlineDeliverymanCurrentPosition!.latitude.toString(),
            "longitude": onlineDeliverymanCurrentPosition!.longitude.toString(),
          };

      FirebaseDatabase.instance.ref().child("all courier requests")
          .child(widget.userCourierRequestDetails!.courierRequestId!)
          .child("deliverymanLocation")
          .set(deliverymanLatLngDataMap);
    });
  }

  updateDurationTimeAtRealTime() async
  {
    if(isRequestDirectionDetails == false)
      {
        isRequestDirectionDetails == true;

        if(onlineDeliverymanCurrentPosition == null)
          {
            return;
          }

        var originLatLng = LatLng(
          onlineDeliverymanCurrentPosition!.latitude,
          onlineDeliverymanCurrentPosition!.longitude,
        ); // deliveryman current position

        var destinationLatLng;

        if(courierRequestStatus == "accepted")
        {
          destinationLatLng = widget.userCourierRequestDetails!.originLatLng; //user pickup location
        }
        else
        {
          destinationLatLng = widget.userCourierRequestDetails!.destinationLatLng; //user dropoff location
        }

        var directionInformation = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);

        if(directionInformation != null)
        {
          setState(() {
            durationFromOriginToDestination = directionInformation.duration_text!;
          });
        }

        isRequestDirectionDetails = false;
      }
  }

  @override
  Widget build(BuildContext context) {
    createDeliverymanIconMarker();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            markers: setOfMarkers,
            circles: setOfCircles,
            polylines: setOfPolyline,
            onMapCreated: (GoogleMapController controller)
            {
              _controllerGoogleMap.complete(controller);
              newTripGoogleMapController = controller;

              setState(() {
                mapPadding = 350;
              });

              //black theme Google Map
              blackThemeGoogleMap(newTripGoogleMapController);

              var deliverymanCurrentLatLng = LatLng(
                  deliverymanCurrentPosition!.latitude,
                  deliverymanCurrentPosition!.longitude
              );

              var courierPickUpLatLng = widget.userCourierRequestDetails!.originLatLng;
              
              drawPolyLineFromOriginToDestination(deliverymanCurrentLatLng, courierPickUpLatLng!);

              getDeliverymenLocationUpdatesAtRealTime();
            },
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white38,
                    blurRadius: 18,
                    spreadRadius: 0.5,
                    offset: Offset(0.6, 0.6),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25,vertical: 20),
                child: Column(
                  children: [

                    //duration
                    Text(
                      durationFromOriginToDestination,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),

                    const SizedBox(height: 18,),

                    const Divider(
                      thickness: 2,
                      height: 2,
                      color: Colors.grey,
                    ),

                    const SizedBox(height: 8,),

                    //user name - Icon
                    Row(
                      children: [
                        Text(
                          widget.userCourierRequestDetails!.userName!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.phone_android,
                            color: Colors.white,
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 18,),

                    //courier pickup location - Icon
                    Row(
                      children: [
                        Image.asset(
                          "images/origin_logo.png",
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(width: 16,),
                        Expanded(
                          child: Container(
                            child: Text(
                              widget.userCourierRequestDetails!.originAddress!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 20,),

                    //courier dropoff location - Icon
                    Row(
                      children: [
                        Image.asset(
                          "images/destination_logo.png",
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(width: 16,),
                        Expanded(
                          child: Container(
                            child: Text(
                              widget.userCourierRequestDetails!.destinationAddress!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 24,),

                    const Divider(
                      thickness: 2,
                      height: 2,
                      color: Colors.grey,
                    ),

                    const SizedBox(height: 20,),

                    ElevatedButton.icon(
                        onPressed: () async
                        {
                          if(courierRequestStatus == "accepted")
                            {
                              courierRequestStatus = "arrived";

                              FirebaseDatabase.instance.ref()
                                  .child("all courier requests")
                                  .child(widget.userCourierRequestDetails!.courierRequestId!)
                                  .child("status")
                                  .set(courierRequestStatus);

                              setState(() {
                                buttonTitle = "Start Trip";
                                buttonColor = Colors.green[800];
                              });

                              showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext c)=> ProgressDialog(
                                    message: "Loading...",
                                  ),
                              );

                              await drawPolyLineFromOriginToDestination(
                                  widget.userCourierRequestDetails!.originLatLng!,
                                  widget.userCourierRequestDetails!.destinationLatLng!
                              );

                              if(!mounted) return;
                              Navigator.pop(context);
                            }
                          //deliveryman has picked up the parcel - Start trip now
                          else if(courierRequestStatus == "arrived")
                          {
                            courierRequestStatus = "onTrip";

                            FirebaseDatabase.instance.ref()
                                .child("all courier requests")
                                .child(widget.userCourierRequestDetails!.courierRequestId!)
                                .child("status")
                                .set(courierRequestStatus);

                            setState(() {
                              buttonTitle = "End Trip";
                              buttonColor = Colors.red[800];
                            });
                          }
                          // deliveryman reached the drop-off location
                          else if(courierRequestStatus == "onTrip")
                            {
                              endTripNow();
                            }
                        },
                        icon: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 25,
                        ),
                        label: Text(
                          buttonTitle!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  endTripNow() async
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c)=> ProgressDialog(
        message: "Please wait...",
      ),
    );

    //get distance travelled
    var currentDeliverymanPositionLatLng = LatLng(
        onlineDeliverymanCurrentPosition!.latitude,
        onlineDeliverymanCurrentPosition!.longitude
    );

    var tripDirectionDetails = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        currentDeliverymanPositionLatLng,
        widget.userCourierRequestDetails!.originLatLng!
    );

    // fee amount for the trip
    double totalFeeAmount = 0;

    await FirebaseDatabase.instance.ref()
        .child("all courier requests")
        .child(widget.userCourierRequestDetails!.courierRequestId!)
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

    await FirebaseDatabase.instance.ref().child("all courier requests")
        .child(widget.userCourierRequestDetails!.courierRequestId!)
        .child("feeAmount")
        .set(totalFeeAmount.toString());

    FirebaseDatabase.instance.ref().child("all courier requests")
        .child(widget.userCourierRequestDetails!.courierRequestId!)
        .child("userFeeAmount").remove();

    FirebaseDatabase.instance.ref().child("all courier requests")
        .child(widget.userCourierRequestDetails!.courierRequestId!)
        .child("status")
        .set("ended");

    streamSubscriptionDeliverymanLivePosition!.cancel();

    Navigator.pop(context);
  }

  saveAssignedDeliverymanDetailsToUserCourierRequest()
  {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref()
        .child("all courier requests")
        .child(widget.userCourierRequestDetails!.courierRequestId!);

    Map deliverymanLocationDataMap =
    {
      "latitude": deliverymanCurrentPosition!.latitude.toString(),
      "longitude": deliverymanCurrentPosition!.longitude.toString(),
    };
    databaseReference.child("deliverymanLocation").set(deliverymanLocationDataMap);

    databaseReference.child("status").set("accepted");
    databaseReference.child("deliverymanId").set(onlineDeliverymanData.id);
    databaseReference.child("deliverymanName").set(onlineDeliverymanData.name);
    databaseReference.child("deliverymanPhone").set(onlineDeliverymanData.phone);
    databaseReference.child("car_details")
        .set(onlineDeliverymanData.car_color.toString()
        + onlineDeliverymanData.car_model.toString());

    saveCourierRequestIdToDeliverymanHistory();
  }

  saveCourierRequestIdToDeliverymanHistory()
  {
    DatabaseReference tripsHistoryRef = FirebaseDatabase.instance.ref()
        .child("deliverymen")
        .child(currentFirebaseUser!.uid)
        .child("tripsHistory");

    tripsHistoryRef.child(widget.userCourierRequestDetails!.courierRequestId!).set(true);
  }
}
