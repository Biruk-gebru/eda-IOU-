import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:google_fonts/google_fonts.dart';

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Groups',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                ),
              ),
              FButton(
                onPress: () => _showCreateGroupDialog(context),
                prefix: const Icon(FIcons.plus),
                child: const Text('New group'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(child: FCircularProgress()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FIcons.circleAlert, size: 36, color: colors.destructive),
                    const SizedBox(height: 12),
                    Text('Something went wrong',
                        style: typo.sm.copyWith(color: colors.mutedForeground)),
                    const SizedBox(height: 16),
                    FButton(
                      variant: FButtonVariant.outline,
                      onPress: () => ref.invalidate(groupListProvider),
                      prefix: const Icon(FIcons.refreshCw),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: colors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.border),
                          ),
                          child: Icon(FIcons.users, size: 30, color: colors.mutedForeground),
                        ),
                        const SizedBox(height: 16),
                        Text('No groups yet',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: colors.foreground,
                            )),
                        const SizedBox(height: 6),
                        Text('Create one to track shared expenses',
                            style: typo.sm.copyWith(color: colors.mutedForeground)),
                        const SizedBox(height: 24),
                        FButton(
                          onPress: () => _showCreateGroupDialog(context),
                          prefix: const Icon(FIcons.plus),
                          child: const Text('Create group'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // Mini-stats row
                    Row(
                      children: [
                        _statCard('${groups.length}', 'Total groups', FIcons.users, colors, typo),
                        const SizedBox(width: 12),
                        _statCard('0', 'Pending', FIcons.clock, colors, typo),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Group tiles
                    FTileGroup(
                      children: [
                        for (final g in groups)
                          FTile(
                            prefix: _avatarCircle(g.name, colors, typo),
                            title: Text(g.name,
                                style: typo.sm
                                    .copyWith(fontWeight: FontWeight.w500, color: colors.foreground)),
                            subtitle: g.description != null
                                ? Text(g.description!,
                                    style: typo.xs.copyWith(color: colors.mutedForeground))
                                : null,
                            suffix: Icon(FIcons.chevronRight, size: 14, color: colors.border),
                            onPress: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GroupDetailScreen(groupId: g.id, groupName: g.name),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, FColors colors, FTypography typo) {
    return Expanded(
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: colors.mutedForeground),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.foreground,
                      )),
                  Text(label, style: typo.xs.copyWith(color: colors.mutedForeground)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarCircle(String name, FColors colors, FTypography typo) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: Text(initial,
          style: typo.xs.copyWith(fontWeight: FontWeight.w600, color: colors.foreground)),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showFDialog(
      context: context,
      builder: (ctx, style, animation) => FDialog.raw(
        animation: animation,
        builder: (ctx, style) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create group',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.theme.colors.foreground,
                  )),
              const SizedBox(height: 4),
              Text('Add a new group to track shared expenses.',
                  style: context.theme.typography.sm
                      .copyWith(color: context.theme.colors.mutedForeground)),
              const SizedBox(height: 20),
              const _CreateGroupForm(),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FTextField(
          label: const Text('Name'),
          hint: 'e.g. Work trip, Roommates',
          control: FTextFieldControl.managed(controller: _nameCtl),
          enabled: !_loading,
        ),
        const SizedBox(height: 12),
        FTextField.multiline(
          label: const Text('Description (optional)'),
          hint: 'What is this group for?',
          control: FTextFieldControl.managed(controller: _descCtl),
          minLines: 2,
          maxLines: 3,
          enabled: !_loading,
        ),
        const SizedBox(height: 20),
        FButton(
          onPress: _loading ? null : _submit,
          prefix: _loading
              ? const SizedBox(width: 16, height: 16, child: FCircularProgress())
              : const Icon(FIcons.check),
          child: const Text('Create'),
        ),
        const SizedBox(height: 8),
        FButton(
          variant: FButtonVariant.outline,
          onPress: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(groupRepositoryProvider).createGroup(
            name: name,
            description: _descCtl.text.trim().isNotEmpty ? _descCtl.text.trim() : null,
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
