#! to execute: 
    # install docker buildx if not installed
    # docker buildx build --target final --output type=local,dest=./output .
FROM ubuntu:22.04 AS builder 

# Install essential packages
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    openjdk-11-jdk \
    python3 \
    vim \
    python3-pip \
    git \
    wget \
    unzip \
    maven \
    cmake \
    build-essential \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Install pipenv globally
RUN pip3 install --upgrade pip && pip3 install pipenv mako types-requests types-python-dateutil

# Install GraphicsFuzzs
WORKDIR /opt
COPY . /opt/graphicsfuzz
RUN cd graphicsfuzz && \
    git submodule update --init && \
    mvn package -e -DskipTests=true

# WORKDIR /opt
# COPY ./glslang /opt/glslang
# RUN cd glslang && \
#     ./update_glslang_sources.py && \
#     mkdir -p build && \
#     cd build && \
#     cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(pwd)/install" .. && \
#     make -j4 install

# RUN cp /opt/glslang/build/install/bin/* /opt/graphicsfuzz/graphicsfuzz/target/graphicsfuzz/bin/Linux
ENV PATH="/opt/graphicsfuzz/graphicsfuzz/target/graphicsfuzz/bin/Linux:${PATH}"
ENV PATH="/opt/graphicsfuzz/graphicsfuzz/target/graphicsfuzz/python/drivers:${PATH}"

FROM builder AS builder-final
WORKDIR /opt/graphicsfuzz/temp
COPY test_suite/references /opt/graphicsfuzz/temp/references
COPY test_suite/donors /opt/graphicsfuzz/temp/donors
RUN glsl-generate --vulkan ./references ./donors 100 syn /output

FROM scratch AS final
COPY --from=builder-final /output test_suite/output

