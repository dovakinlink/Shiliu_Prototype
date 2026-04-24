import '../domain/screening_models.dart';

abstract interface class ScreeningRepository {
  Future<ScreeningSnapshot?> getSnapshot(String caseId);

  Future<void> supplementFields(String caseId, Map<String, String> values);
}
