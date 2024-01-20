FROM rust:latest

# 1. Create a new empty shell project
RUN USER=root cargo new --bin rust_kafka
WORKDIR /rust_kafka

# 2. Copy our manifests
COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml

# 3. Build only the dependencies to cache them
RUN cargo build --release
RUN rm src/*.rs

# 4. Now that the dependency is built, copy your source code
COPY ./src ./src

# 5. Build for release.
RUN rm ./target/release/deps/rust_kafka*
RUN cargo install --path .

CMD ["rust_kafka"]