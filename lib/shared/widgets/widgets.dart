import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// English text (examiner questions, vocabulary) is always left-to-right,
/// even inside the Persian RTL interface.
class EnglishText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign align;
  const EnglishText(this.text, {super.key, this.style, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text(text, style: style, textAlign: align),
      );
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy)),
            const SizedBox(height: 8),
            child,
          ]),
        ),
      );
}

Color scoreColor(double v) => v >= 7 ? AppColors.green : (v >= 5 ? Colors.amber.shade700 : AppColors.orange);

class ScoreBar extends StatelessWidget {
  final String label;
  final double? value;
  const ScoreBar({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(
            child: value == null
                ? const Text('در دسترس نیست', style: TextStyle(color: Colors.grey))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (value! / 10).clamp(0.0, 1.0),
                      minHeight: 10,
                      color: scoreColor(value!),
                      backgroundColor: AppColors.lightBlue,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 32, child: Text(value == null ? '-' : value!.toStringAsFixed(1))),
        ]),
      );
}
