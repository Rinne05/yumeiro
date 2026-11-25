import 'package:material_ui/material_ui.dart';

import '../../theme/theme.dart';

double normalizeRating(double value) => (value.clamp(0.0, 5.0) * 2).round() / 2;

String formatRating(double value) => value == value.toInt()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.value,
    required this.size,
    required this.color,
    this.spacing = 0,
    this.expand = false,
  });

  final double value;
  final double size;
  final Color color;
  final double spacing;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final icons = YumeiroTheme.of(context).icons;
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        spacing: spacing,
        children: List.generate(5, (index) {
          final threshold = index + 1;
          final icon = Icon(
            value >= threshold
                ? icons.starFilled
                : value >= threshold - .5
                ? icons.starHalf
                : icons.star,
            size: size,
            color: color,
          );
          return expand ? Expanded(child: icon) : icon;
        }),
      ),
    );
  }
}
