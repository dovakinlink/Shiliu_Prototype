import '../domain/crf_models.dart';

abstract interface class CRFRepository {
  Future<List<DiseaseProfile>> getDiseaseProfiles();

  Future<CRFTemplate?> getTemplate(String templateId);

  Future<DiseaseProfile?> getDiseaseProfile(String profileId);
}
