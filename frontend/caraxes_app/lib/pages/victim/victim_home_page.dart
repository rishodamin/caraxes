import 'package:caraxes_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class VictimHomePage extends StatefulWidget {
  const VictimHomePage({super.key});

  @override
  State<VictimHomePage> createState() => _VictimHomePageState();
}

class _VictimHomePageState extends State<VictimHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _VictimDashboard(),
    const Center(child: Text('Report Damage Page (Placeholder)')),
    const Center(child: Text('SOS Page (Placeholder)')),
    const Center(child: Text('Safe Zones Page (Placeholder)')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caraxes - Victim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.sos_outlined),
            selectedIcon: Icon(Icons.sos),
            label: 'SOS',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: 'Safe Zones',
          ),
        ],
      ),
    );
  }
}

class _VictimDashboard extends StatelessWidget {
  const _VictimDashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Welcome to Caraxes',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Current SOS Status Card
        Card(
          color: Colors.orange.shade100,
          elevation: 0,
          child: const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.orange),
            title: Text('No active SOS requests'),
            subtitle: Text('Tap the SOS tab if you need immediate help.'),
          ),
        ),
        const SizedBox(height: 24),
        
        // Quick Actions
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Report'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.map),
                label: const Text('Map'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Recent Reports Section
        Text(
          'Recent Reports',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.image),
                ),
                title: Text('Report #${index + 1}'),
                subtitle: const Text('Pending review...'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}
