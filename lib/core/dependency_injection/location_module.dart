// import 'package:location/location.dart';

// abstract class LocationModule {
//   Future<Location> get location async {
//     final Location location = Location();
//     final hasPermissions = await location.hasPermission();
//     if (hasPermissions != PermissionStatus.granted) {
//       await location.requestPermission();
//     }
//     await location.changeSettings(distanceFilter: 5);
//     return location;
//   }
// }
