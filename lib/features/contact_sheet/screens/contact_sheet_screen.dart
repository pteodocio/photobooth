import 'package:flutter/material.dart';
import '../../../core/models/session_state.dart';
import '../../session/controllers/booth_session_controller.dart';
import '../widgets/shot_thumbnail_tile.dart';

class ContactSheetScreen extends StatelessWidget {
  final BoothSessionController controller;

  const ContactSheetScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BoothSessionState>(
      valueListenable: controller,
      builder: (context, state, child) {
        if (state is! SessionContactSheet && state is! SessionCompositing) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F11),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (state is SessionCompositing) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F11),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Baking your film strip...',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }

        final sheet = state as SessionContactSheet;
        final targetCount = sheet.layout.slotCount;
        final selectedIds = sheet.selectedShotIds;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F11),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Select $targetCount photos',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Tap to select ${sheet.selectedShotIds.length}/$targetCount. Photos will appear on the strip in selected order.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: sheet.allShots.length,
                    itemBuilder: (context, index) {
                      final photo = sheet.allShots[index];
                      final orderIndex = selectedIds.indexOf(photo.id);
                      final selectionOrder = orderIndex != -1 ? orderIndex + 1 : null;

                      return ShotThumbnailTile(
                        photo: photo,
                        selectionOrder: selectionOrder,
                        onTap: () => controller.selectShot(photo.id),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]?.withAlpha(200),
                    border: const Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        label: const Text('Retake', style: TextStyle(color: Colors.white70)),
                        onPressed: () async {
                          final shouldRetake = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text('Retake burst?', style: TextStyle(color: Colors.white)),
                              content: const Text(
                                'This will discard current shots and restart the countdown.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.pop(ctx, false),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252)),
                                  child: const Text('Retake', style: TextStyle(color: Colors.white)),
                                  onPressed: () => Navigator.pop(ctx, true),
                                ),
                              ],
                            ),
                          );
                          if (shouldRetake == true) {
                            await controller.retakeBurst();
                          }
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          disabledBackgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: controller.canConfirmSelection
                            ? () async {
                                await controller.confirmSelection();
                              }
                            : null,
                        child: const Text(
                          'Bake Strip',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
