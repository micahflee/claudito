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

# Install ripgrep (architecture-aware)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep_14.1.1-1_${ARCH}.deb && \
    dpkg -i ripgrep_14.1.1-1_${ARCH}.deb || apt-get install -f -y && \
    rm ripgrep_14.1.1-1_${ARCH}.deb && \
    apt-get clean && \
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

# Install Python package managers
RUN pip3 install --no-cache-dir --break-system-packages \
    uv \
    pipenv \
    poetry \
    virtualenv

# Install Node.js (LTS version via NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN npm install -g yarn

# Install Rust via rustup
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default && \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME && \
    rustup component add rustfmt clippy

# Install Go (architecture-aware)
ENV GOLANG_VERSION=1.23.2
ENV GOPATH=/go \
    PATH=/usr/local/go/bin:/go/bin:$PATH

RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then GOARCH="amd64"; elif [ "$ARCH" = "arm64" ]; then GOARCH="arm64"; fi && \
    curl -LO https://go.dev/dl/go${GOLANG_VERSION}.linux-${GOARCH}.tar.gz && \
    tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-${GOARCH}.tar.gz && \
    rm go${GOLANG_VERSION}.linux-${GOARCH}.tar.gz && \
    mkdir -p /go/bin

# Install Ruby and development tools
RUN apt-get update && \
    apt-get install -y \
    ruby \
    ruby-dev \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Bundler
RUN gem install bundler

# Install Java
RUN apt-get update && \
    apt-get install -y \
    openjdk-21-jdk \
    maven \
    gradle \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install PHP and Composer
RUN apt-get update && \
    apt-get install -y \
    php-cli \
    php-curl \
    php-mbstring \
    php-xml \
    php-zip \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install C/C++ development libraries
RUN apt-get update && \
    apt-get install -y \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
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

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

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
RUN mkdir -p /go/bin && \
    chown -R claudito:claudito /go /usr/local/cargo /usr/local/rustup

# Switch to unprivileged user
USER claudito

# Set working directory
WORKDIR /src

# Set entrypoint to claude
ENTRYPOINT ["claude"]
