import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/generation_engine.dart';
import '../core/model_manifest.dart';
import '../core/model_registry.dart';
import '../core/native_engine_bridge.dart';
import '../l10n/app_localizations.dart';

/// Uses registered models and only enables generation with an available host.
class GenerationPanel extends StatefulWidget {
  const GenerationPanel({super.key, required this.isVideo, this.engine});
  final bool isVideo;
  final GenerationEngine? engine;

  @override
  State<GenerationPanel> createState() => _GenerationPanelState();
}

class _GenerationPanelState extends State<GenerationPanel> {
  final prompt = TextEditingController();
  late final GenerationEngine engine = widget.engine ?? NativeEngineBridge();
  List<ModelManifest> models = const [];
  String? selectedId;
  String? outputPath;
  String? error;
  bool available = false;
  bool running = false;
  int width = 512;
  int height = 512;
  int steps = 20;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = ModelRegistry(prefs).list()
          .where((m) => m.capabilities.contains(
              widget.isVideo ? ModelCapability.video : ModelCapability.image))
          .toList();
      final ready = await engine.isAvailable();
      if (!mounted) return;
      setState(() {
        models = entries;
        available = ready;
        if (!entries.any((m) => m.id == selectedId)) selectedId = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> _generate() async {
    if (running || !available || selectedId == null) return;
    final model = models.where((m) => m.id == selectedId).firstOrNull;
    if (model == null) return;
    final request = GenerationRequest(
      prompt: prompt.text,
      model: model,
      width: width,
      height: height,
      steps: steps,
      frames: widget.isVideo ? 16 : 1,
    );
    final errors = request.validate();
    if (errors.isNotEmpty) {
      setState(() => error = errors.join(', '));
      return;
    }
    setState(() { running = true; error = null; outputPath = null; });
    try {
      final result = await engine.generate(request);
      if (mounted) setState(() => outputPath = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => running = false);
    }
  }

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
          onChanged: (_) => setState(() {}),
          maxLines: 4,
          decoration: InputDecoration(
            labelText: t.prompt,
            hintText: t.promptHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        if (models.isEmpty) Text(t.noModelSelected)
        else DropdownButton<String>(
          isExpanded: true,
          value: selectedId,
          hint: Text(t.selectModelFirst),
          items: models.map((m) => DropdownMenuItem(
            value: m.id, child: Text(m.displayName),
          )).toList(),
          onChanged: running ? null : (id) => setState(() => selectedId = id),
        ),
        TextButton.icon(
          onPressed: running ? null : _refresh,
          icon: const Icon(Icons.refresh),
          label: Text(t.models),
        ),
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
            onChanged: running ? null : (v) => setState(() => steps = v.round()),
          )),
        ]),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: !running && available && selectedId != null &&
                  prompt.text.trim().isNotEmpty ? _generate : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(t.generate),
        ),
        if (running) const LinearProgressIndicator(),
        if (!available) Text(t.notReady, textAlign: TextAlign.center),
        if (error != null) SelectableText(error!),
        if (outputPath != null) ...[
          SelectableText(outputPath!),
          if (!widget.isVideo && outputPath!.toLowerCase().endsWith('.png'))
            Image.file(File(outputPath!), errorBuilder: (_, __, ___) =>
              SelectableText(outputPath!)),
        ],
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
        onChanged: running ? null : (n) { if (n != null) onChanged(n); },
      ),
    ]);
  }
}
