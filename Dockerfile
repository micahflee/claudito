FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set locale
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Security labels
LABEL security.sandbox="true" \
    security.user="unprivileged:claudito:1000" \
    security.capabilities="restricted" \
    security.sudo="enabled" \
    org.opencontainers.image.description="Sandboxed Claude Code environment with full development tooling"

# Install core dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    curl \
    wget \
    ca-certificates \
    gnupg \
    unzip \
    zip \
    tar \
    vim \
    nano \
    jq \
    git \
    git-lfs \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python 3 and development tools
RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    python3-wheel \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install virtualenv for Python virtual environments
RUN pip3 install --no-cache-dir --break-system-packages virtualenv

# Install Node.js (LTS version via NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Yarn (small utility, useful for Node.js projects)
RUN npm install -g yarn

# Install common C/C++ development libraries (needed by many Python packages)
RUN apt-get update && \
    apt-get install -y \
    libssl-dev \
    libffi-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install database clients
RUN apt-get update && \
    apt-get install -y \
    postgresql-client \
    libpq-dev \
    mysql-client \
    libmysqlclient-dev \
    sqlite3 \
    libsqlite3-dev \
    redis-tools \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install sudo
RUN apt-get update && \
    apt-get install -y sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade all packages to latest versions
RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create unprivileged user (remove any existing UID 1000 user first)
RUN if id 1000 2>/dev/null; then userdel -r $(id -un 1000); fi && \
    useradd -m -s /bin/bash -u 1000 claudito && \
    echo "claudito ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Make sure shared directories are accessible by claudito user
# Pre-create .claude directory so volume mount has correct permissions
RUN mkdir -p /home/claudito/.claude && \
    chown -R claudito:claudito /home/claudito

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to unprivileged user
USER claudito

# Configure npm to use user-local directory for global packages
RUN mkdir -p /home/claudito/.npm-global && \
    npm config set prefix '/home/claudito/.npm-global'

# Update PATH to include npm global bin directory
ENV PATH="/home/claudito/.npm-global/bin:${PATH}"

# Install Claude Code as claudito user (enables auto-updates)
RUN npm install -g @anthropic-ai/claude-code

# Set working directory
WORKDIR /src

# Set entrypoint to our wrapper script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
