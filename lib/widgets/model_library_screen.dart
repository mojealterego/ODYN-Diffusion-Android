import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/model_importer.dart';
import '../core/model_manifest.dart';
import '../core/model_registry.dart';
import '../l10n/app_localizations.dart';

class ModelLibraryScreen extends StatefulWidget {
  const ModelLibraryScreen({super.key});
  @override
  State<ModelLibraryScreen> createState() => _ModelLibraryScreenState();
}

class _ModelLibraryScreenState extends State<ModelLibraryScreen> {
  ModelRegistry? registry;
  ModelImporter? importer;
  List<ModelManifest> models = const [];
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      registry = ModelRegistry(prefs);
      importer = ModelImporter(registry!);
      models = registry!.list();
    });
  }

  Future<void> _import() async {
    if (busy || importer == null) return;
    setState(() => busy = true);
    try {
      final model = await importer!.pickAndImport();
      if (!mounted) return;
      setState(() => models = registry!.list());
      if (model != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).modelImported)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).importFailed}: $error')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _remove(ModelManifest model) async {
    if (busy || importer == null) return;
    setState(() => busy = true);
    try {
      await importer!.remove(model);
      if (mounted) setState(() => models = registry!.list());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).importFailed}: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: busy || importer == null ? null : _import,
          icon: const Icon(Icons.file_open),
          label: Text(busy ? t.importingModel : t.importModel),
        ),
        const SizedBox(height: 16),
        if (models.isEmpty) Text(t.noModelSelected),
        for (final model in models)
          ListTile(
            title: Text(model.displayName),
            subtitle: Text('${model.format.name} • ${model.modelPath}'),
            trailing: IconButton(
              tooltip: t.removeModel,
              onPressed: busy ? null : () => _remove(model),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
      ],
    );
  }
}
