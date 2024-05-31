

import 'cluster.dart';
import 'cluster_item.dart';
import 'common.dart';

class _MinDistCluster<T extends ClusterItem> {
  _MinDistCluster(this.cluster, this.dist);

  final Cluster<T> cluster;
  final double dist;
}

class MaxDistClustering<T extends ClusterItem> {
  MaxDistClustering({
    this.epsilon = 1,
  });

  ///Complete list of points
  late List<T> dataset;

  final List<Cluster<T>> _cluster = [];

  ///Threshold distance for two clusters to be considered as one cluster
  final double epsilon;

  final DistUtils distUtils = DistUtils();

  ///Run clustering process, add configs in constructor
  List<Cluster<T>> run(List<T> dataset, int zoomLevel) {
    this.dataset = dataset;

    //initial variables
    final distMatrix = <List<double>>[];
    for (final entry1 in dataset) {
      distMatrix.add([]);
      _cluster.add(Cluster.fromItems([entry1]));
    }

    var changed = true;

    while (changed) {
      changed = false;
      for (final c in _cluster) {
        final minDistCluster = getClosestCluster(c, zoomLevel);
        if (minDistCluster == null || minDistCluster.dist > epsilon) continue;
        _cluster
          ..add(Cluster.fromClusters(minDistCluster.cluster, c))
          ..remove(c)
          ..remove(minDistCluster.cluster);

        changed = true;

        break;
      }
    }
    return _cluster;
  }

  _MinDistCluster<T>? getClosestCluster(Cluster cluster, int zoomLevel) {
    var minDist = 1000000000.0;
    var minDistCluster = Cluster<T>.fromItems(const []);
    for (final c in _cluster) {
      if (c.location == cluster.location) continue;
      final tmp = distUtils.getLatLonDist(
        c.location,
        cluster.location,
        zoomLevel,
      );

      if (tmp < minDist) {
        minDist = tmp;
        minDistCluster = Cluster<T>.fromItems(c.items);
      }
    }
    return _MinDistCluster(minDistCluster, minDist);
  }
}
