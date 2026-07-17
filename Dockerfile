
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

ARG RUST_TOOLCHAIN=1.94.0

ARG ARM_GNU_TOOLCHAIN_VERSION=12.2.rel1
ARG ARM_GNU_TOOLCHAIN_DIR=arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-elf
ARG ARM_GNU_TOOLCHAIN_URL=https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-elf.tar.xz

ARG ZIG_VERSION=0.15.2
ARG ZIG_ARCH=x86_64
ARG ZIG_DIR=zig-${ZIG_ARCH}-linux-${ZIG_VERSION}
ARG ZIG_URL=https://ziglang.org/download/${ZIG_VERSION}/${ZIG_DIR}.tar.xz

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bison \
        build-essential \
        ca-certificates \
        clang \
        cmake \
        cpio \
        curl \
        device-tree-compiler \
        dosfstools \
        fdisk \
        file \
        flex \
        gcc-aarch64-linux-gnu \
        gdisk \
        git \
        ipxe-qemu \
        jq \
        libclang-dev \
        libxml2-utils \
        lld \
        llvm-dev \
        make \
        mtools \
        musl-tools \
        ninja-build \
        python3.12 \
        python3.12-dev \
        python3.12-venv \
        qemu-system-arm \
        rsync \
        unzip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/toolchains \
    && curl --fail --location --show-error \
        "${ARM_GNU_TOOLCHAIN_URL}" \
        --output /tmp/arm-gnu-toolchain.tar.xz \
    && tar \
        --extract \
        --file=/tmp/arm-gnu-toolchain.tar.xz \
        --directory=/opt/toolchains \
    && rm /tmp/arm-gnu-toolchain.tar.xz \
    && test -x \
        "/opt/toolchains/${ARM_GNU_TOOLCHAIN_DIR}/bin/aarch64-none-elf-gcc"

RUN mkdir -p /opt/toolchains \
    && curl --fail --location --show-error \
        "${ZIG_URL}" \
        --output /tmp/zig.tar.xz \
    && tar \
        --extract \
        --file=/tmp/zig.tar.xz \
        --directory=/opt/toolchains \
    && rm /tmp/zig.tar.xz \
    && test -x "/opt/toolchains/${ZIG_DIR}/zig"

ENV ZIG_ROOT=/opt/toolchains/${ZIG_DIR}
ENV ARM_GNU_TOOLCHAIN_ROOT=/opt/toolchains/${ARM_GNU_TOOLCHAIN_DIR}

ENV CARGO_HOME=/opt/rust/cargo
ENV RUSTUP_HOME=/opt/rust/rustup
ENV RUSTUP_TOOLCHAIN=${RUST_TOOLCHAIN}

ENV PATH=/opt/rust/cargo/bin:/opt/toolchains/${ARM_GNU_TOOLCHAIN_DIR}/bin:/opt/toolchains/${ZIG_DIR}:${PATH}

RUN curl --proto '=https' \
        --tlsv1.2 \
        --fail \
        --silent \
        --show-error \
        https://sh.rustup.rs \
        | sh -s -- \
            -y \
            --no-modify-path \
            --profile minimal \
            --default-toolchain "${RUST_TOOLCHAIN}" \
    && rustup default "${RUST_TOOLCHAIN}" \
    && rustup component add \
        rust-src \
        --toolchain "${RUST_TOOLCHAIN}" \
    && rustup target add \
        x86_64-unknown-linux-musl \
        aarch64-unknown-linux-musl \
        --toolchain "${RUST_TOOLCHAIN}" \
    && rustc +"${RUST_TOOLCHAIN}" --version \
    && cargo +"${RUST_TOOLCHAIN}" --version \
    && rustup show active-toolchain

WORKDIR /opt/template-pd-manifest

COPY . .

RUN python3.12 -m venv /opt/carrels-env/pyenv \
    && /opt/carrels-env/pyenv/bin/pip install --upgrade \
        pip \
        setuptools \
        wheel \
    && /opt/carrels-env/pyenv/bin/pip install \
        --requirement \
        /opt/template-pd-manifest/microkit/requirements.txt \
    && /opt/carrels-env/pyenv/bin/pip install \
        --no-cache-dir \
        pyelftools

RUN set -eux; \
    rustc --version --verbose; \
    cargo --version --verbose; \
    rustup show; \
    env | sort | grep -E '^(RUST|CARGO)' || true

RUN cd /opt/template-pd-manifest/microkit \
    && /opt/carrels-env/pyenv/bin/python ./build_sdk.py \
        --sel4=../seL4 \
        --skip-tar \
        --skip-doc \
        --boards=qemu_virt_aarch64

RUN /opt/carrels-env/pyenv/bin/pip install \
    /opt/template-pd-manifest/sdfgen

RUN mkdir -p /opt/carrels-env \
    && ln -s \
        /opt/template-pd-manifest/microkit/release/microkit-sdk-2.1.0-dev \
        /opt/carrels-env/microkit-sdk \
    && ln -s \
        /opt/template-pd-manifest/lionsos \
        /opt/carrels-env/lionsos

ENV MICROKIT_SDK=/opt/carrels-env/microkit-sdk
ENV LIONSOS=/opt/carrels-env/lionsos

ENV PATH=/opt/carrels-env/pyenv/bin:/opt/rust/cargo/bin:/opt/toolchains/${ARM_GNU_TOOLCHAIN_DIR}/bin:/opt/toolchains/${ZIG_DIR}:${PATH}

RUN set -eux; \
    python3.12 --version; \
    python -c "import sdfgen"; \
    python -c "from elftools.elf.elffile import ELFFile"; \
    rustc --version; \
    cargo --version; \
    zig version; \
    test "$(zig version)" = "${ZIG_VERSION}"; \
    aarch64-none-elf-gcc --version; \
    aarch64-linux-gnu-gcc --version; \
    llvm-ranlib --version; \
    ld.lld --version; \
    xmllint --version; \
    qemu-system-aarch64 --version; \
    flex --version; \
    bison --version; \
    command -v lex; \
    command -v fdisk; \
    command -v sgdisk; \
    command -v mkfs.fat; \
    command -v mcopy; \
    command -v jq; \
    test -d "${MICROKIT_SDK}"; \
    test -d "${LIONSOS}"; \
    test -x "${MICROKIT_SDK}/bin/microkit"; \
    test -d "${MICROKIT_SDK}/board/qemu_virt_aarch64"

WORKDIR /workspace/carrels

CMD ["/bin/bash"]
