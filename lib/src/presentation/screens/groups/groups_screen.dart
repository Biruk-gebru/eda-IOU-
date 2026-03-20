import 'package:flutter/material.dart';

import '../transactions/transaction_detail_screen.dart';
import 'group_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  // Removing hardcoded _groups
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final client = ref.watch(supabaseClientProvider);
    final user = client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_toggle_off),
            tooltip: 'Recent approvals',
            onPressed: () => _openTransactionTimeline(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateGroupSheet(context),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('New group'),
      ),
      body: user == null 
          ? const Center(child: Text('Please sign in'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: client
                  .from('groups')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final groups = snapshot.data!;
                
                if (groups.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.groups_outlined, size: 64, color: Colors.grey[300]),
                         const SizedBox(height: 16),
                         Text('No groups yet', style: TextStyle(color: Colors.grey.shade600)),
                       ],
                     ),
                   );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSummaryRow(colorScheme, groups.length),
                    const SizedBox(height: 24),
                    ...groups.map(
                      (groupData) {
                         // Mapping raw data to _GroupCardData for now
                         final group = _GroupCardData(
                           name: groupData['name'] ?? 'Unnamed',
                           members: 1, // Placeholder until we have members table
                           pendingApprovals: 0,
                           outstandingAmount: 0,
                         );
                         return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _GroupCard(
                              data: group,
                              onTap: () => _openGroupDetail(context, group.name),
                            ),
                          );
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryRow(ColorScheme colorScheme, int count) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Your groups',
            value: '$count',
            icon: Icons.groups_rounded,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryTile(
            label: 'Pending invites',
            value: '0', // Placeholder
            icon: Icons.mail_outline,
            color: colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  void _openCreateGroupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _CreateGroupSheet(),
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

class _GroupCardData {
  const _GroupCardData({
    required this.name,
    required this.members,
    required this.pendingApprovals,
    required this.outstandingAmount,
  });

  final String name;
  final int members;
  final int pendingApprovals;
  final double outstandingAmount;
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.data, required this.onTap});

  final _GroupCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    data.name.characters.first,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${data.members} members',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _InfoChip(
                    icon: Icons.pending_actions_outlined,
                    label: '${data.pendingApprovals} approvals',
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: _InfoChip(
                    icon: Icons.attach_money,
                    label: 'ETB ${data.outstandingAmount.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _requireApproval = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Create group', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Group name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Join requests require approval'),
              subtitle: const Text('Only creator can approve memberships'),
              value: _requireApproval,
              onChanged: (value) => setState(() => _requireApproval = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text('Create group'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final client = ref.read(supabaseClientProvider);
        final user = client.auth.currentUser;
        if (user != null) {
          await client.from('groups').insert({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'creator_id': user.id,
            'is_invite_only': _requireApproval,
            'created_at': DateTime.now().toIso8601String(),
            // Assuming simplified schema for now
          });
          
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Group created successfully')),
            );
            // In a real app, invalidate a provider here to refresh list
            // ref.invalidate(groupsProvider);
          }
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
}
