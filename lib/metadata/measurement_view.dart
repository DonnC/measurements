import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:measurements/measurement/bloc/measure_bloc/measure_bloc.dart';
import 'package:measurements/measurement/bloc/points_bloc/points_bloc.dart';
import 'package:measurements/measurement/overlay/measure_area.dart';
import 'package:measurements/measurement/repository/measurement_repository.dart';

import '../util/logger.dart';
import 'bloc/metadata_bloc.dart';
import 'bloc/metadata_event.dart';
import 'bloc/metadata_state.dart';
import 'repository/metadata_repository.dart';

/*
 * TODO list:
 * - bug
 *  x slow movement of points - states are equal -> no update -> copy points and distances in measurement repository instead of using same object
 *  x metadata not loaded on start -> stateless measurementView and update arguments in build method
 *  - when distances are shown error during movement
 *  - onEvent and map is called multiple times for each point update
 *  - distance switch provided twice
 *  - switching between "showDistances" and "dontShowDistances" has no immediate effect
 *
 * - features
 *  - orientation change not supported
 *  - slow movement should move points with half distance
 *  - delete points
 *
 * - improve
 *  - state for painting with distances should contain holders
 *  - add/update tests
 *
 * - comments from Christof
 */


class Measurement extends StatelessWidget {
  final Widget child;
  final Size documentSize;
  final double scale;
  final double zoom;
  final bool measure;
  final bool showDistanceOnLine;
  final Color measurePaintColor;
  final Function(List<double>) distanceCallback;

  Measurement({
    Key key,
    @required this.child,
    this.documentSize = const Size(210, 297),
    this.scale = 1.0,
    this.zoom = 1.0,
    this.measure = false,
    this.showDistanceOnLine = false,
    this.distanceCallback,
    this.measurePaintColor
  }) {
    if (!GetIt.I.isRegistered<MetadataRepository>()) {
      GetIt.I.registerSingleton(MetadataRepository());
    }
    if (!GetIt.I.isRegistered<MeasurementRepository>()) {
      GetIt.I.registerSingleton(MeasurementRepository(GetIt.I<MetadataRepository>()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MetadataBloc(),
      child: MeasurementView(
        child,
        documentSize,
        scale,
        zoom,
        measure,
        showDistanceOnLine,
        distanceCallback,
        measurePaintColor,
      ),
    );
  }
}

class MeasurementView extends StatelessWidget {
  final Logger logger = Logger(LogDistricts.MEASUREMENT_VIEW);
  final GlobalKey childKey = GlobalKey();

  final Widget child;
  final Size documentSize;
  final double scale;
  final double zoom;
  final bool measure;
  final bool showDistanceOnLine;
  final Color measurePaintColor;
  final Function(List<double>) distanceCallback;

  MeasurementView(this.child,
      this.documentSize,
      this.scale,
      this.zoom,
      this.measure,
      this.showDistanceOnLine,
      this.distanceCallback,
      this.measurePaintColor);

  void _setBackgroundImageToBloc(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (childKey.currentContext != null) {
        // TODO is a heavy operation and is called after every movement of any point
        RenderRepaintBoundary boundary = childKey.currentContext.findRenderObject();

        if (boundary.size.width > 0.0 && boundary.size.height > 0.0) {
          BlocProvider.of<MetadataBloc>(context).add(MetadataBackgroundEvent(await boundary.toImage(pixelRatio: 4.0), boundary.size));
        }
      }
    });
  }

  void _setStartupArgumentsToBloc(BuildContext context) {
    BlocProvider.of<MetadataBloc>(context).add(
        MetadataStartedEvent(
            documentSize,
            distanceCallback,
            scale,
            zoom,
            measure,
            showDistanceOnLine,
            measurePaintColor)
    );
  }

  @override
  Widget build(BuildContext context) {
    _setBackgroundImageToBloc(context);
    _setStartupArgumentsToBloc(context);

    return BlocBuilder<MetadataBloc, MetadataState>(
        builder: (context, state) {
          return _overlay(state);
        }
    );
  }

  Widget _overlay(MetadataState state) {
    if (state.measure) {
      return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => MeasureBloc(),),
            BlocProvider(create: (context) => PointsBloc(),),
          ],
          child: MeasureArea(
            paintColor: measurePaintColor, // TODO can UI-only parameters be passed like this?
            child: RepaintBoundary(
              key: childKey,
              child: OrientationBuilder(builder: (BuildContext context, Orientation orientation) {
                BlocProvider.of<MetadataBloc>(context).add(MetadataOrientationEvent(orientation));
                return child;
              }),
            ),
          ));
    } else {
      return child;
    }
  }
}