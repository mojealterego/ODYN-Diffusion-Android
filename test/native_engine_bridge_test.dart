import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odyn_diffusion_android/core/native_engine_bridge.dart';
import 'package:odyn_diffusion_android/core/generation_engine.dart';
import 'package:odyn_diffusion_android/core/model_manifest.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('odyn.diffusion/native_v1');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('uninstalled engine reports unavailable', () async {
    expect(await NativeEngineBridge().isAvailable(), isFalse);
  });

  test('valid request is rejected when engine is absent', () async {
    messenger.setMockMethodCallHandler(channel, (call) async => false);
    final engine = NativeEngineBridge();
    final request = GenerationRequest(
      prompt: 'a landscape',
      model: ModelManifest(
        id: 'sd15',
        displayName: 'SD 1.5',
        format: ModelFormat.safetensors,
        capabilities: {ModelCapability.image},
        modelPath: '/models/sd15.safetensors',
      ),
    );
    await expectLater(engine.generate(request), throwsUnsupportedError);
  });

  test('bridge forwards validated request to installed native host', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'isAvailable') return true;
      if (call.method == 'generate') {
        expect(call.arguments['width'], 512);
        expect(call.arguments['modelPath'], '/models/sd15.safetensors');
        return '/output/test.png';
      }
      return null;
    });
    final request = GenerationRequest(
      prompt: 'a landscape',
      model: ModelManifest(
        id: 'sd15',
        displayName: 'SD 1.5',
        format: ModelFormat.safetensors,
        capabilities: {ModelCapability.image},
        modelPath: '/models/sd15.safetensors',
      ),
    );
    expect(await NativeEngineBridge().generate(request), '/output/test.png');
    expect(calls, ['isAvailable', 'generate']);
  });
}
