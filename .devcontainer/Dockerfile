FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    helm \
    alsa-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Task
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d

# Install pre-commit
RUN pip3 install pre-commit

# Install helm-unittest plugin
RUN helm plugin install https://github.com/quintush/helm-unittest

# Set the working directory
WORKDIR /workspace

# Copy the repository files
COPY . /workspace

# Run pre-commit install
RUN pre-commit install

# Define the entrypoint
ENTRYPOINT ["/bin/bash"]
