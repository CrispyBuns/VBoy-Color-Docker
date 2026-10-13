FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    git curl ca-certificates unzip zip \
    build-essential python3 \
    lib32stdc++6 lib32z1 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && curl -fL \
       https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
       -o /tmp/android-tools.zip \
    && mkdir -p /tmp/android-tools \
    && unzip -q /tmp/android-tools.zip -d /tmp/android-tools \
    && mv /tmp/android-tools/cmdline-tools \
       "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm -rf /tmp/android-tools /tmp/android-tools.zip

RUN yes | sdkmanager --licenses >/dev/null 2>&1 || true
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "ndk;23.2.8568313" \
    "cmake;3.22.1"

# Clone the repository and its submodules
WORKDIR /src
RUN git clone --recurse-submodules \
    https://github.com/yuk27/VBoyColor.git /src

# Startup script: update source, update submodules, rebuild, export APK
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    'cd /src' \
    'echo "Updating VBoyColor from GitHub..."' \
    'git pull --ff-only' \
    'git submodule update --init --recursive' \
    'echo "Building Android APK for Quest..."' \
    'cd /src/android' \
    'chmod +x ./gradlew' \
    'bash ./gradlew --no-daemon --stacktrace assembleDebug' \
    'APK="/src/android/app/build/outputs/apk/debug/app-debug.apk"' \
    'test -f "$APK"' \
    'mkdir -p /out' \
    'cp "$APK" /out/VBoyColor-quest-android-arm64.apk' \
    'echo "APK exported to /out/VBoyColor-quest-android-arm64.apk"' \
    > /usr/local/bin/build-vboycolor \
    && chmod +x /usr/local/bin/build-vboycolor

CMD ["/usr/local/bin/build-vboycolor"]
