import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game/rpg_game.dart';
import '../../state/game_state_controller.dart';
import '../../state/models/game_models.dart';

class PauseMenuOverlay extends StatelessWidget {
  const PauseMenuOverlay({
    super.key,
    required this.game,
  });

  final RpgGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xA0000000),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            color: const Color(0xF0142238),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Consumer<GameStateController>(
                builder: (context, controller, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '系統選單',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            onPressed: game.saveGame,
                            child: const Text('存檔'),
                          ),
                          FilledButton.tonal(
                            onPressed: game.loadGame,
                            child: const Text('讀檔'),
                          ),
                          FilledButton.tonal(
                            onPressed: controller.returnToTitleMenu,
                            child: const Text('回初始選單'),
                          ),
                          OutlinedButton(
                            onPressed: controller.closePauseMenu,
                            child: const Text('返回遊戲'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '背包',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          itemCount: controller.inventory.length,
                          separatorBuilder: (_, _) => const Divider(color: Colors.white12),
                          itemBuilder: (context, index) {
                            final entry = controller.inventory[index];
                            final item = entry.item;
                            return ListTile(
                              title: Text(item.name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(item.description, style: const TextStyle(color: Colors.white70)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('x${entry.quantity}', style: const TextStyle(color: Colors.white)),
                                  const SizedBox(width: 8),
                                  if (item.type == ItemType.weapon || item.type == ItemType.armor)
                                    TextButton(
                                      onPressed: () => controller.equipItem(item.id),
                                      child: const Text('裝備'),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '裝備: 武器 ${controller.equipment.weaponId ?? '-'} / 防具 ${controller.equipment.armorId ?? '-'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
