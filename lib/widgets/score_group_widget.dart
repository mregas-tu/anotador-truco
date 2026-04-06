import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/score_provider.dart';
import 'matchstick_widget.dart';
import 'bean_widget.dart';

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
  final Set<int> _alreadyAnimated = {};

  @override
  void initState() {
    super.initState();
    // If we load with points and no animation is requested, they are already animated
    if (widget.points > 0 && !widget.animateLast) {
      for (int i = 1; i <= widget.points; i++) {
        _alreadyAnimated.add(i);
      }
    }
  }

  @override
  void didUpdateWidget(ScoreGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If points decreased (undo/un-drag), remove those indices from state
    if (widget.points < oldWidget.points) {
      for (int i = widget.points + 1; i <= 5; i++) {
        _alreadyAnimated.remove(i);
      }
    }

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
          
          final int teamPoints = widget.team == "nosotros" ? scoreProvider.nosotros : scoreProvider.ellos;
          final int groupBase = widget.groupIndex * 5;
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
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    final double padding = widget.size * 0.05;
    final double thickness = widget.size * 0.1;
    
    if (scoreProvider.pointType == PointType.beans) {
      final double s = widget.size;
      switch (index) {
        case 1: return Offset(s * 0.35, s * 0.65);
        case 2: return Offset(s * 0.35, s * 0.35);
        case 3: return Offset(s * 0.65, s * 0.65);
        case 4: return Offset(s * 0.65, s * 0.35);
        case 5: return Offset(s * 0.5, s * 0.5);
        default: return Offset.zero;
      }
    }

    switch (index) {
      case 1: return Offset(padding + thickness/2, widget.size * 0.5);
      case 2: return Offset(widget.size * 0.5, padding + thickness/2);
      case 3: return Offset(widget.size - padding - thickness/2, widget.size * 0.5);
      case 4: return Offset(widget.size * 0.5, widget.size - padding - thickness/2);
      case 5: return Offset(widget.size * 0.5, widget.size * 0.5);
      default: return Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final double matchHeight = widget.size * 0.85;
    final double padding = widget.size * 0.05;

    if (scoreProvider.isResetting) {
      return _buildFrame(_key, widget.size, [
        for (int i = 1; i <= 5; i++)
          _buildReturningStick(i, padding, matchHeight)
      ]);
    }

    final bool isTeamDraggingBack = widget.isDragging;
    final int teamPoints = widget.team == "nosotros" ? scoreProvider.nosotros : scoreProvider.ellos;
    final int groupBase = widget.groupIndex * 5;
    final bool isLastGroup = (teamPoints / 5).ceil() - 1 == widget.groupIndex;

    return _buildFrame(_key, widget.size, [
      for (int i = 1; i <= 5; i++)
        _buildManagedStick(i, padding, matchHeight, isTeamDraggingBack, isLastGroup, teamPoints, groupBase, scoreProvider)
    ]);
  }

  Widget _buildFrame(Key k, double size, List<Widget> children) {
    return Container(key: k, width: size, height: size, margin: const EdgeInsets.all(4), child: Stack(children: children));
  }

  Widget _buildManagedStick(int i, double p, double mh, bool isD, bool isLG, int tp, int gb, ScoreProvider sp) {
    if (widget.points < i) return const SizedBox.shrink();
    final bool isLastStick = isLG && tp == gb + i;
    if (isD && isLastStick) return const SizedBox.shrink();

    // 🏆 SOLID STATE LOGIC:
    // If already animated, return pure Positioned. No tree structural changes ever again.
    if (_alreadyAnimated.contains(i)) {
      return _wrapPositioned(i, p, _getManagedChild(i, mh, sp), sp);
    }

    // Otherwise, we animate it
    final bool isThisReverting = sp.isReverting && sp.revertTeam == widget.team && isLastStick;
    final bool isThisFlyingOut = sp.scoringMode == ScoringMode.drag && sp.isFlyingOut && sp.flyOutTeam == widget.team && isLastStick;
    final bool isNew = sp.scoringMode == ScoringMode.drag && widget.animateLast && widget.points == i;

    Widget child = _getManagedChild(i, mh, sp);
    
    if (isThisFlyingOut && sp.flyOutTarget != null) {
      final RenderBox? r = _key.currentContext?.findRenderObject() as RenderBox?;
      if (r != null) {
        final Offset end = sp.flyOutTarget! - r.localToGlobal(_getStickLocalOffset(i));
        return _wrapPositioned(i, p, child.animate(target: 1.0).move(begin: Offset.zero, end: end, duration: 400.ms, curve: Curves.easeInCubic).fadeOut(duration: 400.ms), sp);
      }
    } else if (isThisReverting && sp.revertOffset != null) {
      final RenderBox? r = _key.currentContext?.findRenderObject() as RenderBox?;
      if (r != null) {
        final Offset begin = (sp.revertOffset! + const Offset(10, 50)) - r.localToGlobal(_getStickLocalOffset(i));
        return _wrapPositioned(i, p, child.animate(onComplete: (_) => setState(() => _alreadyAnimated.add(i)))
            .move(begin: begin, duration: 400.ms, curve: Curves.easeOutCubic).fadeIn(duration: 400.ms), sp);
      }
    } else if (isNew && _currentFlyInBegin != Offset.zero) {
      return _wrapPositioned(i, p, child.animate(onComplete: (_) => setState(() => _alreadyAnimated.add(i)))
          .move(begin: _currentFlyInBegin, duration: 400.ms, curve: Curves.easeOutCubic).fadeIn(duration: 400.ms), sp);
    }

    // Default: static if we fail animation detection but it's not in the set (fail-safe)
    return _wrapPositioned(i, p, child, sp);
  }

  Widget _getManagedChild(int i, double h, ScoreProvider sp) {
    if (sp.pointType == PointType.beans) {
      // Rotate each bean randomly for organic clusters
      final double angle = [0.2, -0.15, 0.4, -0.3, 0.05][i % 5];
      return Transform.rotate(
        angle: angle,
        child: BeanWidget(size: widget.size * 0.3),
      );
    }
    
    switch (i) {
      case 1: return MatchstickWidget(height: h);
      case 2: return MatchstickWidget(height: h, horizontal: true);
      case 3: return MatchstickWidget(height: h, flipped: true);
      case 4: return MatchstickWidget(height: h, horizontal: true, flipped: true);
      case 5: return MatchstickWidget(height: h, diagonal: true);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildReturningStick(int i, double p, double h) {
    final scoreProvider = Provider.of<ScoreProvider>(context, listen: false);
    if (widget.points < i) return const SizedBox.shrink();
    final int delay = (widget.groupIndex * 20) + (i * 10);
    return _wrapPositioned(i, p, _getManagedChild(i, h, scoreProvider).animate(delay: delay.ms).move(end: const Offset(0, 30), duration: 350.ms, curve: Curves.easeInCubic).scale(end: const Offset(0.5, 0.5), duration: 350.ms).fadeOut(duration: 350.ms), scoreProvider);
  }

  Widget _wrapPositioned(int i, double p, Widget content, ScoreProvider sp) {
    if (sp.pointType == PointType.beans) {
      final double s = widget.size;
      // clustered pile
      final offsets = [
        Offset(s * 0.35 - widget.size * 0.15, s * 0.65 - widget.size * 0.1),
        Offset(s * 0.35 - widget.size * 0.1, s * 0.35 - widget.size * 0.15),
        Offset(s * 0.65 - widget.size * 0.15, s * 0.65 - widget.size * 0.1),
        Offset(s * 0.65 - widget.size * 0.1, s * 0.35 - widget.size * 0.15),
        Offset(s * 0.5 - widget.size * 0.15, s * 0.5 - widget.size * 0.1),
      ];

      return Positioned(
        key: ValueKey("bean_$i"),
        left: offsets[i - 1].dx,
        top: offsets[i - 1].dy,
        child: content,
      );
    }

    if (i == 5) return Positioned.fill(key: ValueKey("st_$i"), child: Center(child: content));
    return Positioned(
      key: ValueKey("st_$i"),
      left: i == 1 || i == 2 || i == 4 ? p : null,
      right: i == 2 || i == 3 || i == 4 ? p : null,
      top: i == 1 || i == 2 || i == 3 ? p : null,
      bottom: i == 1 || i == 3 || i == 4 ? p : null,
      child: content,
    );
  }
}
