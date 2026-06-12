import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// A vertical scroll-wheel interval picker.
///
/// Drag UP to increase the value, drag DOWN to decrease. Snaps to
/// integer minutes. Each integer past is a discrete tick that triggers
/// a light haptic feedback. Includes a tap-to-edit affordance for
/// precise values outside the typical range (e.g. 1-4 minutes for
/// quick test sessions, or 121-240 minutes for marathon focus blocks).
///
/// Visual: a vertical strip showing ~3 visible numbers (one centered
/// and large in amber, two smaller and muted above/below).
class IntervalWheel extends StatefulWidget {
  final int value; // current value in minutes
  final int min; // minimum value shown in the wheel
  final int max; // maximum value shown in the wheel
  final int editorMin; // minimum value allowed in the editor dialog
  final int editorMax; // maximum value allowed in the editor dialog
  final ValueChanged<int> onChanged;

  const IntervalWheel({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 5,
    this.max = 120,
    this.editorMin = 1,
    this.editorMax = 240,
  });

  @override
  State<IntervalWheel> createState() => _IntervalWheelState();
}

class _IntervalWheelState extends State<IntervalWheel> {
  late ScrollController _controller;
  late int _value;
  final double _itemHeight = 44;

  /// One full "item" of empty space at top and bottom of the list. This
  /// shifts the visible center line so that an item sits centered (rather
  /// than the first item being at the top of the wheel).
  double get _centerPadding => _itemHeight;

  @override
  void initState() {
    super.initState();
    // Use widget.value as-is (don't clamp to wheel range). If the actual
    // value is below wheel min or above wheel max, the wheel will still
    // display the nearest visible value but the underlying value is
    // preserved (e.g. user typed 3 in editor — wheel centers on 5 but
    // big number above still shows 3).
    _value = widget.value;
    _controller = ScrollController();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToValue(_value, animated: false);
    });
  }

  @override
  void didUpdateWidget(covariant IntervalWheel old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != _value) {
      _value = widget.value;
      _jumpToValue(_value, animated: false);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  /// Jump (or animate) so that [value] is centered in the visible wheel.
  /// If [value] is outside [widget.min, widget.max], snap to the nearest
  /// end of the wheel.
  void _jumpToValue(int value, {bool animated = true}) {
    if (!_controller.hasClients) return;
    double target;
    if (value < widget.min) {
      target = 0;
    } else if (value > widget.max) {
      target = (widget.max - widget.min) * _itemHeight;
    } else {
      target = (value - widget.min) * _itemHeight;
    }
    if (animated) {
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _controller.jumpTo(target);
    }
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    // If the current value is outside the wheel's display range
    // (e.g. user typed 3 in editor, but min is 5), don't try to
    // update from scroll — just snap the scroll back to nearest.
    if (_value < widget.min || _value > widget.max) {
      // Snap to nearest valid value without firing onChanged.
      final target = _value < widget.min
          ? 0.0
          : (widget.max - widget.min) * _itemHeight;
      if ((_controller.offset - target).abs() > 1.0) {
        _controller.jumpTo(target);
      }
      return;
    }
    final offset = _controller.offset;
    // The center of the wheel sits at `_centerPadding` of padding above
    // the first item. So an offset of `_centerPadding` corresponds to
    // the first item being centered (= value min).
    final raw = (offset / _itemHeight).round();
    final newValue = widget.min + raw;
    if (newValue != _value) {
      setState(() => _value = newValue);
      HapticFeedback.selectionClick();
      widget.onChanged(newValue);
    }
  }

  Future<void> _openEditor() async {
    // Pre-fill with the current value if it's within editor range, else
    // the editor range's nearest valid bound.
    final initial = _value.clamp(widget.editorMin, widget.editorMax);
    final controller = TextEditingController(text: initial.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrandColors.surface,
        title: Text('Custom interval',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 24, color: BrandColors.text),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            filled: true,
            fillColor: BrandColors.surfaceHigh,
            hintText:
                'minutes (${widget.editorMin}-${widget.editorMax})',
            hintStyle: GoogleFonts.plusJakartaSans(
                color: BrandColors.textMuted.withValues(alpha: 0.5)),
            suffixText: 'min',
            suffixStyle: GoogleFonts.plusJakartaSans(
                color: BrandColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: BrandColors.amber, width: 1.5),
            ),
          ),
          onSubmitted: (v) {
            final n = int.tryParse(v);
            if (n != null) Navigator.pop(ctx, n);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(color: BrandColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BrandColors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final n = int.tryParse(controller.text);
              if (n != null) Navigator.pop(ctx, n);
            },
            child: const Text('SET'),
          ),
        ],
      ),
    );
    if (result != null) {
      final clamped = result.clamp(widget.editorMin, widget.editorMax);
      setState(() => _value = clamped);
      widget.onChanged(clamped);
      // Animate to the new value, even if it's outside the visible wheel
      // range (5-120). The wheel will clamp the visual scroll position
      // to its own min/max but the underlying value is preserved.
      _jumpToValue(_value, animated: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            SizedBox(
              width: 140,
              height: _itemHeight * 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Fade overlays top & bottom
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    BrandColors.bg,
                                    BrandColors.bg.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: _itemHeight),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    BrandColors.bg.withValues(alpha: 0.0),
                                    BrandColors.bg,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Center selection indicator
                  Positioned(
                    top: _itemHeight,
                    height: _itemHeight,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: BrandColors.amber.withValues(alpha: 0.10),
                        border: Border(
                          top: BorderSide(
                              color: BrandColors.amber.withValues(alpha: 0.4),
                              width: 1.2),
                          bottom: BorderSide(
                              color: BrandColors.amber.withValues(alpha: 0.4),
                              width: 1.2),
                        ),
                      ),
                    ),
                  ),
                  // Scrollable list
                  ListView.builder(
                    controller: _controller,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.max - widget.min + 1,
                    itemExtent: _itemHeight,
                    // Top + bottom padding equal one item height. This makes
                    // the first item (value = widget.min) sit at the
                    // wheel's vertical center, and the rest scroll in from
                    // above/below. Without this, the first item sits at
                    // the top and the visible "selected" row at the
                    // middle is actually value+1.
                    padding: EdgeInsets.symmetric(vertical: _centerPadding),
                    itemBuilder: (ctx, i) {
                      final value = widget.min + i;
                      final isSelected = value == _value;
                      final distance =
                          (value - _value).abs().clamp(0, 2).toDouble();
                      final opacity = 1.0 - (distance * 0.35);
                      final scale = 1.0 - (distance * 0.15);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _value = value);
                          HapticFeedback.selectionClick();
                          widget.onChanged(value);
                          if (_controller.hasClients) {
                            _controller.animateTo(
                              i * _itemHeight,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: Center(
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: Text(
                                '$value',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: isSelected ? 28 : 22,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? BrandColors.amber
                                      : BrandColors.textMuted,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'min',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: BrandColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            // Edit button
            Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _openEditor,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BrandColors.surface.withValues(alpha: 0.6),
                    border: Border.all(
                        color: BrandColors.outline.withValues(alpha: 0.5)),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      size: 18, color: BrandColors.amber),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Min/Max label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${widget.min} min',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: BrandColors.textMuted,
                    letterSpacing: 1)),
            Text('${widget.max} min',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: BrandColors.textMuted,
                    letterSpacing: 1)),
          ],
        ),
      ],
    );
  }
}
