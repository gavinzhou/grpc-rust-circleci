FROM rust:1.27.1

ENV KCOV_VERSION=34 \
  PROTOBUF_VERSION=3.5.1 \
  GO_VERSION=1.9.4

RUN echo "deb     http://deb.debian.org/debian/    testing main contrib non-free" \
  > /etc/apt/sources.list.d/testing.list

RUN apt-get update -qq && \  
  apt-get install -y -qq curl file gcc g++ git make openssh-client \
  autoconf automake libtool libcurl4-openssl-dev libssl-dev \
  libelf-dev libdw-dev binutils-dev zlib1g-dev libiberty-dev wget \
  xz-utils pkg-config python libsqlite3-dev sqlite3 unzip && \
  apt-get -t testing install -y -qq cmake 


RUN cd /opt \
  && wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz \
  && tar -xzf go${GO_VERSION}.linux-amd64.tar.gz

RUN mkdir ~/temp && cd ~/temp \
  && wget "https://github.com/google/protobuf/releases/download/v$PROTOBUF_VERSION/protoc-$PROTOBUF_VERSION-linux-x86_64.zip" \
  && unzip protoc-$PROTOBUF_VERSION-linux-x86_64.zip \
  && mv include/* /usr/local/include/ \
  && mv bin/* /usr/local/bin/ \
  && cd ~/ && rm -rf ~/temp

RUN wget "https://github.com/SimonKagstrom/kcov/archive/v$KCOV_VERSION.tar.gz" \
  && tar xzf v$KCOV_VERSION.tar.gz \
  && rm v$KCOV_VERSION.tar.gz \
  && cd kcov-$KCOV_VERSION \
  && mkdir build && cd build \
  && cmake .. && make && make install \
  && cd ../.. && rm -rf kcov-$KCOV_VERSION

ENV PATH="/opt/go/bin:/usr/local/bin:$PATH:/root/.cargo/bin" \
  RUSTFLAGS="-C link-dead-code" \
  CFG_RELEASE_CHANNEL="nightly"

RUN rustup update \
  && rustup install stable \
  && rustup install nightly \
  && rustup default nightly \
  && rustup update nightly \
  && rustup component add rustfmt-preview --toolchain=nightly

RUN rm -rf ~/temp

RUN bash -l -c 'echo $(rustc --print sysroot)/lib >> /etc/ld.so.conf' \
  && bash -l -c 'echo /usr/local/lib >> /etc/ld.so.conf' \
  && ldconfig