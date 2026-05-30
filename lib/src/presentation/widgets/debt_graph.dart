import 'dart:math';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Describes a settlement animation to replay on the debt graph.
///
/// Stages:
///  1. A dot moves along a new C→B arc (transit).
///  2. The C→Me edge fades out as its label counts down.
///  3. The Me→B edge fades out as its label counts down.
class SettlementAnim {
  const SettlementAnim({
    required this.transitFrom,
    required this.transitTo,
    required this.routedAmount,
    required this.payerEdgeDebtor,
    required this.payerEdgeCreditor,
    required this.payerNewAmount,
    required this.receiverEdgeDebtor,
    required this.receiverEdgeCreditor,
    required this.receiverNewAmount,
  });

  /// C → B: the redirect arc that appears during animation.
  final String transitFrom, transitTo;
  final double routedAmount;

  /// C → Me: the debt that fades in stage 2.
  final String payerEdgeDebtor, payerEdgeCreditor;
  final double payerNewAmount; // 0 = fully cleared

  /// Me → B: the debt that fades in stage 3.
  final String receiverEdgeDebtor, receiverEdgeCreditor;
  final double receiverNewAmount; // 0 = fully cleared
}

/// Directed debt graph showing only edges that involve [myId].
/// Optionally plays a [SettlementAnim] when [pending] is set.
class DebtGraph extends StatefulWidget {
  const DebtGraph({
    super.key,
    required this.debts,
    required this.myId,
    this.pending,
    this.onAnimationComplete,
  });

  final List<Map<String, dynamic>> debts;
  final String myId;
  final SettlementAnim? pending;
  final VoidCallback? onAnimationComplete;

  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
  static String _shorten(String s) =>
      s.length > 9 ? '${s.substring(0, 8)}…' : s;

  @override
  State<DebtGraph> createState() => _DebtGraphState();
}

