import 'dart:ui';

class Holder {
  final Offset start, end;
  double distance;

  Holder(this.start, this.end);

  @override
  String toString() {
    return super.toString() + " First Point: $start - Second Point: $end - Distance: $distance";
  }
}