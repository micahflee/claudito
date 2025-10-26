# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claudito is a Docker container that runs Claude Code in a sandboxed environment. The project consists of:

- **Dockerfile**: Multi-architecture Ubuntu 24.04 image with comprehensive development tooling
- **claudito script**: Bash wrapper that runs the Docker container with proper volume mounts and security settings
- **GitHub Actions workflow**: Automated builds on push and daily cron (2 AM UTC) to capture latest Claude Code versions

## Key Architecture

### Docker Image Structure

The Dockerfile builds a minimal development environment with:
- Python 3 runtime with pip and virtualenv
- Node.js LTS with npm and yarn (required for Claude Code)
- Database clients: PostgreSQL, MySQL, SQLite, Redis (clients only, no servers)
- Build tools: build-essential, git, and common C/C++ libraries (libssl-dev, libffi-dev)
- Claude Code installed globally via npm as the entrypoint

**Additional languages**: Users can install other language runtimes as needed using `sudo apt install` (e.g., `golang-go`, `rustc`, `openjdk-21-jdk`, `ruby`, `php-cli`)

**Security model**: The container runs as unprivileged user `claudito` (UID 1000) with sudo access. The wrapper script applies security restrictions via Docker flags (--cap-drop=ALL with selective cap-add).

### Volume Mounts

The `claudito` script uses:
1. **Working directory**: `$(pwd)` → `/src` in container (read-write bind mount)
2. **Claudito config**: Docker named volume `claudito-config` → `/home/claudito/.config/@anthropic-ai/claude-code` (to persist authentication)

Using a named volume for configuration ensures reliable persistence across all platforms (especially Docker Desktop) and avoids file synchronization issues with bind mounts.

### Multi-Architecture Support

Builds for both `linux/amd64` and `linux/arm64` using Docker buildx. Architecture-specific handling exists for:
- ripgrep (downloads .deb for correct architecture)
- Go (downloads correct GOARCH tarball)

## Common Commands

### Build Docker Image Locally
```bash
docker build -t micahflee/claudito:latest .
```

For multi-arch build (requires buildx):
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t micahflee/claudito:latest .
```

### Test the Container
```bash
# Run in current directory
./claudito

# Test with arguments
./claudito --help
./claudito --version
```

### Verify Installed Tools
```bash
# Run container with shell override
docker run --rm -it micahflee/claudito:latest bash

# Then test core tools:
python3 --version
node --version
claude --version
psql --version
mysql --version

# Install additional languages as needed:
sudo apt install golang-go
sudo apt install rustc cargo
sudo apt install openjdk-21-jdk
```

### GitHub Actions

Workflow triggers:
- Push to `main` branch (tags: `latest`, `<git-sha>`)
- Daily cron at 2 AM UTC (tags: `latest`, `YYYY-MM-DD`)
- Manual via workflow_dispatch

Required secrets: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`

## Development Guidelines

### Dockerfile Modifications

**Layer ordering for caching**: The Dockerfile orders installations from least to most frequently changing:
1. System packages and core tools
2. Python and Node.js runtimes (stable versions)
3. Claude Code (changes frequently, hence daily rebuilds)
4. System upgrades (final layer before user creation)

**Design philosophy**: The image includes only Python and Node.js by default. Users can install additional languages on-demand via `sudo apt install`, keeping the base image small and fast to pull.

### Updating the claudito Script

The script uses `exec` to replace itself with the Docker process, ensuring signals pass through correctly. Any changes should preserve:
- Docker health checks
- Security options (--cap-drop=ALL with selective cap-add)

### Testing Multi-Architecture Builds

Local testing requires Docker buildx and QEMU:
```bash
docker buildx create --use
docker buildx build --platform linux/amd64,linux/arm64 -t test .
```

## Important Files

- `Dockerfile` - Image definition with all development tools
- `claudito` - Wrapper script for running the container
- `.github/workflows/docker-build.yml` - CI/CD pipeline
- `REQUIREMENTS.md` - Comprehensive project requirements and specifications
- `README.md` - User-facing documentation

## Notes

- The daily cron build ensures users get the latest `@anthropic-ai/claude-code` even without code changes
- Image size is ~800MB-1GB thanks to minimal language runtime approach
- Container runs as non-root user for security but has passwordless sudo for installing additional tools
- The wrapper always pulls the latest image before running (line 78 of claudito script)
- Users can install additional language runtimes (Go, Rust, Java, Ruby, PHP) as needed via apt
