import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/models/photo_filter.dart';
import '../../../core/models/print_format.dart';
import '../../../core/models/session_state.dart';
import '../../session/controllers/booth_session_controller.dart';
import '../widgets/shot_thumbnail_tile.dart';

/// Screen allowing the user to select and reorder shots for their photobooth strip,
/// choose an authentic Korean tone filter, and toggle single vs twin-strip print formats.
class ContactSheetScreen extends StatelessWidget {
  final BoothSessionController controller;

  const ContactSheetScreen({
    super.key,
    required this.controller,
  });

  /// Builds a toggle option button for selecting print format.
  Widget _buildFormatOption({
    required Key key,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5252) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

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
        final ColorFilter? activeFilter = sheet.selectedFilter != PhotoFilter.none
            ? ColorFilter.matrix(sheet.selectedFilter.matrix)
            : null;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final shouldCancel = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text('Exit session?', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Your photos will be discarded and you will return to frame selection.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    key: const ValueKey('exit_dialog_cancel_button'),
                    child: const Text('Stay'),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                  ElevatedButton(
                    key: const ValueKey('exit_dialog_confirm_button'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252)),
                    child: const Text('Exit', style: TextStyle(color: Colors.white)),
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ],
              ),
            );
            if (shouldCancel == true) {
              await controller.cancelSession();
            }
          },
          child: Scaffold(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Tap to select ${sheet.selectedShotIds.length}/$targetCount. Drag strip items to reorder.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),

                // Reorderable Strip Tray
                if (selectedIds.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Row(
                      children: const [
                        Icon(Icons.drag_indicator, size: 16, color: Colors.white54),
                        SizedBox(width: 4),
                        Text(
                          'Strip Order (drag to rearrange):',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 72,
                    child: ReorderableListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: selectedIds.length,
                      // ignore: deprecated_member_use
                      onReorder: (oldIndex, newIndex) {
                        controller.reorderSelectedShots(oldIndex, newIndex);
                      },
                      itemBuilder: (context, idx) {
                        final photoId = selectedIds[idx];
                        final photo = sheet.allShots.where((p) => p.id == photoId).firstOrNull ?? sheet.allShots.first;
                        Widget trayImage = Image.file(
                          File(photo.filePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[900],
                            child: const Icon(Icons.broken_image, color: Colors.white54, size: 16),
                          ),
                        );
                        if (activeFilter != null) {
                          trayImage = ColorFiltered(
                            colorFilter: activeFilter,
                            child: trayImage,
                          );
                        }

                        return Container(
                          key: ValueKey(photoId),
                          width: 54,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFF5252), width: 1.5),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: trayImage,
                              ),
                              Positioned(
                                bottom: 2,
                                left: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${idx + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 8),
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
                        colorFilter: activeFilter,
                        onTap: () => controller.selectShot(photo.id),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]?.withAlpha(200),
                    border: const Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Print format toggle
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFormatOption(
                                key: const ValueKey('format_single'),
                                label: PrintFormat.singleStrip.displayName,
                                isSelected: sheet.selectedPrintFormat == PrintFormat.singleStrip,
                                onTap: () => controller.setPrintFormat(PrintFormat.singleStrip),
                              ),
                              _buildFormatOption(
                                key: const ValueKey('format_twin'),
                                label: PrintFormat.twinStrip.displayName,
                                isSelected: sheet.selectedPrintFormat == PrintFormat.twinStrip,
                                onTap: () => controller.setPrintFormat(PrintFormat.twinStrip),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Filter selector row
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: PhotoFilter.values.map((filter) {
                              final isSelected = sheet.selectedFilter == filter;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  key: ValueKey('filter_chip_${filter.name}'),
                                  label: Text(filter.displayName),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFFFF5252),
                                  backgroundColor: Colors.white10,
                                  showCheckmark: false,
                                  onSelected: (_) {
                                    controller.setFilter(filter);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Bottom actions: Retake & Bake Strip
                      Row(
                        children: [
                          TextButton.icon(
                            key: const ValueKey('retake_button'),
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
                                      key: const ValueKey('dialog_cancel_button'),
                                      child: const Text('Cancel'),
                                      onPressed: () => Navigator.pop(ctx, false),
                                    ),
                                    ElevatedButton(
                                      key: const ValueKey('dialog_confirm_button'),
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
                            key: const ValueKey('bake_strip_button'),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}
