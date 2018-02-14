FROM debian:stretch

RUN apt-get update && \  
    apt-get install -y curl file gcc g++ git make openssh-client \
    autoconf automake libtool libcurl4-openssl-dev libssl-dev \
    libelf-dev libdw-dev binutils-dev zlib1g-dev libiberty-dev wget \
    xz-utils pkg-config python libsqlite3-dev sqlite3

ENV KCOV_VERSION=34 \
  CMAKE_VERSION=3.10 \
  CMAKE_BUILD=2 \
  PROTOBUF_VERSION=3.5.1

RUN mkdir ~/temp && cd ~/temp \
  && wget "https://cmake.org/files/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.${CMAKE_BUILD}.tar.gz" \
  && tar -xvzf cmake-${CMAKE_VERSION}.${CMAKE_BUILD}.tar.gz \
  && cd cmake-${CMAKE_VERSION}.${CMAKE_BUILD} \
  && ./bootstrap && make -j4 && make install

RUN cd ~/temp \
  && wget "https://github.com/google/protobuf/releases/download/v$PROTOBUF_VERSION/protobuf-all-$PROTOBUF_VERSION.tar.gz" \
  && cd protobuf-all-${PROTOBUF_VERSION} \
  && ./autogen.sh && ./configure \
  && make && make check && make install

RUN wget "https://github.com/SimonKagstrom/kcov/archive/v$KCOV_VERSION.tar.gz" \
  && tar xzf v$KCOV_VERSION.tar.gz \
  && rm v$KCOV_VERSION.tar.gz \
  && cd kcov-$KCOV_VERSION \
  && mkdir build && cd build \
  && cmake .. && make && make install \
  && cd ../.. && rm -rf kcov-$KCOV_VERSION

ENV PATH "$PATH:/root/.cargo/bin"  
ENV RUSTFLAGS "-C link-dead-code"  
ENV CFG_RELEASE_CHANNEL "nightly"

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
  && rustup update \
  && rustup install nightly \
  && rustup default nightly \
  && rustup update nightly \
  && rustup component add rustfmt-preview --toolchain=nightly


RUN bash -l -c 'echo $(rustc --print sysroot)/lib >> /etc/ld.so.conf' \
  && bash -l -c 'echo /usr/local/lib >> /etc/ld.so.conf' \
  && ldconfig