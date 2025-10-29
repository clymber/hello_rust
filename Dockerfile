# -----------------------------------------------------------------
# STAGE 1: The "Builder"
#
# This stage is our "workshop." We use the large, official Rust image
# that has `cargo` and all the build tools installed (e.g., ~1.5 GB).
# -----------------------------------------------------------------
FROM rust:1-slim AS builder

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy our project files into the container
# Copy Cargo.toml and Cargo.lock first to cache dependencies
COPY Cargo.toml Cargo.lock ./
# This is a trick to install *only* dependencies. If our .rs files change,
# Docker won't have to re-download all the dependencies.
RUN mkdir src/ && echo "fn main(){}" > src/main.rs && \
    cargo build --release

# Now copy the actual source code
COPY src/ ./src/

# Build the final, optimized release binary
# This will be very fast because the dependencies are already cached.
RUN cargo build --release

# -----------------------------------------------------------------
# STAGE 2: The "Final Image"
#
# This stage is our "shipping container." We start from a *tiny*,
# empty image that has nothing in it (e.g., ~1-2 MB).
# -----------------------------------------------------------------
FROM gcr.io/distroless/static AS final

# Set the working directory
WORKDIR /app

# The most important step!
# We copy *ONLY* the compiled program from the "builder" stage
# into this new, empty stage.
#
# !! IMPORTANT: Change `your-app-name` to the name of your
#    binary (usually the "name" field in your Cargo.toml)
COPY --from=builder /usr/src/app/target/release/your-app-name .

# Set the command to run when the container starts
ENTRYPOINT ["./your-app-name"]
