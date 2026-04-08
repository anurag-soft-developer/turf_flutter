import 'dart:ui';

import 'package:flutter/material.dart';
import '../../config/constants.dart';

class AppBottomNavigationPanel extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavigationPanel({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<AppBottomNavigationPanel> createState() =>
      _AppBottomNavigationPanelState();
}

class _AppBottomNavigationPanelState extends State<AppBottomNavigationPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _position = 0; // fractional index (0.0 = first item centered)
  double _animFrom = 0;
  double _animTo = 0;

  static const _items = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.grass_outlined, Icons.grass, 'Turfs'),
    _NavItem(Icons.sports_soccer_outlined, Icons.sports_soccer, 'Match Up'),
    _NavItem(Icons.groups_outlined, Icons.groups, 'Teams'),
    _NavItem(Icons.emoji_events_outlined, Icons.emoji_events, 'Players'),
    _NavItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  static const double _itemSpacing = 82.0;
  static const double _itemWidth = 72.0;

  @override
  void initState() {
    super.initState();
    _position = widget.currentIndex.toDouble();
    _animTo = _position;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(_onAnimate);
  }

  @override
  void didUpdateWidget(AppBottomNavigationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex &&
        !_controller.isAnimating) {
      _animateTo(widget.currentIndex.toDouble());
    }
  }

  void _onAnimate() {
    final curved = Curves.easeOutCubic.transform(_controller.value);
    setState(() {
      _position = lerpDouble(_animFrom, _animTo, curved)!;
    });
  }

  void _animateTo(double target) {
    _animFrom = _position;
    _animTo = target;
    _controller.forward(from: 0);
  }

  void _onDragStart(DragStartDetails details) {
    _controller.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _position = (_position - details.delta.dx / _itemSpacing).clamp(
        0.0,
        (_items.length - 1).toDouble(),
      );
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    int target;
    if (velocity.abs() > 400) {
      // TWEAK 1: fling threshold (lower = easier to trigger)
      final jump = (velocity.abs() / 1800)
          .ceil(); // TWEAK 2: divisor (lower = jumps more items per swipe)
      target = velocity < 0
          ? (_position + jump).round().clamp(0, _items.length - 1)
          : (_position - jump).round().clamp(0, _items.length - 1);
    } else {
      // Snap to nearest
      target = _position.round().clamp(0, _items.length - 1);
    }

    if (target != widget.currentIndex) {
      widget.onTap(target);
    }
    _animateTo(target.toDouble());
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: const Color(AppColors.surfaceColor).withValues(alpha: 0.75),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Stack(
              children: List.generate(_items.length, (index) {
                final offset = index - _position;
                final absOffset = offset.abs();

                // Items beyond visible range
                final opacity = (1.0 - absOffset * 0.35).clamp(0.0, 1.0);
                if (opacity <= 0) return const SizedBox.shrink();

                final x = centerX + (offset * _itemSpacing) - _itemWidth / 2;
                final scale = (1.0 - absOffset * 0.12).clamp(0.6, 1.0);
                final isCenter = absOffset < 0.4;

                return Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: GestureDetector(
                        onTap: () => widget.onTap(index),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: _itemWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildIcon(index, absOffset, isCenter),
                              const SizedBox(height: 4),
                              _buildLabel(index, absOffset, isCenter),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(int index, double absOffset, bool isCenter) {
    final item = _items[index];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isCenter ? 14 : 10),
      decoration: BoxDecoration(
        color: isCenter
            ? const Color(AppColors.primaryColor)
            : absOffset < 1.5
            ? const Color(AppColors.primaryColor).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(isCenter ? 18 : 14),
        boxShadow: isCenter
            ? [
                BoxShadow(
                  color: const Color(
                    AppColors.primaryColor,
                  ).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        isCenter ? item.activeIcon : item.icon,
        size: isCenter ? 28 : 22,
        color: isCenter
            ? Colors.white
            : absOffset < 1.5
            ? const Color(AppColors.primaryColor)
            : const Color(AppColors.textSecondaryColor),
      ),
    );
  }

  Widget _buildLabel(int index, double absOffset, bool isCenter) {
    return Text(
      _items[index].label,
      style: TextStyle(
        fontSize: isCenter ? 11 : 10,
        fontWeight: isCenter ? FontWeight.w700 : FontWeight.w500,
        color: isCenter
            ? const Color(AppColors.primaryColor)
            : absOffset < 1.5
            ? const Color(AppColors.primaryColor).withValues(alpha: 0.7)
            : const Color(AppColors.textSecondaryColor),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}
