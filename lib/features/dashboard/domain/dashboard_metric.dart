import '../../case_detail/domain/case_models.dart';
import '../../screening/domain/screening_models.dart';

class DashboardMetric {
  const DashboardMetric({
    required this.id,
    required this.label,
    required this.value,
    required this.helper,
    required this.deltaLabel,
    this.isPositive = true,
  });

  final String id;
  final String label;
  final String value;
  final String helper;
  final String deltaLabel;
  final bool isPositive;
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.metrics,
    required this.structuredProgress,
    required this.pendingTasks,
    required this.recentCases,
  });

  final List<DashboardMetric> metrics;
  final double structuredProgress;
  final List<CompletenessTask> pendingTasks;
  final List<CaseSummary> recentCases;
}
