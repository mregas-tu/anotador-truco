import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/score_provider.dart';
import 'matchstick_widget.dart';
import 'bean_widget.dart';

class ScoreGroup extends StatelessWidget {
  final int points;
  final double size;
  final String team;
  final int groupIndex;
  final bool isDragging;

  const ScoreGroup({
    super.key,
    required this.points,
    required this.size,
    required this.team,
    this.groupIndex = 0,
    this.isDragging = false,
    // Compatibility parameters
    bool animateLast = false,
    Offset? dropOffset,
  });

  @override
  Widget build(BuildContext context) {
    final scoreProvider = Provider.of<ScoreProvider>(context);
    final double padding = size * 0.05;
    final double thickness = size * 0.1;
    final double matchHeight = size * 0.85;

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 1; i <= 5; i++)
            _buildStick(i, padding, thickness, matchHeight, scoreProvider),
        ],
      ),
    );
  }

  Widget _buildStick(int i, double p, double thickness, double mh, ScoreProvider sp) {
    if (points < i) return const SizedBox.shrink();

    final int teamPoints = team == "nosotros" ? sp.nosotros : sp.ellos;
    final int groupBase = groupIndex * 5;
    final bool isLastOverall = teamPoints == (groupBase + i);

    // Hiding logic: if DRAGGING, hide the last stick
    final bool isD = isDragging || (team == "nosotros" ? sp.isDraggingBackNosotros : sp.isDraggingBackEllos);
    if (isD && isLastOverall) return const SizedBox.shrink();

    Widget content = _getStickWidget(i, mh, sp);
    return _wrapPositioned(i, p, thickness, content, sp);
  }

  Widget _wrapPositioned(int i, double p, double thickness, Widget content, ScoreProvider sp) {
    if (sp.pointType == PointType.beans) {
      final double s = size;
      final offsets = [
        Offset(s * 0.35 - size * 0.15, s * 0.65 - size * 0.1),
        Offset(s * 0.35 - size * 0.1, s * 0.35 - size * 0.15),
        Offset(s * 0.65 - size * 0.15, s * 0.65 - size * 0.1),
        Offset(s * 0.65 - size * 0.1, s * 0.35 - size * 0.15),
        Offset(s * 0.5 - size * 0.15, s * 0.5 - size * 0.1),
      ];
      return Positioned(
        key: ValueKey("bean_${team}_${groupIndex}_$i"),
        left: offsets[i - 1].dx,
        top: offsets[i - 1].dy,
        child: content,
      );
    }

    if (i == 5) {
      return Positioned.fill(
        key: ValueKey("st_${team}_${groupIndex}_$i"),
        child: Center(child: content),
      );
    }
    
    return Positioned(
      key: ValueKey("st_${team}_${groupIndex}_$i"),
      left: i == 1 || i == 2 || i == 4 ? p : null,
      right: i == 2 || i == 3 || i == 4 ? p : null,
      top: i == 1 || i == 2 || i == 3 ? p : null,
      bottom: i == 1 || i == 3 || i == 4 ? p : null,
      width: (i == 1 || i == 3) ? thickness : null,
      height: (i == 2 || i == 4) ? thickness : null,
      child: content,
    );
  }

  Widget _getStickWidget(int i, double mh, ScoreProvider sp) {
    if (sp.pointType == PointType.beans) {
      final double angle = [0.2, -0.15, 0.4, -0.3, 0.05][i % 5];
      return Transform.rotate(
        angle: angle,
        child: BeanWidget(size: size * 0.3, seed: i, beanType: sp.currentBeanPalette.type),
      );
    }
    return MatchstickWidget(
      height: mh,
      width: size * 0.1,
      horizontal: i == 2 || i == 4,
      flipped: i == 3 || i == 4,
      diagonal: i == 5,
    );
  }
}
