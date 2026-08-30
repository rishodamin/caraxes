import 'package:caraxes_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class RescuerHomePage extends StatefulWidget {
  const RescuerHomePage({super.key});

  @override
  State<RescuerHomePage> createState() => _RescuerHomePageState();
}

class _RescuerHomePageState extends State<RescuerHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _RescuerDashboard(),
    const Center(child: Text('Map Page (Placeholder)')),
    const Center(child: Text('Reports Page (Placeholder)')),
    const Center(child: Text('Route Page (Placeholder)')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caraxes - Rescuer'),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Route',
          ),
        ],
      ),
    );
  }
}

class _RescuerDashboard extends StatelessWidget {
  const _RescuerDashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Rescuer Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        // Stats Row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Active Incidents',
                value: '12',
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Pending SOS',
                value: '5',
                icon: Icons.sos,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // High Priority Reports
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'High Priority Reports',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.priority_high, color: Colors.red),
                title: Text('Critical Damage Report #${index + 1}'),
                subtitle: const Text('2 mins ago • Sector A'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        
        // Quick Access Cards
        Text(
          'Quick Access',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.group),
              label: const Text('Team'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.inventory),
              label: const Text('Supplies'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.contact_phone),
              label: const Text('Contacts'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings),
              label: const Text('Settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
