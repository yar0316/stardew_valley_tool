import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/goal.dart';

class GoalsController extends StateNotifier<List<Goal>> {
  GoalsController() : super(const []);

  void setGoals(List<Goal> goals) => state = goals;
  void addGoal(Goal goal) => state = [...state, goal];
  void removeGoal(String id) => state = state.where((g) => g.id != id).toList();
}

final goalsProvider =
    StateNotifierProvider<GoalsController, List<Goal>>((ref) => GoalsController());

