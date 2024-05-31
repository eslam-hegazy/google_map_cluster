import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rahaly/map_style.dart';
import 'package:rahaly/place_model.dart';
import 'package:rahaly/widget_marker.dart';
import 'package:rahaly/widget_to_marker/src/widget_to_bitmap_descriptor.dart';
import 'google_maps_cluster/src/cluster.dart';
import 'google_maps_cluster/src/cluster_manager.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cluster Manager Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  late ClusterManager _manager;

  Completer<GoogleMapController> _controller = Completer();

  Set<Marker> markers = Set();

  final CameraPosition _parisCameraPosition =
      CameraPosition(target: LatLng(29.256298, 31.540813), zoom: 2);

  List<Place> items = [
    Place(name: '1', latLng: LatLng(28.811026, 30.3896952)),
    Place(name: '2', latLng: LatLng(30.730265, 30.552359)),
    Place(name: '3', latLng: LatLng(29.466142, 31.661978)),
    Place(name: '4', latLng: LatLng(28.775119, 30.903922)),
    Place(name: '5', latLng: LatLng(28.640217, 32.288199)),
    Place(name: '6', latLng: LatLng(30.531745, 31.387320)),
    // dsfd
    Place(name: '6', latLng: LatLng(24.095205, 27.552776)),
    Place(name: '6', latLng: LatLng(24.395723, 30.167522)),
    Place(name: '6', latLng: LatLng(25.818278, 29.629192)),
    Place(name: '6', latLng: LatLng(23.993200, 31.267383)),
    Place(name: '6', latLng: LatLng(24.430604, 27.439367)),
    Place(name: '6', latLng: LatLng(23.514333, 32.453283)),
    Place(name: '6', latLng: LatLng(24.040990, 33.769981)),
    Place(name: '6', latLng: LatLng(23.709088, 25.795462)),
    Place(name: '6', latLng: LatLng(22.848123, 30.959001)),
    Place(name: '6', latLng: LatLng(23.490463, 32.816512)),

  ];

  @override
  void initState() {
    _manager = _initClusterManager();
    super.initState();
  }

  ClusterManager _initClusterManager() {
    return ClusterManager<Place>(
      items,
      _updateMarkers,
      markerBuilder: _markerBuilder,
    );
  }

  void _updateMarkers(Set<Marker> markers) {
    print('Updated ${markers.length} markers');
    setState(() {
      this.markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _parisCameraPosition,
        markers: markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          // controller.setMapStyle(lightMapTheme);
          controller.setMapStyle(darkMapTheme);
          _manager.setMapId(controller.mapId);
        },
        onCameraMove: _manager.onCameraMove,
        onCameraIdle: _manager.updateMap,
      ),
    );
  }

  Future<Marker> Function(Cluster<Place>) get _markerBuilder =>
      (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () {
            // TODO action here
          },
          icon: cluster.isMultiple
              ? BitmapDescriptor.defaultMarker
              : await MarkerWidget(place: cluster.items.first)
                  .toBitmapDescriptor(
                      logicalSize: Size(20, 20),
                      imageSize: Size(150, 150)),
        );
      };
}
