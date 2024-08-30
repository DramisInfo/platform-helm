FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl gnupg lsb-release git python3-pip

# Install Helm
RUN curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
    apt-get install -y apt-transport-https --no-install-recommends && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update && \
    apt-get install -y helm

# Install pre-commit
RUN pip3 install pre-commit

# Set the working directory
WORKDIR /workspace

# Copy the repository files
COPY . /workspace

# Install pre-commit hooks
RUN pre-commit install

# Define the entrypoint
ENTRYPOINT ["/bin/bash"]