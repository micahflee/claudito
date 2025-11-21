# Claudito

This project is a docker container for running [Claude Code](https://docs.claude.com/claude-code) in a sandbox, so it can't access your data outside of your working directory, your SSH keys, or anything else.

(Claudito, as in Little Claude, because it's Claude playing in a sandbox... get it?)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- A [Claude Code account](https://claude.ai/) with API access

## Quick Start

Install claudito:

```bash
curl -sSL https://raw.githubusercontent.com/micahflee/claudito/main/claudito -o /usr/local/bin/claudito && \
chmod +x /usr/local/bin/claudito
```

Change to your project's folder and run claudito:

```bash
claudito
```

That's it! The first run will automatically pull the Docker image and start Claude Code in your current directory.

## Usage

### Basic Usage

Run claudito in your current directory:

```bash
claudito
```

### Passing Arguments

Pass any arguments directly to Claude Code:

```bash
claudito --help
claudito --version
```

### Mounting Additional Volumes

By default, claudito mounts your current working directory to `/src` in the container. If you need to access additional directories, you can mount them using the `--volume` (or `-V`) flag:

```bash
# Mount a single additional directory
claudito --volume /path/on/host:/path/in/container

# Mount multiple directories
claudito --volume /data:/data --volume /config:/etc/myapp

# Mount with read-only access
claudito --volume /readonly/data:/data:ro

# Combine with Claude Code arguments
claudito --volume /extra/data:/data -- --help
```

**Note:** The `--volume` flag is a claudito option and must come before any Claude Code arguments. Use `--` to explicitly separate claudito options from Claude Code arguments if needed.

## Authentication

Claude Code requires authentication with your Anthropic API key. On first run, Claude Code will guide you through the authentication process.

Your credentials are stored in a Docker named volume (`claudito-config`) that persists across container runs. This is completely separate from any Claude Code installation you may have on your host system.
