import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_providers.dart';
import '../../providers/group_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../../core/utils/split_calculator.dart';
import '../../../domain/entities/group.dart';

class CreateTransactionScreen extends ConsumerStatefulWidget {
  const CreateTransactionScreen({super.key});

  @override
  ConsumerState<CreateTransactionScreen> createState() =>
      _CreateTransactionScreenState();
}

class _CreateTransactionScreenState
    extends ConsumerState<CreateTransactionScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isGroupExpense = true;
  bool _customSplit = false;
  bool _isSubmitting = false;
  String? _descError;
  String? _amountError;

  Group? _selectedGroup;
  List<_ParticipantEntry> _participants = [];

  // Personal IOU — recipient search
  final _personalSearchController = TextEditingController();
  List<Map<String, dynamic>> _personalSearchResults = [];
  bool _personalSearching = false;
  Map<String, dynamic>? _personalRecipient;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _personalSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final groupsAsync = ref.watch(groupListProvider);

    return Scaffold(
      backgroundColor: colors.background, // Paper
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.foreground, width: 1.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colors.foreground,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '×',
                            style: typo.lg.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'New IOU',
                          style: typo.lg.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Body ───────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 120),
                    children: [
                      // ── Amount ──────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('AMOUNT', colors),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'ETB',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 14,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[\d.]'),
                                      ),
                                    ],
                                    style: typo.xl4.copyWith(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w600,
                                      color: colors.foreground,
                                      letterSpacing: -1.12,
                                      height: 1.1,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: typo.xl4.copyWith(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w600,
                                        color: colors.mutedForeground
                                            .withValues(alpha: 0.3),
                                        letterSpacing: -1.12,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 1.5,
                              color: colors.foreground,
                              margin: const EdgeInsets.only(top: 4),
                            ),
                            if (_amountError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _amountError!,
                                  style: typo.xs.copyWith(
                                    color: colors.destructive,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // ── Details Form ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('WHAT FOR?', colors),
                            TextField(
                              controller: _descriptionController,
                              style: typo.lg.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: colors.foreground,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. Dinner at restaurant',
                                hintStyle: typo.lg.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: colors.mutedForeground.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colors.foreground,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colors.foreground,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: colors.foreground,
                                    width: 1.5,
                                  ),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                            if (_descError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _descError!,
                                  style: typo.xs.copyWith(
                                    color: colors.destructive,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),

                            // ── Type Toggle ─────────────────────────────
                            _label('CONTEXT', colors),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colors.foreground,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _isGroupExpense = true,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isGroupExpense
                                              ? colors.foreground
                                              : Colors.transparent,
                                          border: Border(
                                            right: BorderSide(
                                              color: colors.foreground,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Group',
                                          style: typo.lg.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _isGroupExpense
                                                ? colors.background
                                                : colors.foreground,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _isGroupExpense = false;
                                        _selectedGroup = null;
                                        _participants = [];
                                        _personalRecipient = null;
                                        _personalSearchResults = [];
                                        _personalSearchController.clear();
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !_isGroupExpense
                                              ? colors.foreground
                                              : Colors.transparent,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Personal',
                                          style: typo.lg.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: !_isGroupExpense
                                                ? colors.background
                                                : colors.foreground,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            if (!_isGroupExpense) ...[
                              _label('WITH WHOM?', colors),
                              const SizedBox(height: 8),
                              if (_personalRecipient != null)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: colors.card,
                                    border: Border.all(color: colors.foreground, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32, height: 32,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: colors.foreground, width: 1.2),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          (_personalRecipient!['display_name'] as String? ?? '?')[0].toUpperCase(),
                                          style: typo.lg.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: colors.foreground),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _personalRecipient!['display_name'] as String? ?? 'User',
                                          style: typo.sm.copyWith(fontWeight: FontWeight.w600, color: colors.foreground),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _personalRecipient = null;
                                          _participants = [];
                                        }),
                                        child: Icon(FIcons.x, size: 18, color: colors.mutedForeground),
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                TextField(
                                  controller: _personalSearchController,
                                  style: typo.sm.copyWith(color: colors.foreground, fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: 'Search by name...',
                                    hintStyle: typo.sm.copyWith(
                                      fontSize: 16,
                                      color: colors.mutedForeground.withValues(alpha: 0.5),
                                    ),
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(color: colors.foreground, width: 1.5),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: colors.foreground, width: 1.5),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: colors.foreground, width: 1.5),
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    suffixIcon: _personalSearching
                                        ? Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: SizedBox(
                                              width: 16, height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: colors.mutedForeground),
                                            ),
                                          )
                                        : null,
                                  ),
                                  onChanged: _searchPersonalRecipient,
                                ),
                                if (_personalSearchResults.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colors.card,
                                      border: Border.all(color: colors.foreground, width: 1.5),
                                    ),
                                    child: Column(
                                      children: List.generate(_personalSearchResults.length, (i) {
                                        final profile = _personalSearchResults[i];
                                        final name = profile['display_name'] as String? ?? 'User';
                                        return GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => _setPersonalRecipient(profile),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              border: i == 0 ? null : Border(
                                                top: BorderSide(color: colors.foreground, width: 1.0),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 32, height: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: colors.foreground, width: 1.2),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    name[0].toUpperCase(),
                                                    style: typo.lg.copyWith(fontSize: 12, color: colors.foreground),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(name, style: typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground)),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ],
                            ],

                            if (_isGroupExpense) ...[
                              _label('SELECT GROUP', colors),
                              const SizedBox(height: 8),
                              groupsAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                                error: (e, _) => Text('Error: $e'),
                                data: (groups) {
                                  if (groups.isEmpty)
                                    return const Text(
                                      'No groups yet. Create one first.',
                                    );
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: colors.card,
                                      border: Border.all(
                                        color: colors.foreground,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: List.generate(groups.length, (
                                        i,
                                      ) {
                                        final group = groups[i];
                                        final isSelected =
                                            _selectedGroup?.id == group.id;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(
                                              () => _selectedGroup = group,
                                            );
                                            _loadGroupMembers(group.id);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              border: i == 0
                                                  ? null
                                                  : Border(
                                                      top: BorderSide(
                                                        color:
                                                            colors.foreground,
                                                        width: 1.0,
                                                      ),
                                                    ),
                                              color: isSelected
                                                  ? colors.primary.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.transparent,
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: colors.foreground,
                                                      width: 1.2,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    group.name.isNotEmpty
                                                        ? group.name[0]
                                                              .toUpperCase()
                                                        : '?',
                                                    style: typo.lg.copyWith(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: colors.foreground,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    group.name,
                                                    style: typo.sm.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: colors.foreground,
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check,
                                                    size: 18,
                                                    color: colors.foreground,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Participants ────────────────────────────────────
                      if (_participants.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: _label('SPLIT WITH', colors),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 22),
                          decoration: BoxDecoration(
                            color: colors.card,
                            border: Border.all(
                              color: colors.foreground,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: List.generate(_participants.length, (i) {
                              final p = _participants[i];
                              return _participantRow(p, i == 0, colors, typo);
                            }),
                          ),
                        ),

                        // ── Split Method Toggle ──────────────────────────
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: _label('SPLIT METHOD', colors),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 22),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colors.foreground,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _customSplit = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !_customSplit
                                          ? colors.foreground
                                          : Colors.transparent,
                                      border: Border(
                                        right: BorderSide(
                                          color: colors.foreground,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Equal',
                                      style: typo.lg.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: !_customSplit
                                            ? colors.background
                                            : colors.foreground,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _customSplit = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _customSplit
                                          ? colors.foreground
                                          : Colors.transparent,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Exact',
                                      style: typo.lg.copyWith(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _customSplit
                                            ? colors.background
                                            : colors.foreground,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // ── Fixed Bottom Actions ────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                decoration: BoxDecoration(
                  color: colors.background, // Paper
                  border: Border(
                    top: BorderSide(color: colors.foreground, width: 1.5),
                  ),
                ),
                child: GestureDetector(
                  onTap: _isSubmitting ? null : _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: colors.primary, // Accent
                      border: Border.all(color: colors.foreground, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: colors.foreground,
                          offset: const Offset(4, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: colors.foreground,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Send IOU · ETB ${_amountController.text.isNotEmpty ? _amountController.text : "0.00"}',
                            style: typo.lg.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, FColors colors) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: colors.mutedForeground,
    ),
  );

  Widget _participantRow(
    _ParticipantEntry p,
    bool isFirst,
    FColors colors,
    FTypography typo,
  ) {
    if (p.isPayer) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : Border(top: BorderSide(color: colors.foreground, width: 1.0)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: colors.foreground, width: 1.2),
              ),
              alignment: Alignment.center,
              child: Text(
                p.displayName[0].toUpperCase(),
                style: typo.lg.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${p.displayName} (You)',
                style: typo.sm.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              'Paying',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }

    final amountCtl = TextEditingController(
      text: p.customAmount?.toStringAsFixed(2) ?? '',
    );
    amountCtl.addListener(
      () => p.customAmount = double.tryParse(amountCtl.text),
    );

    return GestureDetector(
      onTap: () {
        if (!_customSplit) setState(() => p.included = !p.included);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: isFirst
              ? null
              : Border(top: BorderSide(color: colors.foreground, width: 1.0)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: colors.foreground, width: 1.2),
              ),
              alignment: Alignment.center,
              child: Text(
                p.displayName[0].toUpperCase(),
                style: typo.lg.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                p.displayName,
                style: typo.sm.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (_customSplit)
              SizedBox(
                width: 80,
                child: TextField(
                  controller: amountCtl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  textAlign: TextAlign.right,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: colors.foreground,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Amount',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: colors.mutedForeground,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              )
            else
              Text(
                _equalSplitPreview(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: colors.foreground,
                ),
              ),
            const SizedBox(width: 12),
            if (!_customSplit)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: p.included ? colors.primary : Colors.transparent,
                  border: Border.all(color: colors.foreground, width: 1.5),
                ),
                alignment: Alignment.center,
                child: p.included
                    ? Text(
                        '✓',
                        style: typo.lg.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  String _equalSplitPreview() {
    final total = double.tryParse(_amountController.text.trim());
    final n = _participants.where((p) => p.included).length;
    if (total == null || total <= 0 || n < 2) return '—';
    final perPerson = (total / n * 100).round() / 100;
    return perPerson.toStringAsFixed(2);
  }

  Future<void> _loadGroupMembers(String groupId) async {
    try {
      final members = await ref.read(groupMembersProvider(groupId).future);
      final client = ref.read(supabaseClientProvider);
      final currentUserId = client.auth.currentUser?.id;
      final entries = <_ParticipantEntry>[];
      for (final member in members) {
        String displayName = 'User';
        try {
          final profile = await client
              .from('profiles')
              .select('display_name')
              .eq('id', member.userId)
              .maybeSingle();
          if (profile != null && profile['display_name'] != null)
            displayName = profile['display_name'] as String;
        } catch (_) {}
        final isPayer = member.userId == currentUserId;
        if (isPayer) displayName = 'You';
        entries.add(
          _ParticipantEntry(
            userId: member.userId,
            displayName: displayName,
            isPayer: isPayer,
          ),
        );
      }
      setState(() => _participants = entries);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _searchPersonalRecipient(String query) async {
    if (query.trim().length < 2) {
      setState(() => _personalSearchResults = []);
      return;
    }
    setState(() => _personalSearching = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final currentUserId = client.auth.currentUser?.id;
      final data = await client
          .from('profiles')
          .select('id, display_name')
          .ilike('display_name', '%${query.trim()}%')
          .neq('id', currentUserId!)
          .limit(8);
      setState(() {
        _personalSearchResults = List<Map<String, dynamic>>.from(data as List);
        _personalSearching = false;
      });
    } catch (_) {
      setState(() => _personalSearching = false);
    }
  }

  Future<void> _setPersonalRecipient(Map<String, dynamic> profile) async {
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    String myName = 'You';
    try {
      final myProfile = await client
          .from('profiles')
          .select('display_name')
          .eq('id', currentUserId!)
          .maybeSingle();
      if (myProfile != null) myName = myProfile['display_name'] as String? ?? 'You';
    } catch (_) {}
    setState(() {
      _personalRecipient = profile;
      _personalSearchController.clear();
      _personalSearchResults = [];
      _participants = [
        _ParticipantEntry(userId: currentUserId!, displayName: myName, isPayer: true),
        _ParticipantEntry(
          userId: profile['id'] as String,
          displayName: profile['display_name'] as String? ?? 'User',
        ),
      ];
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    _isSubmitting = true;

    setState(() {
      _descError = null;
      _amountError = null;
    });

    final description = _descriptionController.text.trim();
    final amountText = _amountController.text.trim();

    if (description.isEmpty) {
      setState(() {
        _isSubmitting = false;
        _descError = 'Description is required';
      });
      return;
    }

    final totalAmount = double.tryParse(amountText);
    if (totalAmount == null || totalAmount <= 0) {
      setState(() {
        _isSubmitting = false;
        _amountError = 'Enter a valid amount';
      });
      return;
    }

    if (!_isGroupExpense && _personalRecipient == null) {
      setState(() => _isSubmitting = false);
      _snack('Select who this IOU is with');
      return;
    }

    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final others = _participants
        .where((p) => p.included && !p.isPayer)
        .toList();

    if (others.isEmpty) {
      setState(() => _isSubmitting = false);
      _snack('Add at least one other participant');
      return;
    }

    setState(() {});

    final maps = <Map<String, dynamic>>[];

    if (_customSplit) {
      double sum = 0;
      for (final p in others) {
        final amt = p.customAmount ?? 0;
        if (amt <= 0) {
          _snack('Enter an amount for ${p.displayName}');
          setState(() => _isSubmitting = false);
          return;
        }
        sum += amt;
      }
      if ((sum - totalAmount).abs() > 0.01) {
        _snack(
          'Split amounts (${sum.toStringAsFixed(2)}) must equal total (${totalAmount.toStringAsFixed(2)})',
        );
        setState(() => _isSubmitting = false);
        return;
      }
      for (final p in others) {
        maps.add({'user_id': p.userId, 'amount_due': p.customAmount!});
      }
    } else {
      final allIncluded = _participants.where((p) => p.included).toList();
      maps.addAll(equalSplit(
        totalAmount: totalAmount,
        totalParticipants: allIncluded.length,
        otherUserIds: others.map((p) => p.userId).toList(),
      ));
    }

    try {
      await ref
          .read(transactionRepositoryProvider)
          .createTransaction(
            groupId: _selectedGroup?.id,
            payerId: currentUserId,
            totalAmount: totalAmount,
            description: description,
            participants: maps,
          );
      ref.invalidate(transactionListProvider);
      if (mounted) {
        // Just pop since success is obvious, or show snackbar
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction created')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final colors = context.theme.colors;
        final typo = context.theme.typography;
        await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(22),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border.all(color: colors.foreground, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.foreground,
                    offset: const Offset(6, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Failed to create',
                    style: typo.lg.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: colors.foreground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$e',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colors.mutedForeground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: colors.foreground, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'OK',
                        style: typo.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground,
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
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _ParticipantEntry {
  _ParticipantEntry({
    required this.userId,
    required this.displayName,
    this.isPayer = false,
  });
  final String userId;
  final String displayName;
  final bool isPayer;
  bool included = true;
  double? customAmount;
}
