import 'package:flutter/services.dart';
import 'generation_engine.dart';

/// Versioned contract for an Android host that bundles a real native engine.
/// No native library is currently bundled: calls fail explicitly.
class NativeEngineBridge implements GenerationEngine {
  NativeEngineBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('odyn.diffusion/native_v1');

  final MethodChannel _channel;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<String> generate(GenerationRequest request) async {
    final errors = request.validate();
    if (errors.isNotEmpty) throw ArgumentError(errors.join(', '));
    if (!await isAvailable()) {
      throw UnsupportedError('Native diffusion engine is not installed');
    }
    final output = await _channel.invokeMethod<String>('generate', {
      'prompt': request.prompt,
      'modelPath': request.model.modelPath,
      'width': request.width,
      'height': request.height,
      'steps': request.steps,
      'frames': request.frames,
      'seed': request.seed,
    });
    if (output == null || output.isEmpty) {
      throw StateError('Native engine returned no output path');
    }
    return output;
  }

  @override
  Future<void> cancel() async {
    if (await isAvailable()) await _channel.invokeMethod<void>('cancel');
  }
}
