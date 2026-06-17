FROM ubuntu:24.04 AS builder

RUN apt-get update && apt-get install -y git libpq-dev curl build-essential libgpgme-dev pkg-config libssl-dev libglib2.0-dev libostree-dev
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup.sh && \
    sh rustup.sh -y -q

ADD . /src
RUN cd /src && /root/.cargo/bin/cargo build --release

RUN git clone https://github.com/openpak/flat-manager-hooks.git
RUN cd flat-manager-hooks && /root/.cargo/bin/cargo build --release

FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
        flatpak flatpak-builder ostree libpq5 ca-certificates catatonit rsync openssh-client && \
    rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/gpg /usr/bin/gpg2

COPY --from=builder /src/target/release/flat-manager /usr/local/bin/flat-manager
COPY --from=builder /flat-manager-hooks/target/release/flathub-hooks /usr/local/bin/flathub-hooks
COPY --from=builder /src/target/release/flat-manager-client  /usr/local/bin/flat-manager-client

ENV RUST_BACKTRACE=1

ENTRYPOINT ["/usr/bin/catatonit", "--"]
CMD ["/usr/local/bin/flat-manager"]
