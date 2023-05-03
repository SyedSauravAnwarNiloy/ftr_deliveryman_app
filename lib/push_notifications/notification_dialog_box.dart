import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project_files/assistants/assistant_methods.dart';
import 'package:project_files/global/global.dart';
import 'package:project_files/mainScreens/new_trip_screen.dart';

import '../models/user_courier_request_information.dart';

class NotificationDialogBox extends StatefulWidget {
  UserCourierRequestInformation? userCourierRequestDetails;
  NotificationDialogBox({this.userCourierRequestDetails});

  @override
  State<NotificationDialogBox> createState() => _NotificationDialogBoxState();
}



class _NotificationDialogBoxState extends State<NotificationDialogBox> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      elevation: 2,
      child: Container(
        margin: EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[850],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const SizedBox(height: 16,),
            
            const Text(
              "New courier request",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 14,),

            const Divider(
              height: 3,
              thickness: 3,
            ),

            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),

                  const SizedBox(width: 12,),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userCourierRequestDetails!.userName!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,

                        ),
                      ),

                      const SizedBox(height: 6,),

                      Text(
                        "+88${widget.userCourierRequestDetails!.userPhone!}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const Divider(
              height: 3,
              thickness: 3,
            ),

            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Image.asset(
                    "images/parcel.png",
                    width: 40,
                    height: 40,
                  ),

                  const SizedBox(width: 18,),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userCourierRequestDetails!.parcelType!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,

                        ),
                      ),

                      const SizedBox(height: 10,),

                      Row(
                        children: [
                          Text(
                            "${widget.userCourierRequestDetails!.parcelMass!} kg",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 35,),
                          Text(
                            "${widget.userCourierRequestDetails!.parcelVolume!} cm^3",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),

            const Divider(
              height: 3,
              thickness: 3,
            ),

            //Addresses - Origin and Destination
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  //Origin location with icon
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

                  //Destination location with icon
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
                ],
              ),
            ),

            const Divider(
              height: 3,
              thickness: 3,
            ),

            //Buttons - Accept and Cancel
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: ()
                      {
                        //cancel the courier request

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                      ),
                      child: Text(
                        "Cancel".toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      )
                  ),

                  const SizedBox(width: 35,),

                  ElevatedButton(
                      onPressed: ()
                      {
                        //Accept the courier request

                        acceptCourierRequest(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                      ),
                      child: Text(
                        "Accept".toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      )
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  acceptCourierRequest(BuildContext context)
  {
    String getCourierRequestId="";
    FirebaseDatabase.instance.ref()
        .child("deliverymen")
        .child(currentFirebaseUser!.uid)
        .child("newCourierStatus")
        .once().then((snap)
    {
      if(snap.snapshot.value != null)
        {
          getCourierRequestId = snap.snapshot.value.toString();
        }
      else
        {
          Fluttertoast.showToast(msg: "This Courier request does not exist.");
        }

      if(getCourierRequestId == widget.userCourierRequestDetails!.courierRequestId)
        {
          FirebaseDatabase.instance.ref()
              .child("deliverymen")
              .child(currentFirebaseUser!.uid)
              .child("newCourierStatus")
              .set("accepted");

          AssistantMethods.pauseLiveLocationUpdates();

          // Trip started now - send deliveryman to newTripScreen
          Navigator.push(context, MaterialPageRoute(builder: (c)=>NewTripScreen(
              userCourierRequestDetails: widget.userCourierRequestDetails,
          )));
        }
      else
        {
          Fluttertoast.showToast(msg: "This Courier request does not exist.");
        }
    });
  }
}
