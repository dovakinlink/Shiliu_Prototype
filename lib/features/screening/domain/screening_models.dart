import '../../../core/constants/app_enums.dart';

class ConflictEntry {
  const ConflictEntry({
    required this.field,
    required this.sourceA,
    required this.valueA,
    required this.sourceB,
    required this.valueB,
  });

  final String field;
  final String sourceA;
  final String valueA;
  final String sourceB;
  final String valueB;
}

class CompletenessTask {
  const CompletenessTask({
    required this.id,
    required this.caseId,
    required this.title,
    required this.type,
    required this.description,
    required this.fields,
    required this.owner,
    required this.dueLabel,
    this.conflicts = const <ConflictEntry>[],
    this.isBlocking = false,
    this.isCompleted = false,
  });

  final String id;
  final String caseId;
  final String title;
  final TaskType type;
  final String description;
  final List<String> fields;
  final List<ConflictEntry> conflicts;
  final String owner;
  final String dueLabel;
  final bool isBlocking;
  final bool isCompleted;

  CompletenessTask copyWith({
    bool? isCompleted,
    List<String>? fields,
    List<ConflictEntry>? conflicts,
  }) {
    return CompletenessTask(
      id: id,
      caseId: caseId,
      title: title,
      type: type,
      description: description,
      fields: fields ?? this.fields,
      conflicts: conflicts ?? this.conflicts,
      owner: owner,
      dueLabel: dueLabel,
      isBlocking: isBlocking,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ScreeningSnapshot {
  const ScreeningSnapshot({
    required this.caseId,
    required this.projectTitle,
    required this.status,
    required this.keyFacts,
    required this.blockingFields,
    required this.reminderFields,
    required this.tasks,
  });

  final String caseId;
  final String projectTitle;
  final ScreeningStatus status;
  final List<String> keyFacts;
  final List<String> blockingFields;
  final List<String> reminderFields;
  final List<CompletenessTask> tasks;

  List<String> get missingFields => <String>[
        ...blockingFields,
        ...reminderFields,
      ];

  ScreeningSnapshot copyWith({
    ScreeningStatus? status,
    List<String>? keyFacts,
    List<String>? blockingFields,
    List<String>? reminderFields,
    List<CompletenessTask>? tasks,
  }) {
    return ScreeningSnapshot(
      caseId: caseId,
      projectTitle: projectTitle,
      status: status ?? this.status,
      keyFacts: keyFacts ?? this.keyFacts,
      blockingFields: blockingFields ?? this.blockingFields,
      reminderFields: reminderFields ?? this.reminderFields,
      tasks: tasks ?? this.tasks,
    );
  }
}
