// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


import 'cluster_item.dart';

@immutable
class Cluster<T extends ClusterItem> {
  const Cluster(this.items, this.location);

  Cluster.fromItems(this.items)
      : location = LatLng(
          items.fold<double>(0, (p, c) => p + c.location.latitude) / items.length,
          items.fold<double>(0, (p, c) => p + c.location.longitude) / items.length,
        );

  //location becomes weighted avarage lat lon
  Cluster.fromClusters(Cluster<T> cluster1, Cluster<T> cluster2)
      : items = cluster1.items.toSet()..addAll(cluster2.items.toSet()),
        location = LatLng(
          (cluster1.location.latitude * cluster1.count + cluster2.location.latitude * cluster2.count) /
              (cluster1.count + cluster2.count),
          (cluster1.location.longitude * cluster1.count + cluster2.location.longitude * cluster2.count) /
              (cluster1.count + cluster2.count),
        );

  final LatLng location;
  final Iterable<T> items;

  /// Get number of clustered items
  int get count => items.length;

  /// True if cluster is not a single item cluster
  bool get isMultiple => items.length > 1;

  /// Basic cluster marker id
  String getId() {
    return '${location.latitude}_${location.longitude}_$count';
  }

  @override
  String toString() {
    return 'Cluster of $count $T (${location.latitude}, ${location.longitude})';
  }

  @override
  bool operator ==(Object other) => other is Cluster && items == other.items;

  @override
  int get hashCode => items.hashCode;
}
