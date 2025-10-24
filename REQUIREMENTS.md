# Claudito - Requirements Document

## Project Overview

Claudito is a Docker container that provides a sandboxed environment for running Claude Code. It enables users to run Claude Code in an isolated, reproducible environment without installing dependencies on their host system.

## Core Requirements

### 1. Docker Image Specifications

#### 1.1 Base Image

- **Base**: Ubuntu (latest LTS version recommended)
- **Rationale**: Wide compatibility, extensive package support, familiar to most developers

#### 1.2 Installed Components

##### 1.2.1 System Updates

- **System packages**: All existing Ubuntu packages must be updated to latest versions
- Run `apt-get update && apt-get upgrade` during build

##### 1.2.2 Core Development Tools

- **build-essential**: Essential compilation tools
  - gcc, g++, make
  - libc development files
  - dpkg-dev
- **Version Control**:
  - git (latest version)
  - git-lfs (for large file support)
- **Essential Utilities**:
  - curl
  - wget
  - ca-certificates
  - gnupg
  - unzip
  - zip
  - tar
  - vim or nano (text editor)
  - jq (JSON processor)
  - ripgrep (fast text search tool)

##### 1.2.3 Python Development Environment

- **Python 3**: Latest stable Python 3.x from Ubuntu repos
  - python3
  - python3-pip
  - python3-venv (virtual environment support)
  - python3-dev (development headers)
- **Python Tools**:
  - uv (modern Python package and project manager)
  - pipenv (dependency management)
  - poetry (alternative dependency management)
  - virtualenv
- **Common Python Libraries** (optional, for convenience):
  - python3-setuptools
  - python3-wheel

##### 1.2.4 Node.js Development Environment

- **Node.js**: Latest LTS version
  - Install via NodeSource repository or nvm
  - Should include npm package manager
  - Consider installing yarn as alternative package manager
- **Node.js Tools**:
  - npx (should come with npm)
  - node-gyp (for native addons)

##### 1.2.5 Rust Development Environment

- **Rust Toolchain**: Install via rustup
  - rustc (Rust compiler)
  - cargo (package manager and build tool)
  - rustfmt (code formatter)
  - clippy (linter)
- **Target**: Default to stable channel
- **Installation Path**: System-wide installation preferred

##### 1.2.6 Go Development Environment

- **Go**: Latest stable version
  - Install from official Go downloads or Ubuntu repos
  - Set up GOPATH and GOROOT appropriately
- **Go Tools**: Standard Go toolchain includes necessary tools
  - go build, go test, go mod, etc.

##### 1.2.7 Ruby Development Environment

- **Ruby**: Latest stable version from Ubuntu repos or rbenv
  - ruby
  - ruby-dev (development headers)
- **RubyGems**: Package manager (included with Ruby)
- **Bundler**: Dependency management
  - Install via `gem install bundler`
- **Build Dependencies**:
  - libssl-dev
  - libreadline-dev
  - zlib1g-dev

##### 1.2.8 Additional Language Support

- **Java**:
  - openjdk-21-jdk or latest LTS
  - maven and/or gradle (build tools)
- **PHP**:
  - php-cli
  - composer (dependency manager)
- **C/C++ Libraries**:
  - libssl-dev
  - libffi-dev
  - libxml2-dev
  - libxslt1-dev
  - libcurl4-openssl-dev

##### 1.2.9 Database Clients

- **PostgreSQL Client**: psql, libpq-dev
- **MySQL Client**: mysql-client, libmysqlclient-dev
- **SQLite**: sqlite3, libsqlite3-dev
- **Redis Client**: redis-tools

##### 1.2.10 Claude Code

- **Claude Code**: `@anthropic-ai/claude-code` npm package (latest version)
  - Installed globally via npm to be accessible from any directory
  - Should be executable via `claude` command
  - This must be installed AFTER Node.js is set up

#### 1.3 Working Directory

- Container should use `/src` as the default working directory
- This directory will be mounted from the host system at runtime

### 2. Container Execution Script

#### 2.1 Functionality

A wrapper script (`claudito`) should be provided to simplify container execution with the following features:

#### 2.2 Volume Mounts

