import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_enums.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import 'intake_page.dart';

enum _CapturePhase { ready, captured }

class CaptureSimulationPage extends ConsumerStatefulWidget {
  const CaptureSimulationPage({required this.source, super.key});

  final UploadSource source;

  @override
  ConsumerState<CaptureSimulationPage> createState() =>
      _CaptureSimulationPageState();
}

class _CaptureSimulationPageState
    extends ConsumerState<CaptureSimulationPage> {
  _CapturePhase _phase = _CapturePhase.ready;

  void _setPhase(_CapturePhase phase) => setState(() => _phase = phase);

  Future<void> _openComposer() async {
    final cases = ref.read(intakeCaseOptionsProvider);
    final caseOptions = cases.asData?.value;
    if (caseOptions == null) return;

    final jobId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => UploadComposerSheet(
        source: widget.source,
        cases: caseOptions,
        navigateToProcessing: true,
      ),
    );

    if (jobId != null && mounted) {
      context.pushReplacement('/processing/$jobId');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(intakeCaseOptionsProvider);

    return Scaffold(
      backgroundColor: widget.source == UploadSource.camera
          ? const Color(0xFF1A1A1A)
          : null,
      appBar: AppBar(
        title: Text(widget.source.label),
        backgroundColor: widget.source == UploadSource.camera
            ? const Color(0xFF1A1A1A)
            : null,
        foregroundColor:
            widget.source == UploadSource.camera ? Colors.white : null,
      ),
      body: switch (widget.source) {
        UploadSource.camera => _CameraView(
            phase: _phase,
            onCapture: () => _setPhase(_CapturePhase.captured),
            onUse: _openComposer,
            onRetake: () => _setPhase(_CapturePhase.ready),
          ),
        UploadSource.pdf => _PdfPickerView(
            phase: _phase,
            onSelect: () => _setPhase(_CapturePhase.captured),
            onConfirm: _openComposer,
          ),
        UploadSource.voice => _VoiceRecorderView(
            phase: _phase,
            onToggle: () {
              final next = _phase == _CapturePhase.ready
                  ? _CapturePhase.captured
                  : _CapturePhase.ready;
              _setPhase(next);
            },
            onUse: _openComposer,
          ),
        UploadSource.gallery => _GalleryPickerView(
            onConfirm: _openComposer,
          ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Camera simulation
// ---------------------------------------------------------------------------
class _CameraView extends StatelessWidget {
  const _CameraView({
    required this.phase,
    required this.onCapture,
    required this.onUse,
    required this.onRetake,
  });

  final _CapturePhase phase;
  final VoidCallback onCapture;
  final VoidCallback onUse;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    if (phase == _CapturePhase.captured) {
      return _CameraPreview(onUse: onUse, onRetake: onRetake);
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withAlpha(80),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Stack(
                  children: <Widget>[
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.document_scanner_outlined,
                            size: 48,
                            color: Colors.white.withAlpha(100),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '将文档对准取景框',
                            style: TextStyle(
                              color: Colors.white.withAlpha(160),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Corner markers
                    ..._buildCornerMarkers(),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
          ),
          child: GestureDetector(
            onTap: onCapture,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCornerMarkers() {
    const length = 24.0;
    const thickness = 3.0;
    const color = AppPalette.primary;

    Widget corner(Alignment alignment) {
      final isTop = alignment.y < 0;
      final isLeft = alignment.x < 0;
      return Positioned(
        top: isTop ? 0 : null,
        bottom: isTop ? null : 0,
        left: isLeft ? 0 : null,
        right: isLeft ? null : 0,
        child: SizedBox(
          width: length,
          height: length,
          child: CustomPaint(
            painter: _CornerPainter(
              color: color,
              thickness: thickness,
              isTop: isTop,
              isLeft: isLeft,
            ),
          ),
        ),
      );
    }

    return <Widget>[
      corner(Alignment.topLeft),
      corner(Alignment.topRight),
      corner(Alignment.bottomLeft),
      corner(Alignment.bottomRight),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({
    required this.color,
    required this.thickness,
    required this.isTop,
    required this.isLeft,
  });

  final Color color;
  final double thickness;
  final bool isTop;
  final bool isLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.onUse, required this.onRetake});

  final VoidCallback onUse;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppPalette.primary.withAlpha(100),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppPalette.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      size: 32,
                      color: AppPalette.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '病理报告',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '文档已识别 · 1 页',
                    style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            0,
            AppSpacing.xxl,
            MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重拍'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withAlpha(80),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onUse,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('使用照片'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PDF picker simulation
// ---------------------------------------------------------------------------
class _PdfPickerView extends StatefulWidget {
  const _PdfPickerView({
    required this.phase,
    required this.onSelect,
    required this.onConfirm,
  });

  final _CapturePhase phase;
  final VoidCallback onSelect;
  final VoidCallback onConfirm;

  @override
  State<_PdfPickerView> createState() => _PdfPickerViewState();
}

class _PdfPickerViewState extends State<_PdfPickerView> {
  int? _selectedIndex;

  static const _files = <({String name, String size, String date})>[
    (name: '病理报告_张女士_2026.pdf', size: '2.4 MB', date: '04-12'),
    (name: '影像报告_CT_胸腹盆.pdf', size: '5.1 MB', date: '04-10'),
    (name: '实验室检验单_血常规.pdf', size: '0.8 MB', date: '04-08'),
    (name: '出院小结_肿瘤内科.pdf', size: '1.2 MB', date: '04-05'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page, AppSpacing.md, AppSpacing.page, AppSpacing.md,
          ),
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
              hintText: '搜索文件…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: isDark
                  ? AppPalette.surfaceVariantDark
                  : AppPalette.surfaceVariantLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            itemCount: _files.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 52),
            itemBuilder: (context, index) {
              final file = _files[index];
              final selected = _selectedIndex == index;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppPalette.error.withAlpha(isDark ? 20 : 14),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 20,
                    color: AppPalette.error,
                  ),
                ),
                title: Text(
                  file.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${file.size} · ${file.date}'),
                trailing: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppPalette.primary,
                        size: 22,
                      )
                    : null,
                selected: selected,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                onTap: () {
                  setState(() => _selectedIndex = index);
                  if (!selected) widget.onSelect();
                },
              );
            },
          ),
        ),
        if (_selectedIndex != null)
          _BottomConfirmBar(
            label: '已选 1 个文件',
            onConfirm: widget.onConfirm,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Voice recorder simulation
// ---------------------------------------------------------------------------
class _VoiceRecorderView extends StatefulWidget {
  const _VoiceRecorderView({
    required this.phase,
    required this.onToggle,
    required this.onUse,
  });

  final _CapturePhase phase;
  final VoidCallback onToggle;
  final VoidCallback onUse;

  @override
  State<_VoiceRecorderView> createState() => _VoiceRecorderViewState();
}

class _VoiceRecorderViewState extends State<_VoiceRecorderView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final captured = widget.phase == _CapturePhase.captured;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        children: <Widget>[
          const Spacer(),
          if (!captured) ...<Widget>[
            SizedBox(
              height: 80,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) => CustomPaint(
                  painter: _WavePainter(
                    phase: _waveController.value * 2 * math.pi,
                    color: AppPalette.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              '00:12',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w300,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '正在录音…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppPalette.primary,
              ),
            ),
          ] else ...<Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: isDark
                    ? AppPalette.surfaceVariantDark
                    : AppPalette.surfaceVariantLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppPalette.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '录音完成 · 00:12',
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('模拟转写预览', style: theme.textTheme.labelSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '患者自述体力尚可，日常活动基本自理，ECOG 评分 1 分。'
                    '近期体重 54.5 公斤，较上次减轻 1.5 公斤。'
                    '诉轻度乏力，不影响日常生活。口服药物按时服用，未漏服。',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (!captured)
            GestureDetector(
              onTap: widget.onToggle,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppPalette.error.withAlpha(30),
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  size: 36,
                  color: AppPalette.error,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onUse,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('使用录音'),
              ),
            ),
          SizedBox(
            height: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(80)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int wave = 0; wave < 3; wave++) {
      final path = Path();
      final amplitude = (size.height / 4) * (1 - wave * 0.25);
      final phaseOffset = wave * 0.8;
      for (double x = 0; x <= size.width; x++) {
        final y = size.height / 2 +
            amplitude *
                math.sin((x / size.width * 4 * math.pi) + phase + phaseOffset);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint..color = color.withAlpha(80 - wave * 20));
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

// ---------------------------------------------------------------------------
// Gallery picker simulation
// ---------------------------------------------------------------------------
class _GalleryPickerView extends StatefulWidget {
  const _GalleryPickerView({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  State<_GalleryPickerView> createState() => _GalleryPickerViewState();
}

class _GalleryPickerViewState extends State<_GalleryPickerView> {
  final _selected = <int>{};

  static const _colors = <List<Color>>[
    [Color(0xFFE8D5B7), Color(0xFFF5EDE0)],
    [Color(0xFFD5E8DB), Color(0xFFE8F5EC)],
    [Color(0xFFD5DBE8), Color(0xFFE0E8F5)],
    [Color(0xFFE8D5D5), Color(0xFFF5E0E0)],
    [Color(0xFFDBE8D5), Color(0xFFECF5E8)],
    [Color(0xFFE8E2D5), Color(0xFFF5F0E0)],
    [Color(0xFFD5E2E8), Color(0xFFE0EEF5)],
    [Color(0xFFE2D5E8), Color(0xFFEEE0F5)],
    [Color(0xFFE8DBD5), Color(0xFFF5EDE8)],
    [Color(0xFFD5E8E2), Color(0xFFE0F5EE)],
    [Color(0xFFDBD5E8), Color(0xFFEDE0F5)],
    [Color(0xFFE8E8D5), Color(0xFFF5F5E0)],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.xs),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final selected = _selected.contains(index);
              final colors = _colors[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selected.remove(index);
                    } else {
                      _selected.add(index);
                    }
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: colors[0].withAlpha(140),
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        color: AppPalette.primary.withAlpha(40),
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppPalette.primary,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_selected.isNotEmpty)
          _BottomConfirmBar(
            label: '已选 ${_selected.length} 张',
            onConfirm: widget.onConfirm,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bottom confirm bar
// ---------------------------------------------------------------------------
class _BottomConfirmBar extends StatelessWidget {
  const _BottomConfirmBar({
    required this.label,
    required this.onConfirm,
  });

  final String label;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.md + bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppPalette.surfaceDark : AppPalette.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppPalette.borderDark : AppPalette.borderLight,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          FilledButton(
            onPressed: onConfirm,
            child: const Text('下一步'),
          ),
        ],
      ),
    );
  }
}
