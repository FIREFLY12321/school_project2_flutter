import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OverlayService {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;
  static const MethodChannel _channel = MethodChannel('overlay_channel');

  static bool get isVisible => _isVisible;

  static void showOverlay(BuildContext context, VoidCallback onPressed) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => SystemOverlayFAB(
        onPressed: onPressed,
        onClose: hideOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
  }

  static void hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isVisible = false;
  }

  static void toggleOverlay(BuildContext context, VoidCallback onPressed) {
    if (_isVisible) {
      hideOverlay();
    } else {
      showOverlay(context, onPressed);
    }
  }

  // 測試浮動按鈕是否可見的功能
  static bool testFloatingButtonVisibility() {
    return _isVisible;
  }
}

class SystemOverlayFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final VoidCallback onClose;

  const SystemOverlayFAB({
    Key? key,
    required this.onPressed,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SystemOverlayFAB> createState() => _SystemOverlayFABState();
}

class _SystemOverlayFABState extends State<SystemOverlayFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Offset _position = const Offset(300, 500);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (details) {
          _isDragging = true;
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx).clamp(0, screenSize.width - 56),
              (_position.dy + details.delta.dy).clamp(0, screenSize.height - 56),
            );
          });
        },
        onPanEnd: (details) {
          _isDragging = false;
          // 自動吸附到邊緣
          setState(() {
            if (_position.dx > screenSize.width / 2) {
              _position = Offset(screenSize.width - 56 - 16, _position.dy);
            } else {
              _position = Offset(16, _position.dy);
            }
          });
        },
        onTap: () {
          if (!_isDragging) {
            widget.onPressed();
          }
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Material(
                elevation: 8,
                shape: const CircleBorder(),
                color: Colors.blue,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue,
                        Colors.blueAccent,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}