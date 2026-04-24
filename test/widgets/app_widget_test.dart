import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiliu_app_prototype/app/shiliu_app.dart';
import 'package:shiliu_app_prototype/features/case_detail/presentation/case_detail_page.dart';
import 'package:shiliu_app_prototype/features/screening/presentation/screening_page.dart';
import 'package:shiliu_app_prototype/shared/widgets/create_case_sheet.dart';

void main() {
  testWidgets('app starts on inbox and bottom navigation works', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ShiliuApp()));
    await tester.pumpAndSettle();

    expect(find.text('收件箱'), findsWidgets);

    await tester.tap(find.text('病例库'));
    await tester.pumpAndSettle();
    expect(find.text('病例库'), findsWidgets);

    await tester.tap(find.text('筛查中心'));
    await tester.pumpAndSettle();
    expect(find.text('筛查中心'), findsWidgets);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('张医生'), findsOneWidget);
  });

  testWidgets('case detail renders GU CRF tab dynamically', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: CaseDetailPage(caseId: 'case-005')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('专病 CRF'));
    await tester.pumpAndSettle();

    expect(find.text('泌尿生殖系统恶性肿瘤专病CRF'), findsWidgets);
    expect(find.text('搜索字段'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('入院记录'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.text('入院记录'));
    await tester.pumpAndSettle();

    expect(find.text('尿路梗阻程度'), findsOneWidget);
    expect(find.text('gu.admission.urinary_obstruction'), findsOneWidget);
  });

  testWidgets('screening snapshot shows core and CRF completeness', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ScreeningPage(caseId: 'case-005')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('通用核心'), findsOneWidget);
    expect(find.text('GU V2026-03'), findsOneWidget);
  });

  testWidgets('create case sheet exposes disease profile template selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: CreateCaseSheet())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('新建病例'), findsOneWidget);
    expect(find.text('瘤种包 / CRF 模板'), findsOneWidget);
  });
}
