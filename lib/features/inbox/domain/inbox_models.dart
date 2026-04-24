import '../../../core/constants/app_enums.dart';
import '../../intake/domain/upload_job.dart';
import '../../screening/domain/screening_models.dart';

enum InboxItemType { upload, completeness }

enum InboxFilter { all, uploading, pending, conflict }

class InboxItem {
  const InboxItem.upload(this.uploadJob)
      : task = null,
        type = InboxItemType.upload;

  const InboxItem.task(this.task)
      : uploadJob = null,
        type = InboxItemType.completeness;

  final InboxItemType type;
  final UploadJob? uploadJob;
  final CompletenessTask? task;

  String get sortKey {
    if (uploadJob != null) return uploadJob!.createdAtLabel;
    return task!.dueLabel;
  }

  bool matchesFilter(InboxFilter filter) {
    return switch (filter) {
      InboxFilter.all => true,
      InboxFilter.uploading =>
        type == InboxItemType.upload &&
            uploadJob!.stage != UploadJobStage.needsReview,
      InboxFilter.pending =>
        (type == InboxItemType.completeness &&
            task!.type == TaskType.missingField) ||
        (type == InboxItemType.upload &&
            uploadJob!.stage == UploadJobStage.needsReview),
      InboxFilter.conflict =>
        type == InboxItemType.completeness &&
            task!.type == TaskType.conflictReview,
    };
  }
}

extension InboxFilterX on InboxFilter {
  String get label => switch (this) {
        InboxFilter.all => '全部',
        InboxFilter.uploading => '采集中',
        InboxFilter.pending => '待补录',
        InboxFilter.conflict => '冲突',
      };
}

class InboxSnapshot {
  const InboxSnapshot({
    required this.items,
    required this.totalCount,
    required this.uploadingCount,
    required this.pendingCount,
    required this.conflictCount,
  });

  final List<InboxItem> items;
  final int totalCount;
  final int uploadingCount;
  final int pendingCount;
  final int conflictCount;
}
