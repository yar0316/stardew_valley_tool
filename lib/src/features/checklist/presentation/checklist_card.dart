import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/checklist_controller.dart';
import '../domain/check_item.dart';

class ChecklistCard extends ConsumerWidget {
  const ChecklistCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checklistProvider);
    final ctrl = ref.read(checklistProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('チェックリスト', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.edit_note),
                  tooltip: '編集',
                  onPressed: () => _openEditDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.items.isEmpty) const Text('本日のチェック項目はありません'),
            ...state.items.map((e) => CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: e.isChecked,
                  onChanged: (v) => ctrl.toggle(e.id, v ?? false),
                  title: Row(
                    children: [
                      if (e.timeMinutes != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Chip(
                            label: Text(_formatTime(e.timeMinutes!)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      Flexible(child: Text(e.title)),
                      if (e.isRequired)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text('必須', style: TextStyle(color: Colors.red[700], fontSize: 12)),
                        ),
                    ],
                  ),
                  subtitle: e.source == ChecklistItemSource.auto
                      ? const Text('自動追加')
                      : null,
                )),
          ],
        ),
      ),
    );
  }

  String _formatTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _openEditDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(checklistProvider.notifier);
    final state = ref.read(checklistProvider);
    final manualItems = state.items.where((e) => e.type == ChecklistItemType.custom).toList();
    final textCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('チェックリストを編集'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCtrl,
                        decoration: const InputDecoration(
                          labelText: '項目を追加',
                          hintText: '例: 動物にエサ',
                        ),
                        onSubmitted: (v) {
                          if (v.trim().isEmpty) return;
                          ctrl.addCustomItem(v.trim());
                          textCtrl.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        final v = textCtrl.text.trim();
                        if (v.isEmpty) return;
                        ctrl.addCustomItem(v);
                        textCtrl.clear();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('追加'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: manualItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = manualItems[index];
                      return ListTile(
                        leading: const Icon(Icons.drag_indicator),
                        title: Text(item.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            ctrl.removeItem(item.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('イベントや水やりなどの自動項目は削除できません'),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}

