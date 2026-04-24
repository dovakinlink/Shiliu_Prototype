import '../domain/dashboard_metric.dart';

abstract interface class DashboardRepository {
  Future<DashboardSnapshot> getSnapshot();
}
