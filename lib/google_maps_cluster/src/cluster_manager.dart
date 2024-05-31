// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart' hide Cluster;

import 'cluster.dart';
import 'cluster_item.dart';
import 'max_dist_clustering.dart';

enum ClusterAlgorithm { geoHash, maxDist }

class MaxDistParams {
  MaxDistParams(this.epsilon);

  final double epsilon;
}

class ClusterManager<T extends ClusterItem> {
  ClusterManager(
    this._items,
    this.updateMarkers, {
    Future<Marker> Function(Cluster<T>)? markerBuilder,
    this.levels = const [1, 4.25, 6.75, 8.25, 11.5, 14.5, 16.0, 16.5, 20.0],
    this.extraPercent = 0.5,
    this.maxItemsForMaxDistAlgo = 200,
    this.clusterAlgorithm = ClusterAlgorithm.geoHash,
    this.maxDistParams,
    this.stopClusteringZoom,
  })  : markerBuilder = markerBuilder ?? _basicMarkerBuilder,
        assert(
          levels.length <= precision,
          'Levels length should be less than or equal to precision',
        );

  /// Method to build markers
  final Future<Marker> Function(Cluster<T>) markerBuilder;

  // Num of Items to switch from MAX_DIST algo to GEOHASH
  final int maxItemsForMaxDistAlgo;

  /// Function to update Markers on Google Map
  final void Function(Set<Marker>) updateMarkers;

  /// Zoom levels configuration
  final List<double> levels;

  /// Extra percent of markers to be loaded (ex : 0.2 for 20%)
  final double extraPercent;

  // Clusteringalgorithm
  final ClusterAlgorithm clusterAlgorithm;

  final MaxDistParams? maxDistParams;

  /// Zoom level to stop cluster rendering
  final double? stopClusteringZoom;

  /// Precision of the geohash
  static const precision = kIsWeb ? 12 : 20;

  /// Google Maps map id
  int? _mapId;

  /// List of items
  Iterable<T> get items => _items;
  Iterable<T> _items;

  /// Last known zoom
  late double _zoom;

  final double _maxLng = 180 - pow(10, -10.0) as double;

  /// Set Google Map Id for the cluster manager
  Future<void> setMapId(int mapId, {bool withUpdate = true}) async {
    _mapId = mapId;
    _zoom = await GoogleMapsFlutterPlatform.instance.getZoomLevel(mapId: mapId);
    if (withUpdate) updateMap();
  }

  /// Method called on map update to update cluster. Can also be manually called to force update.
  void updateMap() {
    _updateClusters();
  }

  Future<void> _updateClusters() async {
    final mapMarkers = await getMarkers();

    final markers = Set<Marker>.from(await Future.wait(mapMarkers.map(markerBuilder)));

    updateMarkers(markers);
  }

  /// Update all cluster items
  void setItems(List<T> newItems) {
    _items = newItems;
    updateMap();
  }

  /// Add on cluster item
  void addItem(ClusterItem newItem) {
    _items = List.from([...items, newItem]);
    updateMap();
  }

  /// Method called on camera move
  void onCameraMove(CameraPosition position, {bool forceUpdate = false}) {
    _zoom = position.zoom;
    if (forceUpdate) {
      updateMap();
    }
  }

  /// Retrieve cluster markers
  Future<List<Cluster<T>>> getMarkers() async {
    if (_mapId == null) return List.empty();

    final mapBounds = await GoogleMapsFlutterPlatform.instance.getVisibleRegion(mapId: _mapId!);

    late LatLngBounds inflatedBounds;
    if (clusterAlgorithm == ClusterAlgorithm.geoHash) {
      inflatedBounds = _inflateBounds(mapBounds);
    } else {
      inflatedBounds = mapBounds;
    }

    final visibleItems = items.where((i) {
      return inflatedBounds.contains(i.location);
    }).toList();

    if (stopClusteringZoom != null && _zoom >= stopClusteringZoom!) {
      return visibleItems.map((i) => Cluster<T>.fromItems([i])).toList();
    }

    List<Cluster<T>> markers;

    if (clusterAlgorithm == ClusterAlgorithm.geoHash || visibleItems.length >= maxItemsForMaxDistAlgo) {
      final level = _findLevel(levels);
      markers = _computeClusters(visibleItems, List.empty(growable: true), level: level);
    } else {
      markers = _computeClustersWithMaxDist(visibleItems, _zoom);
    }

    return markers;
  }

  LatLngBounds _inflateBounds(LatLngBounds bounds) {
    // Bounds that cross the date line expand compared to their difference with the date line
    var lng = 0.0;
    if (bounds.northeast.longitude < bounds.southwest.longitude) {
      lng = extraPercent * ((180.0 - bounds.southwest.longitude) + (bounds.northeast.longitude + 180));
    } else {
      lng = extraPercent * (bounds.northeast.longitude - bounds.southwest.longitude);
    }

    // Latitudes expanded beyond +/- 90 are automatically clamped by LatLng
    final lat = extraPercent * (bounds.northeast.latitude - bounds.southwest.latitude);

    final eLng = (bounds.northeast.longitude + lng).clamp(-_maxLng, _maxLng);
    final wLng = (bounds.southwest.longitude - lng).clamp(-_maxLng, _maxLng);

    return LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude - lat, wLng),
      northeast: LatLng(bounds.northeast.latitude + lat, lng != 0 ? eLng : _maxLng),
    );
  }

  int _findLevel(List<double> levels) {
    for (var i = levels.length - 1; i >= 0; i--) {
      if (levels[i] <= _zoom) {
        return i + 1;
      }
    }

    return 1;
  }

  int _getZoomLevel(double zoom) {
    for (var i = levels.length - 1; i >= 0; i--) {
      if (levels[i] <= zoom) {
        return levels[i].toInt();
      }
    }

    return 1;
  }

  List<Cluster<T>> _computeClustersWithMaxDist(List<T> inputItems, double zoom) {
    final scanner = MaxDistClustering<T>(
      epsilon: maxDistParams?.epsilon ?? 20,
    );

    return scanner.run(inputItems, _getZoomLevel(zoom));
  }

  List<Cluster<T>> _computeClusters(List<T> inputItems, List<Cluster<T>> markerItems, {int level = 5}) {
    if (inputItems.isEmpty) return markerItems;
    final nextGeohash = inputItems[0].geohash.substring(0, level);

    final items = inputItems.where((p) => p.geohash.substring(0, level) == nextGeohash).toList();

    markerItems.add(Cluster<T>.fromItems(items));

    final newInputList = List<T>.from(inputItems.where((i) => i.geohash.substring(0, level) != nextGeohash));

    return _computeClusters(newInputList, markerItems, level: level);
  }

  static Future<Marker> Function(Cluster) get _basicMarkerBuilder => (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () {
            if (kDebugMode) {
              print(cluster);
            }
          },
          icon: await _getBasicClusterBitmap(
            cluster.isMultiple ? 125 : 75,
            text: cluster.isMultiple ? cluster.count.toString() : null,
          ),
        );
      };

  static Future<BitmapDescriptor> _getBasicClusterBitmap(int size, {String? text}) async {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint1 = Paint()..color = Colors.red;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);

    if (text != null) {
      final painter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: text,
          style: TextStyle(fontSize: size / 3, color: Colors.white, fontWeight: FontWeight.normal),
        )
        ..layout();

      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png);

    if (data == null) return BitmapDescriptor.defaultMarker;

    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }
}
