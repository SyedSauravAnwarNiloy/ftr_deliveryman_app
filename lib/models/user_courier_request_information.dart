import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserCourierRequestInformation
{
  LatLng? originLatLng;
  LatLng? destinationLatLng;
  String? originAddress;
  String? destinationAddress;
  String? courierRequestId;
  String? userName;
  String? userPhone;
  String? parcelMass;
  String? parcelType;
  String? parcelVolume;

  UserCourierRequestInformation({
    this.originLatLng,
    this.destinationLatLng,
    this.originAddress,
    this.destinationAddress,
    this.courierRequestId,
    this.userName,
    this.userPhone,
    this.parcelMass,
    this.parcelType,
    this.parcelVolume,
  });

}