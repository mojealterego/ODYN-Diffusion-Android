import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Deliberately does not invoke native inference until a real backend exists.
class GenerationPanel extends StatefulWidget {
  const GenerationPanel({super.key, required this.isVideo});
  final bool isVideo;

  @override
  State<GenerationPanel> createState() => _GenerationPanelState();
}

class _GenerationPanelState extends State<GenerationPanel> {
  final prompt = TextEditingController();
  int width = 512;
  int height = 512;
  int steps = 20;

  @override
  void dispose() {
    prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          key: const Key('generation_prompt'),
          controller: prompt,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: t.prompt,
            hintText: t.promptHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Text(t.noModelSelected),
        const SizedBox(height: 20),
        _choice(t.width, width, (v) => setState(() => width = v)),
        _choice(t.height, height, (v) => setState(() => height = v)),
        Row(children: [
          Expanded(child: Text(t.steps)),
          Text('$steps'),
          Expanded(child: Slider(
            value: steps.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            onChanged: (v) => setState(() => steps = v.round()),
          )),
        ]),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.play_arrow),
          label: Text(t.generate),
        ),
        const SizedBox(height: 12),
        Text(t.notReady, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _choice(String label, int value, ValueChanged<int> onChanged) {
    return Row(children: [
      Expanded(child: Text(label)),
      DropdownButton<int>(
        value: value,
        items: const [256, 512, 768, 1024]
            .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
            .toList(),
        onChanged: (n) { if (n != null) onChanged(n); },
      ),
    ]);
  }
}
