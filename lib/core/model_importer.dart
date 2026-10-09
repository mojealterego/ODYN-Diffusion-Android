import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'model_manifest.dart';
import 'model_registry.dart';

/// Imports a picked model into app-private storage; never treats a SAF URI as a file path.
class ModelImporter {
  ModelImporter(this.registry);
  final ModelRegistry registry;

  Future<ModelManifest?> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gguf', 'safetensors'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final picked = result.files.single;
    if (picked.path == null) throw const FileSystemException('File picker returned no readable path');
    return importFile(File(picked.path!), displayName: picked.name);
  }

  Future<ModelManifest> importFile(File source, {required String displayName}) async {
    final extension = displayName.toLowerCase().split('.').last;
    if (extension != 'gguf' && extension != 'safetensors') {
      throw const FormatException('Unsupported model extension');
    }
    if (!await source.exists() || await source.length() == 0) {
      throw const FileSystemException('Model file missing or empty');
    }
    final root = await getApplicationSupportDirectory();
    final folder = Directory('${root.path}/models');
    await folder.create(recursive: true);
    final id = '${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
    final target = File('${folder.path}/$id.$extension');
    try {
      await source.openRead().pipe(target.openWrite());
      if (await target.length() != await source.length()) {
        throw const FileSystemException('Incomplete model copy');
      }
      final model = ModelManifest(
        id: id,
        displayName: displayName,
        format: extension == 'gguf' ? ModelFormat.gguf : ModelFormat.safetensors,
        capabilities: {ModelCapability.image},
        modelPath: target.path,
      );
      await registry.add(model);
      return model;
    } catch (_) {
      if (await target.exists()) await target.delete();
      rethrow;
    }
  }

  Future<void> remove(ModelManifest model) async {
    // Only delete files within the application's own models directory.
    final root = await getApplicationSupportDirectory();
    final folder = Directory('${root.path}/models');
    final file = File(model.modelPath);
    if (!await folder.exists()) {
      throw const FileSystemException('Model storage directory missing');
    }
    final safeParent = await folder.absolute.resolveSymbolicLinks();
    final parent = await file.parent.absolute.resolveSymbolicLinks();
    if (parent != safeParent || await FileSystemEntity.isLink(file.path)) {
      throw const FileSystemException('Refusing to delete external or linked file');
    }
    if (await file.exists()) await file.delete();
    await registry.remove(model.id);
  }
}
