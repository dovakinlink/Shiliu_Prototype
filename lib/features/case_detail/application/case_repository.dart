import '../domain/case_models.dart';

abstract interface class CaseRepository {
  Future<List<CaseSummary>> getCaseSummaries();

  Future<CaseDetail?> getCaseDetail(String caseId);

  Future<CaseSummary> createCase({
    required String patientName,
    required String sex,
    required int birthYear,
    required String primarySite,
    required String tumorType,
    String? histology,
    String? stage,
  });
}
