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
    this.templateId,
    this.fieldCode,
    this.fieldPath = const <String>[],
    this.scope = TaskScope.canonical,
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
  final String? templateId;
  final String? fieldCode;
  final List<String> fieldPath;
  final TaskScope scope;
  final List<ConflictEntry> conflicts;
  final String owner;
  final String dueLabel;
  final bool isBlocking;
  final bool isCompleted;

  CompletenessTask copyWith({
    bool? isCompleted,
    List<String>? fields,
    List<ConflictEntry>? conflicts,
    String? templateId,
    String? fieldCode,
    List<String>? fieldPath,
    TaskScope? scope,
  }) {
    return CompletenessTask(
      id: id,
      caseId: caseId,
      title: title,
      type: type,
      description: description,
      fields: fields ?? this.fields,
      templateId: templateId ?? this.templateId,
      fieldCode: fieldCode ?? this.fieldCode,
      fieldPath: fieldPath ?? this.fieldPath,
      scope: scope ?? this.scope,
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
    this.coreCompletionRate = 0,
    this.crfCompletionRate = 0,
    this.crfTemplateLabel,
  });

  final String caseId;
  final String projectTitle;
  final ScreeningStatus status;
  final List<String> keyFacts;
  final List<String> blockingFields;
  final List<String> reminderFields;
  final List<CompletenessTask> tasks;
  final double coreCompletionRate;
  final double crfCompletionRate;
  final String? crfTemplateLabel;

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
    double? coreCompletionRate,
    double? crfCompletionRate,
    String? crfTemplateLabel,
  }) {
    return ScreeningSnapshot(
      caseId: caseId,
      projectTitle: projectTitle,
      status: status ?? this.status,
      keyFacts: keyFacts ?? this.keyFacts,
      blockingFields: blockingFields ?? this.blockingFields,
      reminderFields: reminderFields ?? this.reminderFields,
      tasks: tasks ?? this.tasks,
      coreCompletionRate: coreCompletionRate ?? this.coreCompletionRate,
      crfCompletionRate: crfCompletionRate ?? this.crfCompletionRate,
      crfTemplateLabel: crfTemplateLabel ?? this.crfTemplateLabel,
    );
  }
}
