import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Full-screen animated overlay shown when a settlement is approved.
///
/// Shows a coin/token flowing from [payerName] → [receiverName] along a
/// curved arc, then fades in "debt cleared" confirmations. Auto-dismisses
/// after the animation completes.
class SettlementFlowAnimation extends StatefulWidget {
  const SettlementFlowAnimation({
    super.key,
    required this.payerName,
    required this.receiverName,
    required this.initiatorName,
    required this.amount,
  });

  final String payerName;
  final String receiverName;
  final String initiatorName;
  final double amount;

  @override
  State<SettlementFlowAnimation> createState() =>
      _SettlementFlowAnimationState();
}

class _SettlementFlowAnimationState extends State<SettlementFlowAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Token travels 0 → 1 along the arc
  late final Animation<double> _tokenProgress;
  // Path line draws 0 → 1
  late final Animation<double> _pathDraw;
  // "Cleared" labels fade in after token arrives
  late final Animation<double> _labelsOpacity;
  // Dismiss button fades in at the end
  late final Animation<double> _buttonOpacity;

  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _pathDraw = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _tokenProgress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.1, 0.65, curve: Curves.easeInOut),
    );
    _labelsOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.6, 0.85, curve: Curves.easeIn),
    );
    _buttonOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF8F2);
    final fg = isDark ? Colors.white : Colors.black;
    final accent = const Color(0xFF7C3AED); // purple

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // ── Title ──────────────────────────────────────────────────────
              Text(
                'Settlement Complete',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: -0.44,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _fmt.format(widget.amount),
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  letterSpacing: -0.72,
                ),
              ),
              const SizedBox(height: 40),

              // ── Flow diagram ───────────────────────────────────────────────
              Expanded(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _FlowPainter(
                        pathProgress: _pathDraw.value,
                        tokenProgress: _tokenProgress.value,
                        fg: fg,
                        accent: accent,
                      ),
                      child: _buildLabels(fg, accent),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // ── "Debt cleared" confirmations ───────────────────────────────
              FadeTransition(
                opacity: _labelsOpacity,
                child: Column(
                  children: [
                    _clearedRow(
                        '${widget.payerName} → ${widget.initiatorName}', fg),
                    const SizedBox(height: 8),
                    _clearedRow(
                        '${widget.initiatorName} → ${widget.receiverName}', fg),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Dismiss button ─────────────────────────────────────────────
              FadeTransition(
                opacity: _buttonOpacity,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: accent,
                      border: Border.all(color: fg, width: 1.5),
                      boxShadow: [
                        BoxShadow(color: fg.withValues(alpha: 0.25), offset: const Offset(4, 4)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabels(Color fg, Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final payerPos = Offset(w * 0.1, h * 0.35);
        final receiverPos = Offset(w * 0.9, h * 0.35);
        final initiatorPos = Offset(w * 0.5, h * 0.85);

        return Stack(
          children: [
            _nodeLabel(widget.payerName, payerPos, fg, 'PAYER', align: CrossAxisAlignment.start),
            _nodeLabel(widget.receiverName, receiverPos, fg, 'RECEIVER', align: CrossAxisAlignment.end),
            _nodeLabel(widget.initiatorName, initiatorPos, fg, 'VIA', align: CrossAxisAlignment.center),
          ],
        );
      },
    );
  }

  Widget _nodeLabel(String name, Offset center, Color fg, String role,
      {CrossAxisAlignment align = CrossAxisAlignment.center}) {
    final offset = Offset(
      center.dx - 48,
      center.dy + 30,
    );
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: 96,
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            role,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: fg.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _clearedRow(String label, Color fg) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.green,
            border: Border.all(color: fg, width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.check, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$label  cleared',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowPainter extends CustomPainter {
  const _FlowPainter({
    required this.pathProgress,
    required this.tokenProgress,
    required this.fg,
    required this.accent,
  });

  final double pathProgress;
  final double tokenProgress;
  final Color fg;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Node positions (matching label positions in _buildLabels)
    final payer = Offset(w * 0.1, h * 0.35);
    final receiver = Offset(w * 0.9, h * 0.35);
    final initiator = Offset(w * 0.5, h * 0.85);

    // Draw the three nodes
    _drawNode(canvas, payer, fg, accent, label: '');
    _drawNode(canvas, receiver, fg, accent, label: '');
    _drawNode(canvas, initiator, fg, Colors.grey, label: '');

    // Arc path from payer → receiver (top)
    final arcPath = _buildArc(payer, receiver, curvature: -h * 0.3);
    _drawPartialPath(canvas, arcPath, pathProgress, fg.withValues(alpha: 0.3), strokeWidth: 1.5, dashed: true);

    // Lines to initiator (dimmer)
    final payerToInitiator = _buildArc(payer, initiator, curvature: 0);
    _drawPartialPath(canvas, payerToInitiator, pathProgress * 0.5, fg.withValues(alpha: 0.15), strokeWidth: 1.0, dashed: true);
    final initiatorToReceiver = _buildArc(initiator, receiver, curvature: 0);
    _drawPartialPath(canvas, initiatorToReceiver, pathProgress * 0.5, fg.withValues(alpha: 0.15), strokeWidth: 1.0, dashed: true);

    // Draw animated token along the main arc
    if (tokenProgress > 0) {
      final tokenPos = _pointOnArc(payer, receiver, curvature: -h * 0.3, t: tokenProgress);
      _drawToken(canvas, tokenPos, accent, tokenProgress);
    }
  }

  void _drawNode(Canvas canvas, Offset center, Color stroke, Color fill, {String label = ''}) {
    final paint = Paint()
      ..color = fill.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, paint);

    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 18, strokePaint);
  }

  void _drawToken(Canvas canvas, Offset pos, Color color, double progress) {
    final radius = 10.0;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(pos, radius * 1.5, glow);

    final fill = Paint()..color = color;
    canvas.drawCircle(pos, radius, fill);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(pos, radius, border);
  }

  Path _buildArc(Offset start, Offset end, {double curvature = 0}) {
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final control = Offset(mid.dx, mid.dy + curvature);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    return path;
  }

  void _drawPartialPath(Canvas canvas, Path path, double progress,
      Color color, {double strokeWidth = 1.5, bool dashed = false}) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (progress >= 1.0) {
      canvas.drawPath(path, paint);
      return;
    }

    // Extract partial path using PathMetrics
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final partial = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(partial, paint);
    }
  }

  Offset _pointOnArc(Offset start, Offset end,
      {double curvature = 0, required double t}) {
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final control = Offset(mid.dx, mid.dy + curvature);
    // Quadratic bezier: B(t) = (1-t)²·P0 + 2(1-t)t·P1 + t²·P2
    final u = 1 - t;
    return Offset(
      u * u * start.dx + 2 * u * t * control.dx + t * t * end.dx,
      u * u * start.dy + 2 * u * t * control.dy + t * t * end.dy,
    );
  }

  @override
  bool shouldRepaint(_FlowPainter old) =>
      old.pathProgress != pathProgress || old.tokenProgress != tokenProgress;
}
