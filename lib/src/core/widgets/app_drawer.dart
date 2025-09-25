import 'package:flutter/material.dart';

import '../navigation/routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text('Stardew Valley Tools', style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          _item(context, icon: Icons.dashboard, label: 'ダッシュボード', route: Routes.dashboard),
          const Divider(),
          _item(context, icon: Icons.set_meal, label: '魚を探す', route: Routes.fish),
          _item(context, icon: Icons.grass, label: '作物を確認', route: Routes.crops),
          _item(context, icon: Icons.people, label: '住人を確認', route: Routes.npc),
          _item(context, icon: Icons.home_repair_service, label: '牧場施設', route: Routes.buildings),
        ],
      ),
    );
  }

  ListTile _item(BuildContext context,
      {required IconData icon, required String label, required String route}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        final current = ModalRoute.of(context)?.settings.name;
        Navigator.of(context).pop();
        if (current != route) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      },
    );
  }
}

