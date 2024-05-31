// Clustering maps
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'google_maps_cluster/src/cluster_item.dart';

class Place with ClusterItem {
  final String name;
  final LatLng latLng;

  Place({required this.name, required this.latLng});

  @override
  LatLng get location => latLng;
}