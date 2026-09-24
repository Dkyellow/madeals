import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Scales its child down while pressed and springs back — tactile press feedback.
///
/// Uses a raw [Listener] for the visual state so it keeps working even when an
/// inner widget (button, icon) wins the tap gesture. If [onTap] is null, only
/// the press visual is applied and the child handles its own taps.
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.haptic = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  /// Fire a light selection haptic when the tap completes.
  final bool haptic;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.onTap == null
        ? widget.child
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
            child: widget.child,
          );

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: Duration(milliseconds: _pressed ? 90 : 180),
        curve: Curves.easeOutCubic,
        child: content,
      ),
    );
  }
}

/// Pops (1 → [peak] → 1) whenever [value] changes — for heart/save toggles.
class PopOnChanged extends StatefulWidget {
  const PopOnChanged({
    super.key,
    required this.value,
    required this.child,
    this.peak = 1.35,
  });

  final Object? value;
  final Widget child;
  final double peak;

  @override
  State<PopOnChanged> createState() => _PopOnChangedState();
}

class _PopOnChangedState extends State<PopOnChanged>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(PopOnChanged oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: widget.peak),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.peak, end: 1.0),
        weight: 65,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    return ScaleTransition(scale: scale, child: widget.child);
  }
}

/// Fade + slide-up entrance animation that runs once when first built.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.offset = const Offset(0, 0.06),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  /// Stagger delay for list items: index 0 is instant, capped at [cap] steps.
  static Duration stagger(int index, {int stepMs = 55, int cap = 8}) {
    final step = index.clamp(0, cap);
    return Duration(milliseconds: step * stepMs);
  }

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: widget.offset, end: Offset.zero)
            .animate(curved),
        child: widget.child,
      ),
    );
  }
}
