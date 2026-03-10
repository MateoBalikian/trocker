# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**trocker** is a sports (football/soccer) tracking and analysis desktop application. It uses computer vision (YOLO via Ultralytics + OpenCV) to detect and track players/objects on video, and presents results through a PySide6/QML GUI.

## Environment

The project uses a local Python 3.11.9 venv located at `trocker/` (same name as the project root). Activate it before running anything:

```bash
# Windows
trocker\Scripts\activate

# Then run scripts
python test.py
```

## Key Dependencies (installed in venv)

- **PySide6** — GUI framework with QML support
- **OpenCV** (`opencv-python`) — video capture and image processing
- **Ultralytics** (YOLO) + **PyTorch/torchvision** — object detection and tracking
- **NumPy, SciPy, Matplotlib, Polars** — numerical processing and data analysis

## Project Structure

```
src/
  modules/        # Python backend modules (detection, tracking, analysis logic)
  qml/
    components/   # QML UI components
projects/         # User project files (video sessions, exports)
assets/           # App images, demo GIFs
fonts/            # BebasNeue, Poppins, Arial — used in UI rendering
test.py           # Smoke test for PySide6 availability
```

The architecture separates Python processing logic (`src/modules/`) from the QML/PySide6 UI layer (`src/qml/`). Backend modules expose data to QML via PySide6 properties and signals.

## Running

```bash
# Verify PySide6 works
python test.py

# Main entry point (once created, likely src/ or root)
python main.py
```

No build step, linter, or test suite is configured yet.