- **Working directory**: Mount current directory (or specified directory) to `/src` in the container
- **Authentication**: Mount Claude Code authentication credentials
  - Default location on host: `~/.config/@anthropic-ai/claude-code/` (Linux/macOS)
  - Alternative location on host: `%APPDATA%\@anthropic-ai\claude-code\` (Windows)
  - Mount point in container: `/root/.config/@anthropic-ai/claude-code/`
  - Should preserve authentication tokens and configuration

#### 2.3 Additional Considerations

- Script should support passing arguments to Claude Code
- Should run interactively (TTY allocation)
- Should clean up after execution (use `--rm` flag)
- Consider supporting both read-only and read-write working directory mounts

### 3. Multi-Architecture Support

#### 3.1 Target Platforms

- **ARM64** (aarch64): For Apple Silicon Macs, ARM servers, Raspberry Pi
- **AMD64** (x86-64): For traditional Intel/AMD processors

#### 3.2 Build Strategy

- Use Docker buildx for multi-platform builds
- Single manifest that automatically serves correct architecture
- Both platforms should be built and tested in CI/CD

### 4. Continuous Integration/Deployment

#### 4.1 GitHub Actions Workflow

##### 4.1.1 Trigger Events

- **On Push**: Build and publish images when code is pushed to main branch
  - Ensures latest code changes are immediately available
- **Daily Cron**: Build and publish images once per day
  - Time: Recommend running at a low-traffic time (e.g., 2 AM UTC)
  - Purpose: Capture latest version of `@anthropic-ai/claude-code` even if no code changes
  - Ensures users always have access to newest Claude Code features and fixes

##### 4.1.2 Build Process

- Checkout repository
- Set up Docker buildx
- Configure multi-platform build (linux/amd64, linux/arm64)
- Build Docker image
- Tag image appropriately:
  - `latest` tag for most recent build
  - Date-based tag (e.g., `2024-01-15`) for cron builds
  - Git SHA tag for push builds
  - Semantic version tag if using releases
- Push to Docker Hub

##### 4.1.3 Authentication

- Use Docker Hub credentials stored as GitHub Secrets
- Required secrets:
  - `DOCKERHUB_USERNAME`: Docker Hub username
  - `DOCKERHUB_TOKEN`: Docker Hub access token (not password)

### 5. Docker Hub Configuration

#### 5.1 Repository Setup

- Docker Hub username is `micahflee`
- The repository is `micahflee/claudito`
- It's public

#### 5.2 GitHub Secrets Configuration

GitHub repository has the following secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

### 6. Documentation Requirements

#### 6.1 README.md

Must include:

- Project description and purpose
- Prerequisites (Docker installed)
- **Quick start guide** (must be extremely simple):
  1. Download the `claudito` script using curl from https://github.com/micahflee/claudito
  2. Copy it to `/usr/local/bin/`
  3. Make it executable with `chmod +x`
  4. Run `claudito` to start using Claude Code
- Usage examples
- Authentication setup instructions
- Configuration options
- Troubleshooting section
- Link to Claude Code documentation

#### 6.2 Installation Instructions

- Quick installation (primary method):
  - Single command to download and install the `claudito` script
  - Example: `curl -sSL https://raw.githubusercontent.com/micahflee/claudito/main/claudito -o /usr/local/bin/claudito && chmod +x /usr/local/bin/claudito`
- Alternative: Manual Docker image pull from Docker Hub (for advanced users)
- How to set up authentication for Claude Code
- Platform-specific instructions (macOS, Linux, Windows)
- Note: The script automatically pulls the Docker image on first run

#### 6.3 Development Documentation

- How to build image locally
- How to test changes
- How to contribute
- Architecture decisions

### 7. Security Considerations

#### 7.1 Sandboxing

- Container should run with appropriate isolation
- Consider running as non-root user inside container (optional enhancement)
- Document security implications of mounting host directories

#### 7.2 Secrets Management

- Authentication tokens should never be baked into image
- Always mount at runtime
- Document secure practices for credential management

### 8. Quality Requirements

#### 8.1 Image Size

- Keep image size reasonable (target: < 2GB given the comprehensive tooling)
- Use multi-stage builds if beneficial
- Clean up package manager caches after installations
- Remove unnecessary files and documentation
- Consider using `apt-get clean` and removing `/var/lib/apt/lists/*`
- Balance between image size and functionality

#### 8.2 Build Time

- Optimize layer caching
- Order Dockerfile commands from least to most frequently changing

#### 8.3 Reliability

- Images should build successfully for both architectures
- CI/CD should notify on build failures
- Include health checks if applicable

### 9. Future Enhancements (Optional)

#### 9.1 Version Pinning

- Support for installing specific Claude Code versions
- Support for pinning language runtime versions
- Tagged releases for major updates

#### 9.2 Alternative Image Variants

- Minimal variant with only essential tools
- Language-specific variants (python-only, node-only, etc.)
- Support for different base images (Alpine for smaller size, Debian)

#### 9.3 Configuration

- Environment variables for customization
- Docker Compose support for complex setups
- Support for custom tool installation via configuration file

#### 9.4 Advanced Features

- Pre-configured development environments for popular frameworks
- Integration with VS Code Dev Containers
- Support for installing additional tools at runtime

## Success Criteria

The project will be considered successful when:

1. ✅ Docker image builds successfully for both ARM64 and AMD64
2. ✅ Image is automatically published to Docker Hub on push and daily schedule
3. ✅ Users can run Claude Code in container with single command
4. ✅ Working directory is accessible and modifiable from container
5. ✅ Authentication persists across container sessions
6. ✅ All language runtimes and tools are properly installed and functional:
   - Python, Node.js, Rust, Go, Ruby are executable
   - Package managers (pip, npm, cargo, go mod, gem, bundler) work correctly
   - Build tools compile sample projects successfully
7. ✅ Documentation is clear and complete
8. ✅ CI/CD pipeline is reliable and maintainable

## Open Questions

1. Should the container support GPU access for potential future Claude Code features?
2. Should we provide pre-built binaries/scripts for different platforms?
3. What should be the default behavior if authentication is not configured?
4. Should we support docker-compose for easier configuration?
5. Do we need version tags beyond `latest`?
6. Should we create separate image variants (full vs minimal) or keep one comprehensive image?
7. Which specific versions of language runtimes should we pin, or always use latest?
8. Should database servers (PostgreSQL, MySQL, Redis) be included, or just clients?
9. Should we include container orchestration tools (Docker, Kubernetes CLIs)?
10. What testing strategy should we use to verify all tools work correctly on both architectures?
