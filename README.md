# Google Map Cluster manager

Google Maps Cluster Manager is a utility that helps manage and display a large number of markers on a Google Map efficiently. When there are many markers in close proximity, displaying them all individually can lead to clutter and poor performance. Cluster Manager groups these markers into clusters at various zoom levels to improve performance and provide a cleaner visual representation of the data.

## How It Works

- Zoom Levels:- *At low zoom levels, markers close to each other are grouped into clusters. As you zoom in, clusters break apart into individual markers or smaller clusters.*
- Cluster Icons:- *Each cluster is represented by an icon indicating the number of markers within the cluster.*
- Performance Optimization:- *Improves map performance by reducing the number of markers displayed at one time.*

```yaml
    dependencies:
      flutter:
        sdk: flutter
      google_maps_flutter: ^2.6.1
      step_progress_indicator: ^1.0.2
```

**Install the dependencies:**

```yaml
    flutter pub get
```
## Usage

```dart
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
    Place(name: '7', latLng: LatLng(24.095205, 27.552776)),
    Place(name: '8', latLng: LatLng(24.395723, 30.167522)),
    Place(name: '9', latLng: LatLng(25.818278, 29.629192)),
    Place(name: '10', latLng: LatLng(23.993200, 31.267383)),
    Place(name: '11', latLng: LatLng(24.430604, 27.439367)),
    Place(name: '12', latLng: LatLng(23.514333, 32.453283)),
    Place(name: '13', latLng: LatLng(24.040990, 33.769981)),
    Place(name: '14', latLng: LatLng(23.709088, 25.795462)),
    Place(name: '15', latLng: LatLng(22.848123, 30.959001)),
    Place(name: '16', latLng: LatLng(23.490463, 32.816512)),

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

```
### Place
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'google_maps_cluster/src/cluster_item.dart';

class Place with ClusterItem {
  final String name;
  final LatLng latLng;

  Place({required this.name, required this.latLng});

  @override
  LatLng get location => latLng;
}
```
### Widget Marker
```dart
import 'package:flutter/material.dart';
import 'package:rahaly/place_model.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class MarkerWidget extends StatelessWidget {
  const MarkerWidget({
    super.key,
    required this.place,
  });
  final Place place;

  @override
  Widget build(BuildContext context) {
    return CircularStepProgressIndicator(
      totalSteps: 100,
      currentStep: 100,
      stepSize: 1,
      selectedColor: Colors.blue,
      unselectedColor: Colors.transparent,
      padding: 0,
      width: 50,
      height: 50,
      unselectedStepSize: 3,
      selectedStepSize: 3,
      roundedCap: (_, __) => true,
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Text(
          place.name,
          style: const TextStyle(fontSize: 6),
        ),
      ),
    );
  }
}

```
### Light Map Theme
```dart
const String lightMapTheme = '''
 [
  {
    "elementType": "geometry",
    "stylers": [
      {"color": "#f5f5f5"}
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#616161"}
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {"color": "#f5f5f5"}
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#bdbdbd"}
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {"color": "#eeeeee"}
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#757575"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {"color": "#e5e5e5"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#9e9e9e"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {"color": "#ffffff"}
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#757575"}
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {"color": "#dadada"}
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#616161"}
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#9e9e9e"}
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {"color": "#e5e5e5"}
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {"color": "#eeeeee"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {"color": "#c9c9c9"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#9e9e9e"}
    ]
  }
]
''';
```
### Dark light theme
```dart
const String darkMapTheme = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {"color": "#212121"}
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#757575"}
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {"color": "#212121"}
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [
      {"color": "#757575"}
    ]
  },
  {
    "featureType": "administrative.country",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#9e9e9e"}
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [
      {"visibility": "off"}
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#bdbdbd"}
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#757575"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {"color": "#181818"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#616161"}
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.stroke",
    "stylers": [
      {"color": "#1b1b1b"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      {"color": "#2c2c2c"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#8a8a8a"}
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      {"color": "#373737"}
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {"color": "#3c3c3c"}
    ]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [
      {"color": "#4e4e4e"}
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#616161"}
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#757575"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {"color": "#000000"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#3d3d3d"}
    ]
  }
]
''';
```
## Preview

[![Watch the video](https://firebasestorage.googleapis.com/v0/b/androidkotlin-bf4ea.appspot.com/o/dark_image.jpg?alt=media&token=3c527bbe-6c99-4771-a1e7-d6a46fc2038e)](https://youtube.com/shorts/9ReySljaJjA?feature=share)
[![Watch the video](https://firebasestorage.googleapis.com/v0/b/androidkotlin-bf4ea.appspot.com/o/light_image.jpg?alt=media&token=2c5ce97b-99b1-4ffe-aed4-33921ced84d9)](https://youtube.com/shorts/JbQsPPReJKI?feature=share)
