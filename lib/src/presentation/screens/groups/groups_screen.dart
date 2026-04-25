import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/group_member.dart';
import '../../providers/group_providers.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final groupsAsync = ref.watch(groupListProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Groups',
                      style: typo.xl2.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCreateGroupDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        border:
                            Border.all(color: colors.foreground, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: colors.foreground,
                              offset: const Offset(2, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(FIcons.plus, size: 16, color: colors.foreground),
                          const SizedBox(width: 6),
                          Text(
                            'New group',
                            style: typo.sm.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Content ────────────────────────────────────────────────────
              Expanded(
                child: groupsAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator.adaptive()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FIcons.circleAlert,
                            size: 36, color: colors.destructive),
                        const SizedBox(height: 12),
                        Text('Something went wrong',
                            style: GoogleFonts.inter(
                                color: colors.mutedForeground)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => ref.invalidate(groupListProvider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: colors.foreground, width: 1.5),
                            ),
                            child: Text(
                              'Retry',
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
                  data: (groups) {
                    if (groups.isEmpty) {
                      return _emptyState(colors, typo);
                    }

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        // Stat cards
                        Row(
                          children: [
                            _statCard('${groups.length}', 'Total groups',
                                colors, typo),
                            const SizedBox(width: 12),
                            Consumer(builder: (context, ref, _) {
                              final count = ref
                                      .watch(pendingInvitationsProvider)
                                      .whenOrNull(
                                          data: (list) => list.length) ??
                                  0;
                              return _statCard(
                                  '$count', 'Pending', colors, typo);
                            }),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Invitations inbox
                        Consumer(builder: (context, ref, _) {
                          final invites =
                              ref.watch(pendingInvitationsProvider).valueOrNull;
                          if (invites == null || invites.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INVITATIONS',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: colors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...invites.map((inv) => _InvitationTile(
                                    invitation: inv,
                                    onAccept: () async {
                                      await ref
                                          .read(groupRepositoryProvider)
                                          .acceptInvitation(
                                              inv.member.groupId);
                                      ref.invalidate(
                                          pendingInvitationsProvider);
                                      ref.invalidate(groupListProvider);
                                    },
                                    onDecline: () async {
                                      await ref
                                          .read(groupRepositoryProvider)
                                          .declineInvitation(
                                              inv.member.groupId);
                                      ref.invalidate(
                                          pendingInvitationsProvider);
                                    },
                                  )),
                              const SizedBox(height: 24),
                            ],
                          );
                        }),

                        // Group tiles
                        Container(
                          decoration: BoxDecoration(
                            color: colors.card,
                            border: Border.all(
                                color: colors.foreground, width: 1.5),
                          ),
                          child: Column(
                            children: List.generate(groups.length, (i) {
                              final g = groups[i];
                              return GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GroupDetailScreen(
                                        groupId: g.id, groupName: g.name),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: i == 0
                                        ? null
                                        : Border(
                                            top: BorderSide(
                                                color: colors.foreground,
                                                width: 1.0)),
                                  ),
                                  child: Row(
                                    children: [
                                      _avatarBox(g.name, colors, typo),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              g.name,
                                              style: typo.lg.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: colors.foreground,
                                              ),
                                            ),
                                            if (g.description != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                g.description!,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: colors.mutedForeground,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(FIcons.chevronRight,
                                          size: 16, color: colors.foreground),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(FColors colors, FTypography typo) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(color: colors.foreground, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(FIcons.users, size: 30, color: colors.foreground),
          ),
          const SizedBox(height: 20),
          Text(
            'No groups yet',
            style: typo.lg.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create one to track shared expenses',
            style: GoogleFonts.inter(color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String value, String label, FColors colors, FTypography typo) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.foreground, width: 1.5),
          boxShadow: [
            BoxShadow(color: colors.foreground, offset: const Offset(2, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: typo.xl3.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: colors.foreground,
                letterSpacing: -0.64,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarBox(String name, FColors colors, FTypography typo) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: colors.foreground, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: typo.lg.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(22),
        child: _CreateGroupForm(),
      ),
    );
  }
}

// ── _InvitationTile ─────────────────────────────────────────────────────────

class _InvitationTile extends ConsumerStatefulWidget {
  const _InvitationTile({
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  });

  final ({GroupMember member, String groupName}) invitation;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  @override
  ConsumerState<_InvitationTile> createState() => _InvitationTileState();
}

class _InvitationTileState extends ConsumerState<_InvitationTile> {
  bool _responding = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _responding = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final groupName = widget.invitation.groupName;
    final initial = groupName.isNotEmpty ? groupName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.foreground, width: 1.5),
        boxShadow: [
          BoxShadow(color: colors.foreground, offset: const Offset(3, 3)),
        ],
      ),
      child: Row(
        children: [
          // Group avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: colors.foreground, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: typo.lg.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Group info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: typo.sm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "You've been invited to join",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Decline
          GestureDetector(
            onTap: _responding ? null : () => _run(widget.onDecline),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: colors.foreground, width: 1.5),
              ),
              child: Text(
                'Decline',
                style: typo.xs.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Accept
          GestureDetector(
            onTap: _responding ? null : () => _run(widget.onAccept),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary,
                border: Border.all(color: colors.foreground, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: colors.foreground,
                      offset: const Offset(2, 2)),
                ],
              ),
              child: _responding
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: colors.foreground, strokeWidth: 2),
                    )
                  : Text(
                      'Accept',
                      style: typo.xs.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _CreateGroupForm ─────────────────────────────────────────────────────────

class _CreateGroupForm extends ConsumerStatefulWidget {
  const _CreateGroupForm();

  @override
  ConsumerState<_CreateGroupForm> createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends ConsumerState<_CreateGroupForm> {
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.foreground, width: 1.5),
        boxShadow: [
          BoxShadow(color: colors.foreground, offset: const Offset(6, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create group',
            style: typo.lg.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a new group to track shared expenses.',
            style: GoogleFonts.inter(fontSize: 13, color: colors.mutedForeground),
          ),
          const SizedBox(height: 24),
          _label('NAME', colors),
          const SizedBox(height: 4),
          _field(_nameCtl, 'e.g. Work trip, Roommates', colors, typo),
          const SizedBox(height: 16),
          _label('DESCRIPTION (OPTIONAL)', colors),
          const SizedBox(height: 4),
          _field(_descCtl, 'What is this group for?', colors, typo,
              minLines: 2, maxLines: 3),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _loading ? null : _submit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: colors.primary,
                border: Border.all(color: colors.foreground, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: colors.foreground, offset: const Offset(3, 3)),
                ],
              ),
              alignment: Alignment.center,
              child: _loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: colors.foreground, strokeWidth: 2))
                  : Text(
                      'Create',
                      style: typo.sm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.foreground),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _loading ? null : () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: colors.foreground, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                'Cancel',
                style: typo.sm.copyWith(
                    fontWeight: FontWeight.w600, color: colors.foreground),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, FColors colors) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: colors.mutedForeground,
        ),
      );

  Widget _field(
    TextEditingController ctl,
    String hint,
    FColors colors,
    FTypography typo, {
    int minLines = 1,
    int maxLines = 1,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: colors.foreground, width: 1.5),
    );
    return TextField(
      controller: ctl,
      enabled: !_loading,
      minLines: minLines,
      maxLines: maxLines,
      style:
          typo.sm.copyWith(fontWeight: FontWeight.w500, color: colors.foreground),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: typo.sm
            .copyWith(color: colors.mutedForeground.withValues(alpha: 0.5)),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        isDense: true,
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(groupRepositoryProvider).createGroup(
            name: name,
            description: _descCtl.text.trim().isNotEmpty
                ? _descCtl.text.trim()
                : null,
          );
      ref.invalidate(groupListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
