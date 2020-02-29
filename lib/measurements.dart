import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:measurements/bloc/bloc_provider.dart';
import 'package:measurements/measure_area.dart';
import 'package:measurements/measurement_bloc.dart';
import 'package:measurements/pdf_view.dart';

typedef OnViewCreated(int id);

const double mmPerInch = 25.4;

class MeasurementView extends StatefulWidget {
  const MeasurementView({
    Key key,
    this.filePath,
    this.documentSize = const Size(210, 297),
    this.scale,
    this.measure,
    this.showOriginalSize,
    this.onViewCreated,
    this.outputStream,
  });

  final String filePath;
  final Size documentSize;
  final double scale;
  final bool measure;
  final bool showOriginalSize;
  final OnViewCreated onViewCreated;
  final StreamSink<double> outputStream;

  @override
  _MeasurementViewState createState() => _MeasurementViewState();
}

class _MeasurementViewState extends State<MeasurementView> {
  MethodChannel _channel = MethodChannel("measurements");

  MeasurementBloc _bloc;
  double zoomLevel = 1.0;
  double devicePixelRatio;
  double totalScaleFactor;
  double screenWidth;
  double screenHeight;
  double viewWidth;
  double paperToDeviceScaleFactor;

  bool showOriginalSizeLastState = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(_afterInit);

    _bloc = MeasurementBloc();

    _bloc.pixelDistanceStream.listen((double distance) {
      if (totalScaleFactor == null) {
        totalScaleFactor = getTotalScaleFactor();
        print("measure_flutter: totalScaleFactor - $totalScaleFactor");
      }

      print("measure_flutter: distance is $distance");
      double distanceInMM = distance * screenWidth / viewWidth / zoomLevel / widget.scale * (widget.documentSize.width / screenWidth);

      widget.outputStream?.add(distanceInMM);
    });

    _bloc.zoomLevelStream.listen((double zoomLevel) {
      print("measure_flutter: zoom level updated to: $zoomLevel");
      this.zoomLevel = zoomLevel;

      if (totalScaleFactor != null) {
        totalScaleFactor = getTotalScaleFactor();
        print("measure_flutter: totalScaleFactor - $totalScaleFactor");
      }
    });

    _bloc.logicalPdfViewWidthStream.listen((double width) {
      viewWidth = width;
      print("measure_flutter: view is $viewWidth pixels wide");
    });

    super.initState();
  }

  double getTotalScaleFactor() {
    print("measure_flutter: viewWidth - $viewWidth widgetScale - ${widget.scale} zoomLevel - $zoomLevel");
    return paperToDeviceScaleFactor / (widget.scale * zoomLevel);
  }

  void _afterInit(_) async {
    devicePixelRatio = MediaQuery
        .of(context)
        .devicePixelRatio;

    final Map size = await _channel.invokeMethod("getPhysicalScreenSize");

    screenWidth = size["width"] * mmPerInch;
    screenHeight = size["height"] * mmPerInch;

    paperToDeviceScaleFactor = widget.documentSize.width / screenWidth;

    print("measure_flutter: Physical Screen Size is: $screenWidth x $screenHeight");
  }

  void zoomViewToOriginalSize() {
    double pageToDeviceScale = widget.documentSize.width / screenWidth;
    double targetZoomLevel = pageToDeviceScale / widget.scale;

    print("measure_flutter: show original size with zoom level: $targetZoomLevel");
    _bloc.setZoomTo(targetZoomLevel);
  }

  void zoomIfWidgetParamChanged() {
    if (widget.showOriginalSize && widget.showOriginalSize != showOriginalSizeLastState) {
      showOriginalSizeLastState = widget.showOriginalSize;
      zoomViewToOriginalSize();
    } else if (!widget.showOriginalSize && widget.showOriginalSize != showOriginalSizeLastState) {
      showOriginalSizeLastState = widget.showOriginalSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    zoomIfWidgetParamChanged();

    return BlocProvider(
      bloc: _bloc,
      child: Stack(
        children: <Widget>[
          PdfView(filePath: widget.filePath, onViewCreated: widget.onViewCreated),
          if (widget.measure)
            MeasureArea()
          else
            Opacity(opacity: 0.0),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }
}
