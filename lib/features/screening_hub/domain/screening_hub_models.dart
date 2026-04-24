import '../../../core/constants/app_enums.dart';

class ScreeningHubSnapshot {
  const ScreeningHubSnapshot({
    required this.totalCases,
    required this.readyCount,
    required this.partialCount,
    required this.notReadyCount,
    required this.overallProgress,
    required this.projects,
    required this.topBlockingFields,
  });

  final int totalCases;
  final int readyCount;
  final int partialCount;
  final int notReadyCount;
  final double overallProgress;
  final List<ScreeningProject> projects;
  final List<BlockingFieldSummary> topBlockingFields;
}

class ScreeningProject {
  const ScreeningProject({
    required this.projectTitle,
    required this.caseId,
    required this.patientName,
    required this.patientCode,
    required this.status,
    required this.keyFacts,
    required this.blockingCount,
    required this.reminderCount,
  });

  final String projectTitle;
  final String caseId;
  final String patientName;
  final String patientCode;
  final ScreeningStatus status;
  final List<String> keyFacts;
  final int blockingCount;
  final int reminderCount;
}

class BlockingFieldSummary {
  const BlockingFieldSummary({
    required this.fieldName,
    required this.caseCount,
    required this.caseIds,
  });

  final String fieldName;
  final int caseCount;
  final List<String> caseIds;
}
