import 'package:flutter/material.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupName});

  final String groupName;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            onPressed: () => _showInviteSheet(context),
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ledger'),
            Tab(text: 'Members'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildLedgerTab(), _buildMembersTab(), _buildRequestsTab()],
      ),
    );
  }

  Widget _buildLedgerTab() {
    final entries = [
      _LedgerEntry(
        title: 'Dinner at Blue Nile',
        amount: 540,
        status: 'Pending approval',
        timestamp: 'Today • 6:12 PM',
      ),
      _LedgerEntry(
        title: 'Uber rides',
        amount: 220,
        status: 'Approved',
        timestamp: 'Yesterday • 9:40 PM',
      ),
      _LedgerEntry(
        title: 'Groceries',
        amount: 870,
        status: 'Applied to balances',
        timestamp: 'Nov 12 • 3:20 PM',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: entries.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _LedgerCard(entry: entries[index]),
      ),
    );
  }

  Widget _buildMembersTab() {
    final members = [
      _Member(name: 'You', role: 'Creator', balance: 0),
      _Member(name: 'Liya', role: 'Member', balance: -230),
      _Member(name: 'Tomas', role: 'Member', balance: 120),
      _Member(name: 'Sarah', role: 'Member', balance: 110),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(
          child: Text(members[index].name.characters.first),
        ),
        title: Text(members[index].name),
        subtitle: Text(members[index].role),
        trailing: Text(
          members[index].balance == 0
              ? 'Settled'
              : '${members[index].balance > 0 ? 'Owes' : 'Is owed'} '
                    'ETB ${members[index].balance.abs()}',
          style: TextStyle(
            color: members[index].balance >= 0
                ? Colors.teal
                : Colors.orangeAccent,
          ),
        ),
      ),
      separatorBuilder: (context, index) => const Divider(height: 0),
      itemCount: members.length,
    );
  }

  Widget _buildRequestsTab() {
    final requests = [
      _Request(name: 'Dawit', type: 'Join request', time: '2h ago'),
      _Request(name: 'Netsanet', type: 'Approval reminder', time: '1d ago'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Text(requests[index].name.characters.first),
          ),
          title: Text(requests[index].name),
          subtitle: Text('${requests[index].type} • ${requests[index].time}'),
          trailing: Wrap(
            spacing: 8,
            children: [
              OutlinedButton(onPressed: () {}, child: const Text('Reject')),
              FilledButton(onPressed: () {}, child: const Text('Approve')),
            ],
          ),
        ),
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: requests.length,
    );
  }

  void _showInviteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Invite via link',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Shareable link',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              controller: TextEditingController(
                text: 'https://eda.app/invite/demo',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerEntry {
  _LedgerEntry({
    required this.title,
    required this.amount,
    required this.status,
    required this.timestamp,
  });

  final String title;
  final double amount;
  final String status;
  final String timestamp;
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.entry});

  final _LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'ETB ${entry.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(entry.timestamp, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Chip(label: Text(entry.status), backgroundColor: Colors.grey[200]),
          ],
        ),
      ),
    );
  }
}

class _Member {
  _Member({required this.name, required this.role, required this.balance});

  final String name;
  final String role;
  final double balance;
}

class _Request {
  _Request({required this.name, required this.type, required this.time});

  final String name;
  final String type;
  final String time;
}
