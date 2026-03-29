import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/score_provider.dart';
import 'matchstick_widget.dart';

class ScoreGroup extends StatefulWidget {
  final int points;
  final bool animateLast;
  final Offset? dropOffset;
  final double size;
  final int groupIndex; 
  final String team; // "nosotros" or "ellos"

  const ScoreGroup({
    super.key,
    required this.points,
    required this.size,
    required this.team,
    this.groupIndex = 0,
    this.animateLast = false,
    this.dropOffset,
  });

  @override
  State<ScoreGroup> createState() => _ScoreGroupState();
}

class _ScoreGroupState extends State<ScoreGroup> {
  final GlobalKey _key = GlobalKey();
  Offset _currentFlyInBegin = Offset.zero;

  @override
  void didUpdateWidget(ScoreGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only calculate Fly-In (Adding point)
    if (widget.animateLast && widget.dropOffset != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final RenderBox? renderBox =
            _key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final Offset groupGlobalPos = renderBox.localToGlobal(Offset.zero);
          setState(() {
            _currentFlyInBegin = widget.dropOffset! - groupGlobalPos;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final double matchHeight = widget.size * 0.85;
    final double padding = widget.size * 0.05;

    final bool isTeamResetting = widget.team == "nosotros" 
        ? scoreProvider.nosotrosResetting 
        : scoreProvider.ellosResetting;

    if (isTeamResetting) {
      return Container(
        key: _key,
        width: widget.size,
        height: widget.size,
        margin: const EdgeInsets.all(4),
        child: Stack(
          children: [
            _buildReturningStick(1,
                left: padding,
                top: padding,
                bottom: padding,
                child: MatchstickWidget(height: matchHeight)),
            _buildReturningStick(2,
                left: padding,
                right: padding,
                top: padding,
                child: MatchstickWidget(height: matchHeight, horizontal: true)),
            _buildReturningStick(3,
                right: padding,
                top: padding,
                bottom: padding,
                child: MatchstickWidget(height: matchHeight, flipped: true)),
            _buildReturningStick(4,
                left: padding,
                right: padding,
                bottom: padding,
                child: MatchstickWidget(height: matchHeight, horizontal: true, flipped: true)),
            _buildReturningStick(5,
                isDiagonal: true,
                child: MatchstickWidget(height: matchHeight, diagonal: true)),
          ],
        ),
      );
    }

    return Container(
      key: _key,
      width: widget.size,
      height: widget.size,
      margin: const EdgeInsets.all(4),
      child: Stack(
        children: [
          _buildPositionedStick(1,
              left: padding,
              top: padding,
              bottom: padding,
              child: MatchstickWidget(height: matchHeight)), // Head Top
          _buildPositionedStick(2,
              left: padding,
              right: padding,
              top: padding,
              child: MatchstickWidget(height: matchHeight, horizontal: true)), // Head Right
          _buildPositionedStick(3,
              right: padding,
              top: padding,
              bottom: padding,
              child: MatchstickWidget(height: matchHeight, flipped: true)), // Head Bottom
          _buildPositionedStick(4,
              left: padding,
              right: padding,
              bottom: padding,
              child: MatchstickWidget(height: matchHeight, horizontal: true, flipped: true)), // Head Left
          _buildPositionedStick(5,
              isDiagonal: true,
              child: MatchstickWidget(height: matchHeight, diagonal: true)), // Head Bottom-Right
        ],
      ),
    );
  }

  Widget _buildReturningStick(int index,
      {double? left,
      double? right,
      double? top,
      double? bottom,
      bool isDiagonal = false,
      required Widget child}) {
    if (widget.points < index) return const SizedBox();

    final int baseDelay = widget.groupIndex * 20; // Very tight group stagger

    return _wrapPositioned(
      index,
      left,
      right,
      top,
      bottom,
      isDiagonal,
      child.animate(delay: (baseDelay + index * 10).ms).move(
            end: const Offset(0, 30), 
            duration: 350.ms,
            curve: Curves.easeInCubic,
          ).scale(
            end: const Offset(0.5, 0.5), 
            duration: 350.ms,
          ).fadeOut(duration: 350.ms),
    );
  }

  Widget _buildPositionedStick(int index,
      {double? left,
      double? right,
      double? top,
      double? bottom,
      bool isDiagonal = false,
      required Widget child}) {
    if (widget.points < index) return const SizedBox();

    final bool isNew = widget.animateLast && widget.points == index;
    final bool hasValidBegin = _currentFlyInBegin != Offset.zero;

    return _wrapPositioned(
      index,
      left,
      right,
      top,
      bottom,
      isDiagonal,
      child.animate(target: 1.0)
          .move(
            begin: (isNew && hasValidBegin) ? _currentFlyInBegin : Offset.zero,
            duration: (isNew && hasValidBegin) ? 400.ms : 0.ms,
            curve: Curves.easeOutCubic,
          )
          .fadeIn(duration: isNew ? 400.ms : 0.ms),
    );
  }

  Widget _wrapPositioned(int index, double? left, double? right, double? top,
      double? bottom, bool isDiagonal, Widget content) {
    if (isDiagonal) {
      return Positioned.fill(
          key: ValueKey("stick_$index"), child: Center(child: content));
    }
    return Positioned(
      key: ValueKey("stick_$index"),
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: content,
    );
  }
}
