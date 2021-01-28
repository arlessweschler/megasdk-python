FROM python:slim

ENV LANG C.UTF-8
ENV MEGA_SDK_VERSION '3.7.9'

RUN set -ex && \
        savedAptMark="$(apt-mark showmanual)" && \
    apt-get -qq update && apt-get -qq install --no-install-recommends -y git g++ gcc autoconf automake \
    m4 libtool qt4-qmake make libqt4-dev libcurl4-openssl-dev \
    libcrypto++-dev libsqlite3-dev libc-ares-dev \
    libsodium-dev libnautilus-extension-dev \
    libssl-dev libfreeimage-dev swig && \
    git clone https://github.com/meganz/sdk.git sdk && \
    cd sdk && \
    git checkout v$MEGA_SDK_VERSION && \
    ./autogen.sh && \
    ./configure --disable-silent-rules --enable-python --disable-examples && \
    make -j$(nproc --all) && \
    cd bindings/python/ && \
    python3 setup.py bdist_wheel && \
    cd dist/ && \
    pip3 install --no-cache-dir megasdk-$MEGA_SDK_VERSION-*.whl && \
    apt-mark auto '.*' > /dev/null && \
    apt-mark manual $savedAptMark && \
    find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
                | awk '/=>/ { print $(NF-1) }' \
                | sort -u \
                | xargs -r dpkg-query --search \
                | cut -d: -f1 \
                | sort -u \
                | xargs -r apt-mark manual && \
        apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
        rm -rf /var/lib/apt/lists/*
