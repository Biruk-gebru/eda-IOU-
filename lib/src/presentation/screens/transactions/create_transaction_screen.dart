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
    final groupsAsync = ref.watch(groupListProvider);

    return FScaffold(
      header: FHeader.nested(
        title: const Text('New Transaction'),
        prefixes: [
          FHeaderAction.back(
            onPress: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Split type toggle: Group vs Personal
            Row(
              children: [
                Expanded(
                  child: FButton(
                    variant:
                        _isGroupExpense ? FButtonVariant.primary : FButtonVariant.outline,
                    onPress: () => setState(() => _isGroupExpense = true),
                    prefix: const Icon(Icons.groups_outlined),
                    child: const Text('Group'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FButton(
                    variant:
                        !_isGroupExpense ? FButtonVariant.primary : FButtonVariant.outline,
                    onPress: () => setState(() {
                      _isGroupExpense = false;
                      _selectedGroup = null;
                      _participants = [];
                    }),
                    prefix: const Icon(Icons.person_outline),
                    child: const Text('Personal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Group selector
            if (_isGroupExpense) ...[
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return FCard(
                      title: const Text('No groups'),
                      subtitle: const Text(
                          'Create or join a group first to make group transactions.'),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Group',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...groups.map(
                        (group) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: FTile(
                            title: Text(group.name),
                            subtitle: group.description != null
                                ? Text(group.description!)
                                : null,
                            selected: _selectedGroup?.id == group.id,
                            onPress: () {
                              setState(() => _selectedGroup = group);
                              _loadGroupMembers(group.id);
                            },
                            suffix: _selectedGroup?.id == group.id
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF00BFA5))
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => FCard(
                  title: const Text('Error loading groups'),
                  subtitle: Text('$e'),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Description field
            FTextField(
              control: FTextFieldControl.managed(
                controller: _descriptionController,
              ),
              label: const Text('Description'),
              hint: 'e.g. Dinner at restaurant',
            ),
            const SizedBox(height: 16),

            // Amount field
            FTextField(
              control: FTextFieldControl.managed(
                controller: _amountController,
              ),
              label: const Text('Total Amount (ETB)'),
              hint: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: 20),

            // Equal/custom split toggle
            FSwitch(
              label: const Text('Custom split'),
              description: const Text('Toggle for unequal distribution'),
              value: _customSplit,
              onChange: (value) => setState(() => _customSplit = value),
            ),
            const SizedBox(height: 16),

            // Participants list
            if (_participants.isNotEmpty) ...[
              Text(
                'Participants',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ..._participants.map((p) => _buildParticipantRow(p)),
              const SizedBox(height: 16),
            ],

            // Approval rules info card
            FCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.rule, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Majority of included participants must approve within 48h. '
                        'Auto-cancels if no response.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FButton(
                onPress: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit for Approval'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantRow(_ParticipantEntry participant) {
    final amountController = TextEditingController(
      text: participant.customAmount?.toStringAsFixed(2) ?? '',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FTile(
        title: Text(participant.displayName),
        subtitle: _customSplit
            ? SizedBox(
                width: 100,
                height: 36,
                child: TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Amount',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (value) {
                    participant.customAmount = double.tryParse(value);
                  },
                ),
              )
            : Text(participant.isPayer ? 'Payer' : 'Equal split'),
        prefix: FCheckbox(
          value: participant.included,
          onChange: (value) {
            setState(() {
              participant.included = value;
            });
          },
        ),
        suffix: participant.isPayer
            ? const Icon(Icons.account_balance_wallet_outlined,
                color: Color(0xFF00BFA5))
            : null,
      ),
    );
  }

  Future<void> _loadGroupMembers(String groupId) async {
    try {
      final members = await ref.read(groupMembersProvider(groupId).future);
      final client = ref.read(supabaseClientProvider);
      final currentUserId = client.auth.currentUser?.id;

      final entries = <_ParticipantEntry>[];
      for (final member in members) {
        // Try to fetch display name from profiles
        String displayName = 'User';
        try {
          final profile = await client
              .from('profiles')
              .select('display_name')
              .eq('id', member.userId)
              .maybeSingle();
          if (profile != null && profile['display_name'] != null) {
            displayName = profile['display_name'] as String;
          }
        } catch (_) {
          // Use fallback
        }

        final isPayer = member.userId == currentUserId;
        if (isPayer) {
          displayName = 'You';
        }

        entries.add(_ParticipantEntry(
          userId: member.userId,
          displayName: displayName,
          isPayer: isPayer,
        ));
      }

      setState(() => _participants = entries);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading members: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    final amountText = _amountController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    final totalAmount = double.tryParse(amountText);
    if (totalAmount == null || totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    final includedParticipants =
        _participants.where((p) => p.included).toList();

    // Build participant maps
    final participantMaps = <Map<String, dynamic>>[];
    if (_customSplit) {
      for (final p in includedParticipants) {
        participantMaps.add({
          'user_id': p.userId,
          'amount_due': p.customAmount ?? 0.0,
        });
      }
    } else {
      final splitAmount = includedParticipants.isNotEmpty
          ? totalAmount / includedParticipants.length
          : totalAmount;
      for (final p in includedParticipants) {
        participantMaps.add({
          'user_id': p.userId,
          'amount_due': splitAmount,
        });
      }
    }

    // If no group participants, add self as the only participant
    if (participantMaps.isEmpty) {
      participantMaps.add({
        'user_id': currentUserId,
        'amount_due': totalAmount,
      });
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.createTransaction(
        groupId: _selectedGroup?.id,
        payerId: currentUserId,
        totalAmount: totalAmount,
        description: description,
        participants: participantMaps,
      );

      // Invalidate transaction list cache
      ref.invalidate(transactionListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction created successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
