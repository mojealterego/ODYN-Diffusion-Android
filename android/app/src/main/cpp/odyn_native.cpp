#include <jni.h>
#include <android/log.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <atomic>
#include <string>
#include <vector>
#include <zlib.h>
#include "stable-diffusion.h"

namespace {
std::mutex generation_mutex;
std::atomic<sd_ctx_t*> active_context{nullptr};
std::mutex cancel_mutex;

void write_u32(std::vector<uint8_t>& bytes, uint32_t value) {
  for (int shift = 24; shift >= 0; shift -= 8) bytes.push_back(static_cast<uint8_t>(value >> shift));
}

void png_chunk(std::vector<uint8_t>& png, const char* tag, const std::vector<uint8_t>& payload) {
  write_u32(png, static_cast<uint32_t>(payload.size()));
  const size_t offset = png.size();
  png.insert(png.end(), tag, tag + 4);
  png.insert(png.end(), payload.begin(), payload.end());
  const uLong checksum = crc32(0L, png.data() + offset, static_cast<uInt>(png.size() - offset));
  write_u32(png, static_cast<uint32_t>(checksum));
}

bool write_png(const char* path, const sd_image_t& image) {
  if (!image.data || image.channel < 3 || !image.width || !image.height) return false;
  const size_t stride = static_cast<size_t>(image.width) * 3;
  std::vector<uint8_t> raw((stride + 1) * image.height);
  for (uint32_t y = 0; y < image.height; ++y) {
    const size_t row = static_cast<size_t>(y) * (stride + 1);
    raw[row] = 0;
    for (uint32_t x = 0; x < image.width; ++x) {
      const uint8_t* pixel = image.data + (static_cast<size_t>(y) * image.width + x) * image.channel;
      for (int c = 0; c < 3; ++c) raw[row + 1 + static_cast<size_t>(x) * 3 + c] = pixel[c];
    }
  }
  uLongf compressed_size = compressBound(static_cast<uLong>(raw.size()));
  std::vector<uint8_t> compressed(compressed_size);
  if (compress2(compressed.data(), &compressed_size, raw.data(), static_cast<uLong>(raw.size()), Z_BEST_SPEED) != Z_OK) return false;
  compressed.resize(compressed_size);
  std::vector<uint8_t> png = {137, 80, 78, 71, 13, 10, 26, 10};
  std::vector<uint8_t> ihdr;
  write_u32(ihdr, image.width);
  write_u32(ihdr, image.height);
  ihdr.insert(ihdr.end(), {8, 2, 0, 0, 0});
  png_chunk(png, "IHDR", ihdr);
  png_chunk(png, "IDAT", compressed);
  png_chunk(png, "IEND", {});
  FILE* file = fopen(path, "wb");
  if (!file) return false;
  const bool ok = fwrite(png.data(), 1, png.size(), file) == png.size();
  const bool closed = fclose(file) == 0;
  if (!ok || !closed) remove(path);
  return ok && closed;
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
      if (write_png(output, images[0])) result = env->NewStringUTF(output);
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
