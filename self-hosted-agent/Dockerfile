FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH=linux-x64

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       git \
       gnupg \
       jq \
       lsb-release \
       python3 \
       python3-pip \
       software-properties-common \
       unzip \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends openjdk-17-jdk maven docker.io \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    && curl -LO https://dl.k8s.io/release/v1.32.2/bin/linux/amd64/kubectl \
    && install -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl \
    && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

ARG ADO_AGENT_VERSION=4.273.0
RUN mkdir -p /azp/agent \
    && curl -fsSL "https://download.agent.dev.azure.com/agent/${ADO_AGENT_VERSION}/vsts-agent-linux-x64-${ADO_AGENT_VERSION}.tar.gz" \
       | tar -xz -C /azp/agent

WORKDIR /azp
COPY start.sh /azp/start.sh

# ADO agent refuses to run as root — create a dedicated non-root user
RUN useradd -m -s /bin/bash azpuser \
    && chown -R azpuser:azpuser /azp \
    && chmod +x /azp/start.sh

USER azpuser

ENTRYPOINT ["/azp/start.sh"]