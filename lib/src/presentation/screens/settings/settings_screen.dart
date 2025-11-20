import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildProfileCard(context),
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
            onPressed: () {},
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 32, child: Text('K')),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Karanos Abebe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text('karanos@example.com'),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
        ],
      ),
    );
  }
}

