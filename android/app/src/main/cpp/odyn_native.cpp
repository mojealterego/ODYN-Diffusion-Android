#include <jni.h>
#include <android/log.h>

// JNI handshake: compiled native library is present, but generation remains
// gated until a verified stable-diffusion.cpp pipeline is implemented.
extern "C" JNIEXPORT jboolean JNICALL
Java_com_mojealterego_odyn_1diffusion_1android_MainActivity_nativeLibraryLoaded(
    JNIEnv *, jobject) {
  return JNI_TRUE;
}
