import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiliu_app_prototype/app/shiliu_app.dart';
import 'package:shiliu_app_prototype/features/case_detail/presentation/case_detail_page.dart';

void main() {
  testWidgets('app starts on inbox and bottom navigation works',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ShiliuApp()),
    );
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

  testWidgets('case detail links selected field to evidence highlighting',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CaseDetailPage(caseId: 'case-001'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('近期安全性评估'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('近期安全性评估'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('ECOG评分'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('ECOG评分'));
    await tester.pumpAndSettle();

    expect(find.text('当前字段'), findsOneWidget);
    expect(find.text('已定位'), findsOneWidget);
  });
}
