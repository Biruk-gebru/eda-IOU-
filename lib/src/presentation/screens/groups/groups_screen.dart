import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

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
    final theme = context.theme;
    final colors = theme.colors;
    final typo = theme.typography;
    final groupsAsync = ref.watch(groupListProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Groups',
                  style: typo.lg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
              FButton(
                onPress: () => _showCreateGroupDialog(context),
                prefix: const Icon(FIcons.plus),
                child: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: groupsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Something went wrong',
                        style: typo.sm.copyWith(color: colors.destructive)),
                    const SizedBox(height: 12),
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
                        Icon(FIcons.users,
                            size: 48, color: colors.mutedForeground),
                        const SizedBox(height: 12),
                        Text('No groups yet',
                            style: typo.md
                                .copyWith(color: colors.mutedForeground)),
                        const SizedBox(height: 4),
                        Text('Create one to start tracking expenses',
                            style: typo.sm
                                .copyWith(color: colors.mutedForeground)),
                        const SizedBox(height: 20),
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
                    // Summary
                    Row(
                      children: [
                        Expanded(
                          child: FCard.raw(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${groups.length}',
                                      style: typo.xl.copyWith(
                                          fontWeight: FontWeight.bold)),
                                  Text('Groups',
                                      style: typo.xs.copyWith(
                                          color: colors.mutedForeground)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FCard.raw(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('0',
                                      style: typo.xl.copyWith(
                                          fontWeight: FontWeight.bold)),
                                  Text('Pending',
                                      style: typo.xs.copyWith(
                                          color: colors.mutedForeground)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Group list
                    FTileGroup(
                      children: [
                        for (final g in groups)
                          FTile(
                            title: Text(g.name),
                            subtitle: g.description != null
                                ? Text(g.description!)
                                : null,
                            suffix: const Icon(FIcons.chevronRight),
                            onPress: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GroupDetailScreen(
                                  groupId: g.id,
                                  groupName: g.name,
                                ),
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

  void _showCreateGroupDialog(BuildContext context) {
    showFDialog(
      context: context,
      builder: (ctx, style, animation) => FDialog.raw(
        animation: animation,
        builder: (ctx, style) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create group',
                  style: context.theme.typography.lg
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Add a new group to track shared expenses.',
                  style: context.theme.typography.sm
                      .copyWith(color: context.theme.colors.mutedForeground)),
              const SizedBox(height: 16),
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
          hint: 'Group name',
          control: FTextFieldControl.managed(controller: _nameCtl),
          enabled: !_loading,
        ),
        const SizedBox(height: 12),
        FTextField.multiline(
          label: const Text('Description'),
          hint: 'Optional',
          control: FTextFieldControl.managed(controller: _descCtl),
          minLines: 2,
          maxLines: 3,
          enabled: !_loading,
        ),
        const SizedBox(height: 16),
        FButton(
          onPress: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2))
              : const Text('Create'),
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
            description:
                _descCtl.text.trim().isNotEmpty ? _descCtl.text.trim() : null,
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
