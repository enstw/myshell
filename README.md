# myshell

A unified shell environment for macOS and Ubuntu Linux.

## Setup

Start with [setup.md](./setup.md).

This repo no longer expects you to run a bootstrap shell script. Install an AI agent in your CLI, open this repo, and have the agent follow [OBJECTIVE.md](./OBJECTIVE.md) to configure the shell.

The project is intended to work with different CLI AI agents, not one specific tool, and to support both macOS and Ubuntu Linux.

## Current Implementation

The repo currently provides:

- platform-aware package lists for macOS and Ubuntu Linux
- [setup.md](./setup.md) as the user-facing setup flow
- [OBJECTIVE.md](./OBJECTIVE.md) as the agent directive
- legacy scripts and config files kept in [`archive/`](./archive/) for reference only — no longer maintained

## What it sets up

- packages from the repo package lists
- Fonts from https://ens.tw/font
- zsh + Oh-My-Zsh + Powerlevel10k theme
- Preferred aliases and tools
