import '../../../core/constants/app_enums.dart';
import '../domain/upload_job.dart';

abstract interface class UploadRepository {
  Future<List<UploadJob>> getJobs();

  Future<UploadJob> createUpload({
    required String patientId,
    required String documentType,
    required UploadSource source,
    required String description,
  });

  Future<void> advanceJob(String jobId);

  Future<void> advanceToNeedsReview(String jobId);
}
