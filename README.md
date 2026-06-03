# YOLOv7 RTSP Object Tracking (Containerized)

This repository is a specialized fork of the [original YOLOv7-object-tracking project](https://github.com/RizwanMunawar/yolov7-object-tracking). It has been refactored and hardened for **headless Docker environments** and **RTSP stream processing**.

## Key Enhancements in this Fork
- **Headless Compatibility**: Added automatic display detection (`check_imshow()`) to prevent crashes in Docker/X11-less environments.
- **Structured Data Export**: Introduced `--save-json` to export all tracking metadata (Track ID, Class, Bbox, Conf) into a single, portable `results.json` file.
- **Resource Hardening**: Integrated `try...finally` blocks for reliable resource cleanup (streams, writers, and memory).
- **RTSP Simulation Stack**: Added a full Docker Compose environment with MediaMTX and FFmpeg for end-to-end stream simulation.

## Prerequisites
- Docker and Docker Compose
- A sample video file named `sample_video.mp4` in the root directory.

## Quick Start (Docker)
1. **Prepare the video**:
   Place your `sample_video.mp4` in the project root.
2. **Start the stack**:
   ```bash
   docker-compose up --build
   ```
3. **View Results**:
   Tracking data will be automatically saved to `./runs/detect/object_tracking/results.json` on your host machine.

## Native Usage
If running without Docker, install the requirements:
```bash
pip install -r requirements.txt
```
Run the tracker with JSON output:
```bash
python detect_and_track.py --source "path/to/video.mp4" --save-json
```

## Argument Compatibility Audit (Docker)
| Argument | Docker Status | Notes |
| :--- | :--- | :--- |
| `--source` | Supported | Use `rtsp://rtsp-server:8554/live` for simulation. |
| `--save-json` | **New** | Recommended for structured data extraction. |
| `--view-img` | Safe | Automatically disables display in headless mode. |
| `--nosave` | Recommended | Prevents unnecessary video file creation. |

## Credits & References
- **Original Work**: [RizwanMunawar/yolov7-object-tracking](https://github.com/RizwanMunawar/yolov7-object-tracking)
- **Model**: [YOLOv7](https://github.com/WongKinYiu/yolov7) by WongKinYiu
- **Tracking Algorithm**: [SORT](https://github.com/abewley/sort) by abewley

## Troubleshooting
Refer to the [DOCKER_GUIDE.md](./DOCKER_GUIDE.md) for detailed container instructions and resource requirements.
