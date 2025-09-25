import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/routes.dart';
import 'features/dashboard/presentation/dashboard_page.dart';
import 'features/fish/presentation/fish_page.dart';
import 'features/crops/presentation/crops_page.dart';
import 'features/crops/presentation/crops_plan_page.dart';
import 'features/crops/domain/crop.dart';
import 'features/npc/presentation/npc_page.dart';
import 'features/buildings/presentation/buildings_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: Routes.dashboard,
        routes: {
          Routes.dashboard: (context) => const DashboardPage(),
          Routes.fish: (context) => const FishPage(),
          Routes.crops: (context) => const CropsPage(),
          Routes.cropsPlan: (context) {
            final args = ModalRoute.of(context)?.settings.arguments;
            return CropsPlanPage(crop: args is Crop ? args : null);
          },
          Routes.npc: (context) => const NpcPage(),
          Routes.buildings: (context) => const BuildingsPage(),
        },
      ),
    );
  }
}