class _DebtGraphState extends State<DebtGraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  );

  SettlementAnim? _running;

  @override
  void initState() {
    super.initState();
    // addStatusListener is reliable across tab/visibility changes.
    // TickerFuture.then() silently drops in IndexedStack+Visibility.maintain.
    _ctrl.addStatusListener(_onCtrlStatus);
    if (widget.pending != null) _start(widget.pending!);
  }

  @override
  void didUpdateWidget(DebtGraph old) {
    super.didUpdateWidget(old);
    if (widget.pending != null && widget.pending != old.pending) {
      _start(widget.pending!);
    }
  }

  void _onCtrlStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _running = null);
      widget.onAnimationComplete?.call();
    }
  }

  void _start(SettlementAnim anim) {
    _running = anim;
    _ctrl.reset();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Geometry helper ──────────────────────────────────────────────────────────

  static _EdgeGeom _buildGeom(
    List<Offset> positions,
    int fromIdx,
    int toIdx, {
    double nodeRadius = 22.0,
    bool transitCurve = false,
    // Where along the bezier (0=from-node, 1=to-node) to anchor the amount label.
    // Use 0.85 for outgoing-from-me edges (label near recipient node)
    // and 0.15 for incoming-to-me edges (label near sender node).
    double labelT = 0.5,
  }) {
    final from = positions[fromIdx];
    final to = positions[toIdx];
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1) {
      return _EdgeGeom(start: from, end: to, control: from, labelPos: from);
    }
    final nx = dx / dist;
    final ny = dy / dist;
    final start =
        Offset(from.dx + nx * nodeRadius, from.dy + ny * nodeRadius);
    final end = Offset(
      to.dx - nx * (nodeRadius + 7),
      to.dy - ny * (nodeRadius + 7),
    );
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final curvature = dist * 0.22;
    // s = -1 → curve left of direction (standard edges)
    // s = +1 → curve right (transit arc, visually distinct)
    final s = transitCurve ? 1.0 : -1.0;
    final control =
        Offset(mid.dx + s * ny * curvature, mid.dy - s * nx * curvature);
    // Edge bezier evaluated at labelT for label anchor.
    final lt = labelT;
    final bx = (1 - lt) * (1 - lt) * start.dx +
        2 * (1 - lt) * lt * control.dx +
        lt * lt * end.dx;
    final by = (1 - lt) * (1 - lt) * start.dy +
        2 * (1 - lt) * lt * control.dy +
        lt * lt * end.dy;
    // Small perpendicular nudge (0.15×) to separate label from the line.
    final labelPos = Offset(
      bx + s * ny * curvature * 0.15,
      by - s * nx * curvature * 0.15,
    );
    return _EdgeGeom(
        start: start, end: end, control: control, labelPos: labelPos);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    // Only render edges that directly involve the current user.
    final myDebts = widget.debts
        .where((d) =>
            d['debtor_id'] == widget.myId ||
            d['creditor_id'] == widget.myId)
        .toList();

    final nodeIds = <String>[];
    final nodeNames = <String, String>{};
    for (final d in myDebts) {
      for (final pair in [
        ('debtor_id', 'debtor_name'),
        ('creditor_id', 'creditor_name'),
      ]) {
        final id = d[pair.$1] as String;
        if (!nodeIds.contains(id)) {
          nodeIds.add(id);
          nodeNames[id] = d[pair.$2] as String;
        }
      }
    }

    if (nodeIds.length < 2) {
      return Center(
        child: Text(
          'No debts directly involving you',
          style: GoogleFonts.inter(
              fontSize: 12, color: colors.mutedForeground),
          textAlign: TextAlign.center,
        ),
      );
    }

    final nodeIndex = {
      for (int i = 0; i < nodeIds.length; i++) nodeIds[i]: i
    };
    final edges = myDebts
        .map((d) => _Edge(
              from: nodeIndex[d['debtor_id']]!,
              to: nodeIndex[d['creditor_id']]!,
              amount: d['amount'] as double,
              debtorId: d['debtor_id'] as String,
              creditorId: d['creditor_id'] as String,
            ))
        .toList();

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        const nodeR = 22.0;
        final n = nodeIds.length;
        final minR = (nodeR + 12) / sin(pi / n);
        final graphRadius =
            min(max(minR, min(w, h) * 0.28), min(w, h) * 0.42);
        final center = Offset(w / 2, h / 2 - 10);

        final positions = List.generate(n, (i) {
          final angle = 2 * pi * i / n - pi / 2;
          return Offset(
            center.dx + graphRadius * cos(angle),
            center.dy + graphRadius * sin(angle),
          );
        });

        final edgeGeom = edges.map((e) {
          // Outgoing (Me→X, I am debtor): anchor past the midpoint toward X.
          //   This spreads labels out — multiple outgoing edges won't cluster near Me.
          // Incoming (X→Me, X is debtor): anchor near X (the sender node).
          //   These are already spread since each X is a different peripheral node.
          final lt = e.debtorId == widget.myId ? 0.55 : 0.20;
          return _buildGeom(positions, e.from, e.to,
              nodeRadius: nodeR, labelT: lt);
        }).toList();

        // ── Animation staging ──────────────────────────────────────────────────
        // 0.00 – 0.45 → transit dot moves C → B
        // 0.45 – 0.72 → payer edge (C → Me) fades, label counts down
        // 0.72 – 0.97 → receiver edge (Me → B) fades, label counts down
        final anim = _running;
        final v = anim != null ? _ctrl.value : 0.0;

        double edgeAlpha(int i) {
          if (anim == null) return 1.0;
          final e = edges[i];
          if (e.debtorId == anim.payerEdgeDebtor &&
              e.creditorId == anim.payerEdgeCreditor) {
            return v < 0.45
                ? 1.0
                : (1.0 - ((v - 0.45) / 0.27).clamp(0.0, 1.0));
          }
          if (e.debtorId == anim.receiverEdgeDebtor &&
              e.creditorId == anim.receiverEdgeCreditor) {
            return v < 0.72
                ? 1.0
                : (1.0 - ((v - 0.72) / 0.25).clamp(0.0, 1.0));
          }
          return 1.0;
        }

        double edgeLabel(int i) {
          if (anim == null) return edges[i].amount;
          final e = edges[i];
          if (e.debtorId == anim.payerEdgeDebtor &&
              e.creditorId == anim.payerEdgeCreditor) {
            final p = v < 0.45
                ? 0.0
                : ((v - 0.45) / 0.27).clamp(0.0, 1.0);
            return anim.payerNewAmount + anim.routedAmount * (1.0 - p);
          }
          if (e.debtorId == anim.receiverEdgeDebtor &&
              e.creditorId == anim.receiverEdgeCreditor) {
            final p = v < 0.72
                ? 0.0
                : ((v - 0.72) / 0.25).clamp(0.0, 1.0);
            return anim.receiverNewAmount + anim.routedAmount * (1.0 - p);
          }
          return e.amount;
        }

        final transitT = anim != null
            ? (v < 0.45 ? (v / 0.45).clamp(0.0, 1.0) : 1.0)
            : 0.0;

        _EdgeGeom? transitGeom;
        if (anim != null &&
            nodeIndex.containsKey(anim.transitFrom) &&
            nodeIndex.containsKey(anim.transitTo)) {
          transitGeom = _buildGeom(
            positions,
            nodeIndex[anim.transitFrom]!,
            nodeIndex[anim.transitTo]!,
            nodeRadius: nodeR,
            transitCurve: true,
          );
        }

        // ── Stack ──────────────────────────────────────────────────────────────

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              size: Size(w, h),
              painter: _GraphPainter(
                edgeGeom: edgeGeom,
                edgeAlphas: List.generate(edges.length, edgeAlpha),
                positions: positions,
                isMe: nodeIds.map((id) => id == widget.myId).toList(),
                nodeRadius: nodeR,
                fg: colors.foreground,
                accent: colors.primary,
                transitGeom: transitGeom,
                transitT: transitT,
              ),
            ),

            // Node initials
            for (int i = 0; i < nodeIds.length; i++)
              Positioned(
                left: positions[i].dx - nodeR,
                top: positions[i].dy - nodeR,
                width: nodeR * 2,
                height: nodeR * 2,
                child: Center(
                  child: Text(
                    (nodeNames[nodeIds[i]] ?? '?')[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.foreground,
                    ),
                  ),
                ),
              ),

            // Name labels below nodes
            for (int i = 0; i < nodeIds.length; i++)
              Positioned(
                left: positions[i].dx - 44,
                top: positions[i].dy + nodeR + 4,
                width: 88,
                child: Text(
                  nodeIds[i] == widget.myId
                      ? 'You'
                      : DebtGraph._shorten(nodeNames[nodeIds[i]] ?? '?'),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: nodeIds[i] == widget.myId
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: nodeIds[i] == widget.myId
                        ? colors.foreground
                        : colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Edge amount labels — no background so nothing is obscured.
            // Soft shadow gives readability against any background.
            ...edgeGeom.asMap().entries.map((entry) {
              final i = entry.key;
              final eg = entry.value;
              final alpha = edgeAlpha(i);
              if (alpha <= 0.01) return const SizedBox.shrink();
              return Positioned(
                left: eg.labelPos.dx - 34,
                top: eg.labelPos.dy - 8,
                width: 68,
                child: Opacity(
                  opacity: (alpha * 0.9).clamp(0.0, 1.0),
                  child: Text(
                    DebtGraph._fmt.format(edgeLabel(i)),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: colors.foreground,
                      shadows: [
                        Shadow(
                            color: colors.background, blurRadius: 4),
                        Shadow(
                            color: colors.background, blurRadius: 4),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              );
            }),

            // Transit amount label — fades in as dot passes midpoint
            if (anim != null && transitGeom != null && transitT > 0.3)
              Positioned(
                left: transitGeom.labelPos.dx - 34,
                top: transitGeom.labelPos.dy - 8,
                width: 68,
                child: Opacity(
                  opacity: ((transitT - 0.3) / 0.35).clamp(0.0, 1.0),
                  child: Text(
                    DebtGraph._fmt.format(anim.routedAmount),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                      shadows: [
                        Shadow(
                            color: colors.background, blurRadius: 4),
                        Shadow(
                            color: colors.background, blurRadius: 4),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _Edge {
  const _Edge({
    required this.from,
    required this.to,
    required this.amount,
    required this.debtorId,
    required this.creditorId,
  });

  final int from, to;
  final double amount;
  final String debtorId, creditorId;
}

class _EdgeGeom {
  const _EdgeGeom({
    required this.start,
    required this.end,
    required this.control,
    required this.labelPos,
  });

  final Offset start, end, control, labelPos;
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
    required this.edgeGeom,
    required this.edgeAlphas,
    required this.positions,
    required this.isMe,
    required this.nodeRadius,
    required this.fg,
    required this.accent,
    this.transitGeom,
    this.transitT = 0.0,
  });

  final List<_EdgeGeom> edgeGeom;
  final List<double> edgeAlphas;
  final List<Offset> positions;
  final List<bool> isMe;
  final double nodeRadius;
  final Color fg, accent;
  final _EdgeGeom? transitGeom;
  final double transitT;

  @override
  void paint(Canvas canvas, Size size) {
    // Regular edges first (behind nodes).
    for (int i = 0; i < edgeGeom.length; i++) {
      _drawEdge(canvas, edgeGeom[i], edgeAlphas[i]);
    }

    // Transit arc on top of regular edges.
    if (transitGeom != null && transitT > 0) {
      _drawTransitArc(canvas, transitGeom!, transitT);
    }

    // Nodes last.
    for (int i = 0; i < positions.length; i++) {
      _drawNode(canvas, positions[i], isMe[i]);
    }
  }

  void _drawEdge(Canvas canvas, _EdgeGeom eg, double alpha) {
    if (alpha <= 0.01) return;
    final paint = Paint()
      ..color = fg.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      Path()
        ..moveTo(eg.start.dx, eg.start.dy)
        ..quadraticBezierTo(
            eg.control.dx, eg.control.dy, eg.end.dx, eg.end.dy),
      paint,
    );

    // Arrowhead using tangent at t=1 of quadratic bezier.
    final tx = 2 * (eg.end.dx - eg.control.dx);
    final ty = 2 * (eg.end.dy - eg.control.dy);
    final tLen = sqrt(tx * tx + ty * ty);
    if (tLen < 0.001) return;
    final tnx = tx / tLen;
    final tny = ty / tLen;
    const s = 7.0;
    canvas.drawPath(
      Path()
        ..moveTo(eg.end.dx, eg.end.dy)
        ..lineTo(eg.end.dx - tnx * s + tny * s * 0.4,
            eg.end.dy - tny * s - tnx * s * 0.4)
        ..lineTo(eg.end.dx - tnx * s - tny * s * 0.4,
            eg.end.dy - tny * s + tnx * s * 0.4)
        ..close(),
      Paint()..color = fg.withValues(alpha: alpha),
    );
  }

  void _drawTransitArc(Canvas canvas, _EdgeGeom eg, double t) {
    // Arc path in accent colour.
    canvas.drawPath(
      Path()
        ..moveTo(eg.start.dx, eg.start.dy)
        ..quadraticBezierTo(
            eg.control.dx, eg.control.dy, eg.end.dx, eg.end.dy),
      Paint()
        ..color = accent.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );

    // Arrowhead at end.
    final tx = 2 * (eg.end.dx - eg.control.dx);
    final ty = 2 * (eg.end.dy - eg.control.dy);
    final tLen = sqrt(tx * tx + ty * ty);
    if (tLen > 0.001) {
      final tnx = tx / tLen;
      final tny = ty / tLen;
      const s = 7.0;
      canvas.drawPath(
        Path()
          ..moveTo(eg.end.dx, eg.end.dy)
          ..lineTo(eg.end.dx - tnx * s + tny * s * 0.4,
              eg.end.dy - tny * s - tnx * s * 0.4)
          ..lineTo(eg.end.dx - tnx * s - tny * s * 0.4,
              eg.end.dy - tny * s + tnx * s * 0.4)
          ..close(),
        Paint()..color = accent.withValues(alpha: 0.55),
      );
    }

    // Animated coin dot moving along the bezier path.
    final dotT = t.clamp(0.0, 1.0);
    final dotX = (1 - dotT) * (1 - dotT) * eg.start.dx +
        2 * (1 - dotT) * dotT * eg.control.dx +
        dotT * dotT * eg.end.dx;
    final dotY = (1 - dotT) * (1 - dotT) * eg.start.dy +
        2 * (1 - dotT) * dotT * eg.control.dy +
        dotT * dotT * eg.end.dy;

    canvas.drawCircle(
        Offset(dotX, dotY), 9, Paint()..color = accent.withValues(alpha: 0.2));
    canvas.drawCircle(Offset(dotX, dotY), 5, Paint()..color = accent);
    canvas.drawCircle(
      Offset(dotX, dotY),
      5,
      Paint()
        ..color = fg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawNode(Canvas canvas, Offset pos, bool mine) {
    canvas.drawCircle(
      pos,
      nodeRadius,
      Paint()
        ..color = mine
            ? accent.withValues(alpha: 0.18)
            : fg.withValues(alpha: 0.07),
    );
    canvas.drawCircle(
      pos,
      nodeRadius,
      Paint()
        ..color = fg
        ..style = PaintingStyle.stroke
        ..strokeWidth = mine ? 2.0 : 1.5,
    );
  }

  @override
  // AnimatedBuilder drives full rebuilds — always repaint.
  bool shouldRepaint(_GraphPainter old) => true;
}
