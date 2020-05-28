import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:measurements/measurements.dart';
import 'package:measurements_example/colors.dart';

class MetadataRepository {}

void main() {
  GetIt.I.registerSingleton(MetadataRepository());

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static String originalTitle = 'Measurement app';
  String title = originalTitle;
  bool measure = true;
  bool showDistanceOnLine = true;

  Function(List<double>) distanceCallback;

  @override
  void initState() {
    super.initState();

    distanceCallback = (List<double> distance) {
      setState(() {
        this.title = "Measurement#: ${distance.length}";
      });
    };
  }

  Color getButtonColor(bool selected) {
    if (selected) {
      return selectedColor;
    } else {
      return unselectedColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff1280b3),
          title: Row(
            children: <Widget>[
              IconButton(onPressed: () {
                setState(() {
                  measure = !measure;
                  title = originalTitle;
                });
              },
                  icon: Icon(Icons.straighten, color: getButtonColor(measure))
              ),
              IconButton(onPressed: () {
                setState(() {
                  showDistanceOnLine = !showDistanceOnLine;
                });
              },
                  icon: Icon(Icons.vertical_align_bottom, color: getButtonColor(showDistanceOnLine))
              ),
              Text(title),
            ],
          ),
        ),
        body: Center(
          child: Measurement(
            child: Image.asset("assets/images/example_portrait.png",),
            measurementInformation: MeasurementInformation(
              scale: 1 / 2.0,
              documentWidthInLengthUnits: Millimeter(210),
              unitOfMeasurement: UnitOfMeasurement.INCH,
            ),
            distanceCallback: distanceCallback,
            showDistanceOnLine: showDistanceOnLine,
            distanceStyle: DistanceStyle(numDecimalPlaces: 4, showTolerance: true),
            measure: measure,
            pointStyle: PointStyle(lineType: DashedLine()),
          ),
        ),
      ),
    );
  }
}
