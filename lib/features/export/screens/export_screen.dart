import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/session_state.dart';
import '../../session/controllers/booth_session_controller.dart';

/// Screen displayed after film strip compositing completes.
/// Renders a dynamic aspect ratio preview, format badge, and export actions
/// (save to gallery, share, and return to home session).
class ExportScreen extends StatefulWidget {
  final BoothSessionController controller;

  const ExportScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BoothSessionState>(
      valueListenable: widget.controller,
      builder: (context, state, child) {
        if (state is! SessionExportReady) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F11),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final compositePath = state.compositeFilePath;
        final compositeFile = File(compositePath);

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F11),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Your Film Strip',
              style: TextStyle(
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
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Chip(
                    label: Text(
                      state.printFormat.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.white.withAlpha(25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: AspectRatio(
                        aspectRatio: state.printFormat.aspectRatio,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black87,
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: compositeFile.existsSync()
                                ? Image.file(
                                    compositeFile,
                                    fit: BoxFit.contain,
                                  )
                                : Container(
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]?.withAlpha(200),
                    border: const Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.download),
                              label: Text(_isSaving ? 'Saving...' : 'Save to Roll'),
                              onPressed: _isSaving
                                  ? null
                                  : () async {
                                      setState(() => _isSaving = true);
                                      try {
                                        final success = await widget.controller.storageService.saveToGallery(compositePath);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                success ? 'Saved strip to Camera Roll!' : 'Unable to save to gallery',
                                              ),
                                              backgroundColor: success ? Colors.green[800] : Colors.red[800],
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isSaving = false);
                                        }
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5252),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              onPressed: () async {
                                try {
                                  await Share.shareXFiles(
                                    [XFile(compositePath)],
                                    text: 'My Korean 4-Cut Photobooth Strip #인생네컷',
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to share: $e'),
                                        backgroundColor: Colors.red[800],
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () async {
                            await widget.controller.finishSession();
                          },
                          child: const Text(
                            'Done & New Session',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
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
