#include <jni.h>
#include <android/log.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <atomic>
#include <string>
#include "stable-diffusion.h"

namespace {
std::mutex generation_mutex;
std::atomic<sd_ctx_t*> active_context{nullptr};
std::mutex cancel_mutex;

bool write_ppm(const char* path, const sd_image_t& image) {
  if (!image.data || image.channel < 3 || !image.width || !image.height) return false;
  FILE* file = fopen(path, "wb");
  if (!file) return false;
  bool ok = fprintf(file, "P6\n%u %u\n255\n", image.width, image.height) > 0;
  for (uint32_t y = 0; ok && y < image.height; ++y) {
    for (uint32_t x = 0; ok && x < image.width; ++x) {
      const uint8_t* pixel = image.data + (static_cast<size_t>(y) * image.width + x) * image.channel;
      ok = fwrite(pixel, 1, 3, file) == 3;
    }
  }
  ok = fclose(file) == 0 && ok;
  if (!ok) remove(path);
  return ok;
}
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_mojealterego_odyn_1diffusion_1android_MainActivity_nativeLibraryLoaded(
    JNIEnv*, jobject) {
  return JNI_TRUE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_mojealterego_odyn_1diffusion_1android_MainActivity_nativeGenerateImage(
    JNIEnv* env, jobject, jstring model_path, jstring prompt,
    jint width, jint height, jint steps, jlong seed, jstring output_path) {
  if (!model_path || !prompt || !output_path || width < 64 || height < 64 ||
      width > 2048 || height > 2048 || width % 8 || height % 8 ||
      steps < 1 || steps > 150) return nullptr;
  const char* model = env->GetStringUTFChars(model_path, nullptr);
  const char* text = env->GetStringUTFChars(prompt, nullptr);
  const char* output = env->GetStringUTFChars(output_path, nullptr);
  if (!model || !text || !output) {
    if (model) env->ReleaseStringUTFChars(model_path, model);
    if (text) env->ReleaseStringUTFChars(prompt, text);
    if (output) env->ReleaseStringUTFChars(output_path, output);
    return nullptr;
  }
  std::lock_guard<std::mutex> lock(generation_mutex);
  sd_ctx_params_t context_params{};
  sd_ctx_params_init(&context_params);
  context_params.model_path = model;
  context_params.n_threads = 4;
  context_params.enable_mmap = true;
  sd_ctx_t* ctx = new_sd_ctx(&context_params);
  jstring result = nullptr;
  if (ctx && sd_ctx_supports_image_generation(ctx)) {
    { std::lock_guard<std::mutex> guard(cancel_mutex); active_context.store(ctx); }
    sd_img_gen_params_t params{};
    sd_img_gen_params_init(&params);
    params.prompt = text;
    params.width = width;
    params.height = height;
    params.sample_params.sample_steps = steps;
    params.seed = seed;
    params.batch_count = 1;
    sd_image_t* images = nullptr;
    int count = 0;
    if (generate_image(ctx, &params, &images, &count) && images && count > 0) {
      if (write_ppm(output, images[0])) result = env->NewStringUTF(output);
    }
    if (images) {
      for (int i = 0; i < count; ++i) free(images[i].data);
      free(images);
    }
    { std::lock_guard<std::mutex> guard(cancel_mutex); active_context.store(nullptr); }
  }
  if (ctx) free_sd_ctx(ctx);
  env->ReleaseStringUTFChars(model_path, model);
  env->ReleaseStringUTFChars(prompt, text);
  env->ReleaseStringUTFChars(output_path, output);
  return result;
}

extern "C" JNIEXPORT void JNICALL
Java_com_mojealterego_odyn_1diffusion_1android_MainActivity_nativeCancel(
    JNIEnv*, jobject) {
  std::lock_guard<std::mutex> guard(cancel_mutex);
  sd_ctx_t* ctx = active_context.load();
  if (ctx) sd_cancel_generation(ctx, SD_CANCEL_ALL);
}
