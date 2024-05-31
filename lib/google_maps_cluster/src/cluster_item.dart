import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'cluster_manager.dart';
import 'geohash.dart';

mixin ClusterItem {
  LatLng get location;

  String? _geohash;
  String get geohash => _geohash ??= Geohash.encode(
        latLng: location,
        codeLength: ClusterManager.precision,
      );
}
