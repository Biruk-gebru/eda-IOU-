import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/auth_controller.dart';
import '../../providers/auth_providers.dart';
import '../setup/bank_info_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    final client = ref.watch(supabaseClientProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildProfileCard(context, sessionAsync.valueOrNull, client),
          const SizedBox(height: 24),
          Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Push notifications'),
            subtitle: const Text('Approvals, payments, reminders'),
          ),
          SwitchListTile(
            value: false,
            onChanged: (_) {},
            title: const Text('Email digests'),
            subtitle: const Text('Daily summary of activity'),
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Security center'),
            subtitle: const Text('Sessions, OAuth providers'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Export data'),
            subtitle: const Text('Download CSV of transactions'),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Text('Support', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help center'),
            subtitle: const Text('FAQs, guides, troubleshooting'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Contact support'),
            onTap: () {},
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(authControllerProvider).signOut();
              } on AuthControllerException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.message)));
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Session? session, SupabaseClient client) {
    final email = session?.user.email ?? 'you@example.com';
    final name =
        session?.user.userMetadata?['full_name'] as String? ?? 'Your profile';
    final uid = session?.user.id;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(email),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined), 
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BankInfoScreen()),
                ),
              ),
            ],
          ),
          if (uid != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            StreamBuilder<Map<String, dynamic>?>(
              stream: client.from('profiles').stream(primaryKey: ['id']).eq('id', uid).map((event) => event.isEmpty ? null : event.first),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (!snapshot.hasData) return const SizedBox.shrink(); // Loading or no data
                final data = snapshot.data;
                if (data == null) return const Text('No banking info set');
                
                final bank = data['bank_name'] as String?;
                final account = data['account_number'] as String?;
                
                if (bank == null || account == null) return const Text('No banking info set');

                return Row(
                  children: [
                     const Icon(Icons.account_balance, size: 20, color: Colors.grey),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            Text(bank, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(account, style: const TextStyle(fontSize: 12)),
                         ],
                       ),
                     )
                  ],
                );
              }
            )
          ]
        ],
      ),
    );
  }
}
