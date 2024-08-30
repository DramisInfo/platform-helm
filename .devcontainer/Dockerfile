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

# Install Helm unittest plugin
RUN helm plugin install https://github.com/quintush/helm-unittest


# Install pre-commit
RUN pip3 install pre-commit

# Install Docker
RUN apt-get update && \
    apt-get install -y docker.io

# Install k3d
RUN curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/


# Install k9s
RUN curl -sS https://webinstall.dev/k9s | bash && \
    mv /root/.local/bin/k9s /usr/local/bin/k9s

# Set the working directory
WORKDIR /workspace

# Copy the repository files
COPY . /workspace

#run pre-commit install
RUN pre-commit install

# Define the entrypoint
ENTRYPOINT ["/bin/bash"]
