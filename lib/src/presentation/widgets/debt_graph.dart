import 'dart:math';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Directed graph showing who owes whom within a group.
/// Nodes = members, arrows = debt direction (debtor → creditor).
class DebtGraph extends StatelessWidget {
  const DebtGraph({
    super.key,
    required this.debts,
    required this.myId,
  });

  final List<Map<String, dynamic>> debts;
  final String myId;

  static final _fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    // Collect unique ordered node list.
    final nodeIds = <String>[];
    final nodeNames = <String, String>{};
    for (final d in debts) {
      for (final key in [('debtor_id', 'debtor_name'), ('creditor_id', 'creditor_name')]) {
        final id = d[key.$1] as String;
        if (!nodeIds.contains(id)) {
          nodeIds.add(id);
          nodeNames[id] = d[key.$2] as String;
        }
      }
    }

    if (nodeIds.length < 2) return const SizedBox.shrink();

    final nodeIndex = {for (int i = 0; i < nodeIds.length; i++) nodeIds[i]: i};
    final edges = debts
        .map((d) => _Edge(
              from: nodeIndex[d['debtor_id']]!,
              to: nodeIndex[d['creditor_id']]!,
              amount: d['amount'] as double,
            ))
        .toList();

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      const nodeRadius = 22.0;
      final n = nodeIds.length;
      // Minimum radius that keeps adjacent node edges ≥ 12 px apart.
      final minR = (nodeRadius + 12) / sin(pi / n);
      // Allow up to 42 % of the shorter axis, but never less than minR.
      final graphRadius = min(max(minR, min(w, h) * 0.28), min(w, h) * 0.42);
      // Shift centre up so the bottom-node label doesn't clip.
      final center = Offset(w / 2, h / 2 - 10);

      final positions = List.generate(nodeIds.length, (i) {
        final angle = 2 * pi * i / nodeIds.length - pi / 2;
        return Offset(
          center.dx + graphRadius * cos(angle),
          center.dy + graphRadius * sin(angle),
        );
      });

      // Precompute bezier geometry for each edge.
      final edgeGeom = <_EdgeGeom>[];
      for (final e in edges) {
        final from = positions[e.from];
        final to = positions[e.to];
        final dx = to.dx - from.dx;
        final dy = to.dy - from.dy;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 1) continue;
        final nx = dx / dist;
        final ny = dy / dist;
        final start = Offset(from.dx + nx * nodeRadius, from.dy + ny * nodeRadius);
        final end = Offset(
          to.dx - nx * (nodeRadius + 7),
          to.dy - ny * (nodeRadius + 7),
        );
        final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        final curvature = dist * 0.22;
        final control = Offset(mid.dx - ny * curvature, mid.dy + nx * curvature);
        // bezier at t=0.5 + slight perp offset for label
        const t = 0.5;
        final bx = (1 - t) * (1 - t) * start.dx + 2 * (1 - t) * t * control.dx + t * t * end.dx;
        final by = (1 - t) * (1 - t) * start.dy + 2 * (1 - t) * t * control.dy + t * t * end.dy;
        final labelPos = Offset(bx - ny * curvature * 0.35, by + nx * curvature * 0.35);
        edgeGeom.add(_EdgeGeom(edge: e, start: start, end: end, control: control, labelPos: labelPos));
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // Lines + arrowheads
          CustomPaint(
            size: Size(w, h),
            painter: _GraphPainter(
              edgeGeom: edgeGeom,
              positions: positions,
              isMe: nodeIds.map((id) => id == myId).toList(),
              nodeRadius: nodeRadius,
              fg: colors.foreground,
              accent: colors.primary,
            ),
          ),

          // Node initials (centered on each node)
          for (int i = 0; i < nodeIds.length; i++)
            Positioned(
              left: positions[i].dx - nodeRadius,
              top: positions[i].dy - nodeRadius,
              width: nodeRadius * 2,
              height: nodeRadius * 2,
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

          // Name labels below each node
          for (int i = 0; i < nodeIds.length; i++)
            Positioned(
              left: positions[i].dx - 44,
              top: positions[i].dy + nodeRadius + 4,
              width: 88,
              child: Text(
                nodeIds[i] == myId
                    ? 'You'
                    : _shorten(nodeNames[nodeIds[i]] ?? '?'),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: nodeIds[i] == myId ? FontWeight.w700 : FontWeight.w500,
                  color: nodeIds[i] == myId
                      ? colors.foreground
                      : colors.mutedForeground,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Amount labels on edges
          for (final eg in edgeGeom)
            Positioned(
              left: eg.labelPos.dx - 34,
              top: eg.labelPos.dy - 11,
              width: 68,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.background,
                  border: Border.all(color: colors.foreground, width: 1),
                ),
                child: Text(
                  _fmt.format(eg.edge.amount),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ),
        ],
      );
    });
  }

  static String _shorten(String s) =>
      s.length > 9 ? '${s.substring(0, 8)}…' : s;
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _Edge {
  const _Edge({required this.from, required this.to, required this.amount});
  final int from, to;
  final double amount;
}

class _EdgeGeom {
  const _EdgeGeom({
    required this.edge,
    required this.start,
    required this.end,
    required this.control,
    required this.labelPos,
  });
  final _Edge edge;
  final Offset start, end, control, labelPos;
}

// ── Painter ───────────────────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
    required this.edgeGeom,
    required this.positions,
    required this.isMe,
    required this.nodeRadius,
    required this.fg,
    required this.accent,
  });

  final List<_EdgeGeom> edgeGeom;
  final List<Offset> positions;
  final List<bool> isMe;
  final double nodeRadius;
  final Color fg, accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Edges first (so nodes sit on top).
    for (final eg in edgeGeom) {
      _drawEdge(canvas, eg);
    }
    // Node circles.
    for (int i = 0; i < positions.length; i++) {
      _drawNode(canvas, positions[i], isMe[i]);
    }
  }

  void _drawEdge(Canvas canvas, _EdgeGeom eg) {
    final linePaint = Paint()
      ..color = fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(eg.start.dx, eg.start.dy)
      ..quadraticBezierTo(eg.control.dx, eg.control.dy, eg.end.dx, eg.end.dy);
    canvas.drawPath(path, linePaint);

    // Arrowhead: tangent direction at t=1 of quadratic bezier.
    final tx = 2 * (eg.end.dx - eg.control.dx);
    final ty = 2 * (eg.end.dy - eg.control.dy);
    final tLen = sqrt(tx * tx + ty * ty);
    if (tLen < 0.001) return;
    final tnx = tx / tLen;
    final tny = ty / tLen;
    const s = 7.0;
    final arrowPath = Path()
      ..moveTo(eg.end.dx, eg.end.dy)
      ..lineTo(eg.end.dx - tnx * s + tny * s * 0.4, eg.end.dy - tny * s - tnx * s * 0.4)
      ..lineTo(eg.end.dx - tnx * s - tny * s * 0.4, eg.end.dy - tny * s + tnx * s * 0.4)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = fg);
  }

  void _drawNode(Canvas canvas, Offset pos, bool mine) {
    canvas.drawCircle(
      pos,
      nodeRadius,
      Paint()..color = mine ? accent.withValues(alpha: 0.18) : fg.withValues(alpha: 0.07),
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
  bool shouldRepaint(_GraphPainter old) =>
      old.edgeGeom != edgeGeom ||
      old.positions != positions ||
      old.isMe != isMe;
}
