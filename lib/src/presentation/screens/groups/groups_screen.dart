import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../providers/group_providers.dart';
import '../transactions/transaction_detail_screen.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupListProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Groups',
                style: context.theme.typography.xl2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.theme.colors.foreground,
                ),
              ),
              Row(
                children: [
                  FButton.icon(
                    onPress: () => _openTransactionTimeline(context),
                    child: const Icon(FIcons.clock),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: () => _showCreateGroupDialog(context),
                    prefix: const Icon(FIcons.plus),
                    child: const Text('New group'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Content
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator.adaptive(),
              ),
              error: (error, _) => Center(
                child: FCard(
                  title: const Text('Something went wrong'),
                  subtitle: Text('$error'),
                  child: FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => ref.invalidate(groupListProvider),
                    prefix: const Icon(FIcons.refreshCw),
                    child: const Text('Retry'),
                  ),
                ),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FIcons.users,
                          size: 64,
                          color: context.theme.colors.mutedForeground,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No groups yet',
                          style: context.theme.typography.lg.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a group to start tracking expenses',
                          style: context.theme.typography.sm.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
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
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [
                    // Summary cards row
                    Row(
                      children: [
                        Expanded(
                          child: FCard(
                            title: Text(
                              '${groups.length}',
                              style: context.theme.typography.xl2.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text('Your groups'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FCard(
                            title: Text(
                              '0',
                              style: context.theme.typography.xl2.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text('Pending invites'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Group list
                    FTileGroup(
                      label: Text(
                        'All groups',
                        style: context.theme.typography.sm.copyWith(
                          fontWeight: FontWeight.w500,
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                      children: [
                        for (final group in groups)
                          FTile(
                            title: Text(group.name),
                            subtitle: group.description != null
                                ? Text(group.description!)
                                : null,
                            suffix: const Icon(FIcons.chevronRight),
                            onPress: () => _openGroupDetail(
                              context,
                              group.name,
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
      builder: (dialogContext, style, animation) => FDialog.raw(
        animation: animation,
        builder: (context, style) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create group',
                style: context.theme.typography.lg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.theme.colors.foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a new group to track shared expenses.',
                style: context.theme.typography.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              const _CreateGroupForm(),
            ],
          ),
        ),
      ),
    );
  }

  void _openGroupDetail(BuildContext context, String groupName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailScreen(groupName: groupName),
      ),
    );
  }

  void _openTransactionTimeline(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transactionId: 'demo'),
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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FTextField(
          label: const Text('Group name'),
          hint: 'Enter group name',
          control: FTextFieldControl.managed(
            controller: _nameController,
          ),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 12),
        FTextField.multiline(
          label: const Text('Description'),
          hint: 'Enter a description (optional)',
          control: FTextFieldControl.managed(
            controller: _descriptionController,
          ),
          minLines: 2,
          maxLines: 4,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        FButton(
          onPress: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Create group'),
        ),
        const SizedBox(height: 8),
        FButton(
          variant: FButtonVariant.outline,
          onPress: _isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(groupRepositoryProvider).createGroup(
            name: name,
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
          );
      ref.invalidate(groupListProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
