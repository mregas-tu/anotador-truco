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
  final bool isDragging;
  final String team; // "nosotros" or "ellos"

  const ScoreGroup({
    super.key,
    required this.points,
    required this.size,
    required this.team,
    this.isDragging = false,
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
    
    // 1. Calculate Fly-In position for adding point
    if (widget.animateLast && widget.dropOffset != null) {
      _schedulePositionUpdate(widget.dropOffset!);
    }
    
    // 2. Report global position of the last stick for potential drag-back
    if (widget.points > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final Offset localPos = _getStickLocalOffset(widget.points);
          final Offset globalPos = renderBox.localToGlobal(localPos);
          final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
          
          // Only update if this is indeed the last stick for the whole team
          final int teamPoints = widget.team == "nosotros" ? scoreProvider.nosotros : scoreProvider.ellos;
          final int groupBase = (widget.groupIndex % 3) * 5;
          if (teamPoints == groupBase + widget.points) {
            scoreProvider.updateLastStickPos(widget.team, globalPos);
          }
        }
      });
    }
  }

  void _schedulePositionUpdate(Offset dropOffset) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final Offset groupGlobalPos = renderBox.localToGlobal(Offset.zero);
        setState(() {
          _currentFlyInBegin = dropOffset - groupGlobalPos;
        });
      }
    });
  }

  Offset _getStickLocalOffset(int index) {
    final double padding = widget.size * 0.05;
    final double thickness = widget.size * 0.1; // estimate visual thickness
    switch (index) {
      case 1: return Offset(padding + thickness/2, widget.size * 0.5); // Center left
      case 2: return Offset(widget.size * 0.5, padding + thickness/2); // Center top
      case 3: return Offset(widget.size - padding - thickness/2, widget.size * 0.5); // Center right
      case 4: return Offset(widget.size * 0.5, widget.size - padding - thickness/2); // Center bottom
      case 5: return Offset(widget.size * 0.5, widget.size * 0.5); // Center center
      default: return Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final double matchHeight = widget.size * 0.85;
    final double padding = widget.size * 0.05;

    final bool isTeamResetting = scoreProvider.isResetting;

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

    final bool isTeamDraggingBack = widget.isDragging;
    
    final int teamPoints = widget.team == "nosotros" ? scoreProvider.nosotros : scoreProvider.ellos;
    final int groupBase = (widget.groupIndex % 3) * 5;
    final bool isLastGroup = (teamPoints / 5).ceil() - 1 == (widget.groupIndex % 3);

    return Container(
      key: _key,
      width: widget.size,
      height: widget.size,
      margin: const EdgeInsets.all(4),
      child: Stack(
        children: [
          _buildPositionedStick(1,
              isTeamDraggingBack: isTeamDraggingBack,
              isLastStick: isLastGroup && teamPoints == groupBase + 1,
              left: padding,
              top: padding,
              bottom: padding,
              child: MatchstickWidget(height: matchHeight)),
          _buildPositionedStick(2,
              isTeamDraggingBack: isTeamDraggingBack,
              isLastStick: isLastGroup && teamPoints == groupBase + 2,
              left: padding,
              right: padding,
              top: padding,
              child: MatchstickWidget(height: matchHeight, horizontal: true)),
          _buildPositionedStick(3,
              isTeamDraggingBack: isTeamDraggingBack,
              isLastStick: isLastGroup && teamPoints == groupBase + 3,
              right: padding,
              top: padding,
              bottom: padding,
              child: MatchstickWidget(height: matchHeight, flipped: true)),
          _buildPositionedStick(4,
              isTeamDraggingBack: isTeamDraggingBack,
              isLastStick: isLastGroup && teamPoints == groupBase + 4,
              left: padding,
              right: padding,
              bottom: padding,
              child: MatchstickWidget(height: matchHeight, horizontal: true, flipped: true)),
          _buildPositionedStick(5,
              isTeamDraggingBack: isTeamDraggingBack,
              isLastStick: isLastGroup && teamPoints == groupBase + 5,
              isDiagonal: true,
              child: MatchstickWidget(height: matchHeight, diagonal: true)),
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
      {required bool isTeamDraggingBack,
      required bool isLastStick,
      double? left,
      double? right,
      double? top,
      double? bottom,
      bool isDiagonal = false,
      required Widget child}) {
    if (widget.points < index) return const SizedBox();

    // Hide the stick if it's currently being dragged back by the user
    if (isTeamDraggingBack && isLastStick) {
      return const SizedBox();
    }

    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    final bool isThisReverting = scoreProvider.isReverting && 
                                scoreProvider.revertTeam == widget.team &&
                                isLastStick;

    final bool isThisFlyingOut = scoreProvider.scoringMode == ScoringMode.drag &&
                                scoreProvider.isFlyingOut && 
                                scoreProvider.flyOutTeam == widget.team &&
                                isLastStick;

    final bool isNew = scoreProvider.scoringMode == ScoringMode.drag &&
                      widget.animateLast && widget.points == index;
    final bool hasValidBegin = _currentFlyInBegin != Offset.zero;

    // Apply animation wrapper only if needed
    Widget animatedChild = child;
    if (isThisFlyingOut && scoreProvider.flyOutTarget != null) {
      final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final Offset groupGlobalPos = renderBox.localToGlobal(Offset.zero);
        final Offset localPos = _getStickLocalOffset(index);
        final Offset boxRelGroup = scoreProvider.flyOutTarget! - groupGlobalPos;
        final Offset flyOutEnd = boxRelGroup - localPos;
        
        animatedChild = animatedChild.animate(target: 1.0)
            .move(begin: Offset.zero, end: flyOutEnd, duration: 400.ms, curve: Curves.easeInCubic)
            .fadeOut(duration: 400.ms);
      }
    } else if (isThisReverting && scoreProvider.revertOffset != null) {
      final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final Offset groupGlobalPos = renderBox.localToGlobal(Offset.zero);
        final Offset localPos = _getStickLocalOffset(index);
        final Offset globalStickCenter = groupGlobalPos + localPos;
        
        // feedback is dragged by top-left by default, but we used pointerDragAnchorStrategy
        // which centers it on the pointer. revertedOffset is the top-left of the widget!
        // We need the center of the dropped widget.
        final Offset droppedWidgetCenter = scoreProvider.revertOffset! + const Offset(10, 50); 
        final Offset revertBegin = droppedWidgetCenter - globalStickCenter;

        animatedChild = animatedChild.animate()
            .move(begin: revertBegin, duration: 400.ms, curve: Curves.easeOutCubic)
            .fadeIn(duration: 400.ms);
      }
    } else if (isNew && hasValidBegin) {
      animatedChild = animatedChild.animate()
          .move(begin: _currentFlyInBegin, duration: 400.ms, curve: Curves.easeOutCubic)
          .fadeIn(duration: 400.ms);
    }

    return _wrapPositioned(
      index,
      left,
      right,
      top,
      bottom,
      isDiagonal,
      animatedChild,
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
