#!/usr/bin/env bash
set -eu
: "$KEYSTORE_FILE"

rm -f ./out/cmake/CMakeCache.txt
cmake . -GNinja -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_ROOT/build/cmake/android.toolchain.cmake" \
  -B./out/cmake \
  -DANDROID_PLATFORM=21 \
  -DANDROID_ABI=armeabi-v7a \
  -DCMAKE_BUILD_TYPE=Release \
  -DFORCE_COLORED_OUTPUT=TRUE
pushd ./out/cmake
ninja
popd

gradle assembleRelease
rm -rf ./out/app/
baksmali d ./app/build/intermediates/dex/release/mergeDexRelease/classes.dex -o ./out/app/smali
rm -rf ./out/apktool/smali/com/ptdhook/
mkdir -p ./out/apktool/smali/com/ptdhook/
cp ./out/app/smali/com/ptdhook/*.smali \
  ./out/apktool/smali/com/ptdhook/
rm ./out/apktool/smali/com/ptdhook/R*.smali

cp -R ./smali/ ./out/apktool/
cp -R ./res/ ./out/apktool/
cp AndroidManifest.xml ./out/apktool/
cp out/cmake/hook/libhook.so out/cmake/acd/lib__57d5__.so ./out/apktool/lib/armeabi-v7a/

pushd ./out/apktool/
apktool b -f -o ../PTD_tmp.apk
popd

rm -f ./out/PTD_modded.apk
zipalign -v 4 ./out/PTD_tmp.apk ./out/PTD_modded.apk
rm ./out/PTD_tmp.apk
apksigner sign --ks "$KEYSTORE_FILE" ./out/PTD_modded.apk
