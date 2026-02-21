// import 'package:state_beacon/state_beacon.dart';

// final class SwipeRadiusController {
//   final double deadZone;
//   final double maxRadius;

//   SwipeRadiusController({this.maxRadius = 20, this.deadZone = 0.04});

//   late final progress = B.writable<double>(0.0);
//   late final radius = B.derived<double>(() {
//     final clamp = progress.value.clamp(0.0, 1.0);
//     final adjusted = clamp < deadZone ? clamp / deadZone : 1.0;

//     return maxRadius * (1 - adjusted);
//   });

//   void update(double value) {
//     progress.value = value;
//   }
// }
