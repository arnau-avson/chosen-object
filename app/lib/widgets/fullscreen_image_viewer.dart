import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FullscreenImageViewer extends StatefulWidget {
  final List<String> imagesB64;
  final int initialIndex;
  const FullscreenImageViewer(
      {super.key, required this.imagesB64, this.initialIndex = 0});

  /// Opens the viewer via a fade transition.
  static void open(
      BuildContext context, List<String> imagesB64,
      {int initialIndex = 0}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, _, _) => FullscreenImageViewer(
            imagesB64: imagesB64, initialIndex: initialIndex),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imagesB64;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: images.length,
            onPageChanged: (p) => setState(() => _current = p),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Image.memory(
                  base64Decode(images[i]),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Bottom: counter + arrows
          if (images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _current > 0
                        ? () => _pageCtrl.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            )
                        : null,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 24,
                      color: _current > 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_current + 1} / ${images.length}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _current < images.length - 1
                        ? () => _pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            )
                        : null,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color: _current < images.length - 1
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
