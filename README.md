# GitHub Image Collector

A macOS-friendly shell script that clones public GitHub repositories, recursively collects **every image at any folder depth**, normalizes them, and stores them in a single organized output directory.

This tool is designed for:
- Wallpaper collections
- Image aggregation from multiple GitHub repos
- Asset archiving and normalization

---

## Demo

> Example run on a wallpaper repository:

```bash
./scripts/collect_repo_images.sh https://github.com/Bharadwaja1557/walls.git
```

After execution:

```
all-images/
├── 4K/
├── 2K/
├── Portrait/
└── Other/
```

Images are automatically categorized, converted, and de-duplicated per run.

---

## Features

- Clones **any public GitHub repository**
- Recursively scans **all folder levels**
- Supports image formats:
  - `jpg`
  - `jpeg`
  - `png`
  - `webp`
- Converts images using ImageMagick
- Strips all EXIF metadata
- Categorizes images by resolution:
  - **4K** (≥ 3840px)
  - **2K** (≥ 2560px)
  - **Portrait** (height > width)
  - **Other**
- Prevents duplicate processing:
  - Tracks last processed commit per repository
  - Skips repositories with no new commits
- Safe handling of filenames with spaces
- Detailed per-repository logs
- Global CSV summary for analytics

---

## Directory Structure

```
gitwalls/
├── scripts/
│   └── collect_repo_images.sh
├── all-images/
│   ├── 4K/
│   ├── 2K/
│   ├── Portrait/
│   └── Other/
├── _repos/
├── logs/
│   ├── <repo>.log
│   └── summary.csv
└── .repo_state.tsv
```

---

## Requirements

### Operating System
- macOS (default `bash` or `zsh` supported)

### Dependencies
- Git
- ImageMagick

Install ImageMagick using Homebrew:

```bash
brew install imagemagick
```

---

## Installation

```bash
git clone https://github.com/<your-username>/gitwalls.git
cd gitwalls
chmod +x scripts/collect_repo_images.sh
```

---

## Usage

```bash
./scripts/collect_repo_images.sh <github-repo-url>
```

---

## Logging & Stats

- Per-repo logs: `logs/<repo>.log`
- Global summary: `logs/summary.csv`

---

## License

MIT License

---

## Author

Built by **Bharadwaja**
