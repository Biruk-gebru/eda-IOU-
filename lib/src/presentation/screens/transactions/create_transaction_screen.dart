import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/auth_providers.dart';
import '../../providers/group_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../../domain/entities/group.dart';

class CreateTransactionScreen extends ConsumerStatefulWidget {
  const CreateTransactionScreen({super.key});

  @override
  ConsumerState<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends ConsumerState<CreateTransactionScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isGroupExpense = true;
  bool _customSplit = false;
  bool _isSubmitting = false;

  Group? _selectedGroup;
  List<_ParticipantEntry> _participants = [];

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final groupsAsync = ref.watch(groupListProvider);

    return FScaffold(
      header: FHeader.nested(
        title: const Text('New Transaction'),
        prefixes: [FHeaderAction.back(onPress: () => Navigator.of(context).pop())],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type toggle: Group / Personal ─────────────────────────────
            _sectionLabel('TYPE', colors, typo),
            const SizedBox(height: 10),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: colors.secondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  _typeTab('Group', _isGroupExpense, FIcons.users,
                      () => setState(() => _isGroupExpense = true), colors, typo),
                  _typeTab('Personal', !_isGroupExpense, FIcons.user,
                      () => setState(() { _isGroupExpense = false; _selectedGroup = null; _participants = []; }),
                      colors, typo),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Group selector ────────────────────────────────────────────
            if (_isGroupExpense) ...[
              _sectionLabel('SELECT GROUP', colors, typo),
              const SizedBox(height: 10),
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return FAlert(
                      icon: const Icon(FIcons.info),
                      title: const Text('No groups yet'),
                      subtitle: const Text('Create a group first to make group transactions.'),
                    );
                  }
                  return FTileGroup(
                    children: [
                      for (final group in groups)
                        FTile(
                          prefix: _avatarCircle(group.name, colors, typo),
                          title: Text(group.name),
                          subtitle: group.description != null ? Text(group.description!) : null,
                          selected: _selectedGroup?.id == group.id,
                          suffix: _selectedGroup?.id == group.id
                              ? Icon(FIcons.check, size: 16, color: colors.foreground)
                              : Icon(FIcons.chevronRight, size: 14, color: colors.border),
                          onPress: () { setState(() => _selectedGroup = group); _loadGroupMembers(group.id); },
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: FCircularProgress()),
                error: (e, _) => FAlert(
                  variant: FAlertVariant.destructive,
                  icon: const Icon(FIcons.circleAlert),
                  title: const Text('Error loading groups'),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Description ───────────────────────────────────────────────
            _sectionLabel('DESCRIPTION', colors, typo),
            const SizedBox(height: 10),
            FTextField(
              control: FTextFieldControl.managed(controller: _descriptionController),
              hint: 'e.g. Dinner at restaurant',
              prefixBuilder: (context, style, variants) =>
                  FTextField.prefixIconBuilder(context, style, variants, const Icon(FIcons.fileText)),
            ),

            const SizedBox(height: 16),

            // ── Amount ─────────────────────────────────────────────────────
            _sectionLabel('AMOUNT (ETB)', colors, typo),
            const SizedBox(height: 10),
            FTextField(
              control: FTextFieldControl.managed(controller: _amountController),
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              prefixBuilder: (context, style, variants) =>
                  FTextField.prefixIconBuilder(context, style, variants, const Icon(FIcons.coins)),
            ),

            const SizedBox(height: 16),

            // ── Split ──────────────────────────────────────────────────────
            FSwitch(
              label: const Text('Custom split'),
              description: const Text('Toggle for unequal amounts'),
              value: _customSplit,
              onChange: (v) => setState(() => _customSplit = v),
            ),

            // ── Participants ───────────────────────────────────────────────
            if (_participants.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionLabel('PARTICIPANTS', colors, typo),
              const SizedBox(height: 10),
              FTileGroup(
                children: [for (final p in _participants) _participantTile(p, colors, typo)],
              ),
            ],

            const SizedBox(height: 20),

            // ── Approval rules info ────────────────────────────────────────
            FAlert(
              icon: const Icon(FIcons.info),
              title: const Text('Auto-approval rules'),
              subtitle: const Text(
                  'Majority of participants must approve within 48 h. Auto-cancels if no response.'),
            ),

            const SizedBox(height: 28),

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: _isSubmitting ? null : _submit,
                prefix: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: FCircularProgress())
                    : const Icon(FIcons.send),
                child: const Text('Submit for approval'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(String label, bool selected, IconData icon, VoidCallback onTap, FColors colors, FTypography typo) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? colors.card : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? colors.foreground : colors.mutedForeground),
              const SizedBox(width: 6),
              Text(label,
                  style: typo.sm.copyWith(
                    color: selected ? colors.foreground : colors.mutedForeground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  FTile _participantTile(_ParticipantEntry p, FColors colors, FTypography typo) {
    final amountCtl = TextEditingController(text: p.customAmount?.toStringAsFixed(2) ?? '');
    return FTile(
      prefix: FCheckbox(
        value: p.included,
        onChange: (v) => setState(() => p.included = v),
      ),
      title: Text(p.displayName, style: typo.sm.copyWith(fontWeight: FontWeight.w500)),
      subtitle: _customSplit
          ? SizedBox(
              width: 110,
              height: 36,
              child: TextField(
                controller: amountCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: typo.sm.copyWith(color: colors.foreground),
                decoration: InputDecoration(
                  hintText: 'Amount',
                  hintStyle: typo.sm.copyWith(color: colors.mutedForeground),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
                onChanged: (v) => p.customAmount = double.tryParse(v),
              ),
            )
          : Text(p.isPayer ? 'Payer' : 'Equal split',
              style: typo.xs.copyWith(color: colors.mutedForeground)),
      suffix: p.isPayer ? Icon(FIcons.wallet, size: 14, color: colors.mutedForeground) : null,
    );
  }

  Widget _avatarCircle(String name, FColors colors, FTypography typo) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: Text(initial, style: typo.xs.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
    );
  }

  Widget _sectionLabel(String text, FColors colors, FTypography typo) => Text(
        text,
        style: typo.xs.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.mutedForeground,
          letterSpacing: 0.8,
        ),
      );

  Future<void> _loadGroupMembers(String groupId) async {
    try {
      final members = await ref.read(groupMembersProvider(groupId).future);
      final client = ref.read(supabaseClientProvider);
      final currentUserId = client.auth.currentUser?.id;
      final entries = <_ParticipantEntry>[];
      for (final member in members) {
        String displayName = 'User';
        try {
          final profile = await client.from('profiles').select('display_name').eq('id', member.userId).maybeSingle();
          if (profile != null && profile['display_name'] != null) displayName = profile['display_name'] as String;
        } catch (_) {}
        final isPayer = member.userId == currentUserId;
        if (isPayer) displayName = 'You';
        entries.add(_ParticipantEntry(userId: member.userId, displayName: displayName, isPayer: isPayer));
      }
      setState(() => _participants = entries);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    final amountText = _amountController.text.trim();
    if (description.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a description'))); return; }
    final totalAmount = double.tryParse(amountText);
    if (totalAmount == null || totalAmount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount'))); return; }
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return;
    final included = _participants.where((p) => p.included).toList();
    final maps = <Map<String, dynamic>>[];
    if (_customSplit) {
      for (final p in included) maps.add({'user_id': p.userId, 'amount_due': p.customAmount ?? 0.0});
    } else {
      final split = included.isNotEmpty ? totalAmount / included.length : totalAmount;
      for (final p in included) maps.add({'user_id': p.userId, 'amount_due': split});
    }
    if (maps.isEmpty) maps.add({'user_id': currentUserId, 'amount_due': totalAmount});
    setState(() => _isSubmitting = true);
    try {
      await ref.read(transactionRepositoryProvider).createTransaction(
          groupId: _selectedGroup?.id, payerId: currentUserId, totalAmount: totalAmount, description: description, participants: maps);
      ref.invalidate(transactionListProvider);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction created'))); Navigator.of(context).pop(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ParticipantEntry {
  _ParticipantEntry({required this.userId, required this.displayName, this.isPayer = false});
  final String userId;
  final String displayName;
  final bool isPayer;
  bool included = true;
  double? customAmount;
}
