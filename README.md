# Pixel Hero NES

An original 8-bit platformer prototype for the Nintendo Entertainment System (NES), written in 6502 assembly with ca65/ld65.

## Controls

- **Left / Right:** Move
- **A:** Jump

## Build locally

Install `cc65` and GNU Make, then run:

```sh
make
```

The build creates `pixel-hero.nes`. Open it in an NES emulator such as Mesen or FCEUX.

## Build on GitHub

Pushes to `main` trigger the GitHub Actions workflow. Download `Pixel-Hero-NES` from the completed workflow run's Artifacts section.

## Current prototype

- NROM / Mapper 0 ROM layout
- 32 KiB PRG-ROM and 8 KiB CHR-ROM
- Controller input, movement, jump, gravity, and ground collision
- Generated background and player graphics

This is an early playable prototype, not a finished commercial game yet.
