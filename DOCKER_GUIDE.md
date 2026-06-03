# Docker Integration Guide for YOLOv7 Object Tracking

This guide explains how to use the containerized YOLOv7 tracking stack, optimized for headless environments and RTSP stream processing.

## Quick Start (RTSP Simulation)

1.  **Place a sample video:** Add a file named `sample_video.mp4` to the project root.
2.  **Start the stack:**
    ```bash
    docker-compose up --build
    ```
    This will start:
    *   `rtsp-server`: A MediaMTX hub for stream distribution.
    *   `rtsp-producer`: Simulates a camera by streaming the video file.
    *   `yolov7-tracker`: Performs object tracking on the stream.

## Headless Environment Compatibility

The code has been specifically hardened for Docker/Headless servers:
*   **Automatic Display Detection:** If `--view-img` is used in a headless environment, the script will automatically detect the lack of a display, print a warning, and continue processing in the background instead of crashing.
*   **Resource Safety:** Uses `try...finally` blocks to ensure video writers and streams are closed properly even if the container is stopped.

## Recommended Command Arguments

### 1. Background Processing (Fastest)
Optimized for high-performance tracking without saving visual output.
```bash
python detect_and_track.py --source rtsp://rtsp-server:8554/live --weights yolov7.pt --device cpu --nosave
```

### 2. Validation Mode (Save Video for Review)
Processes the stream and saves a video with boxes and track IDs to the host's `./runs` folder.
```bash
python detect_and_track.py --source rtsp://rtsp-server:8554/live --weights yolov7.pt --device cpu --save-with-object-id
```

### 3. Data Extraction Mode (Save Logs)
Saves tracking coordinates and IDs to `.txt` files for further analytics.
```bash
python detect_and_track.py --source rtsp://rtsp-server:8554/live --weights yolov7.pt --device cpu --save-txt --nosave
```

## Argument Compatibility Audit

| Argument | Docker Status | Notes |
| :--- | :--- | :--- |
| `--source` | **Fully Supported** | Use `rtsp://rtsp-server:8554/live` in the compose environment. |
| `--view-img` | **Safe (Gated)** | Skips window creation if no display is detected. |
| `--nosave` | **Recommended** | Prevents disk bloat in production environments. |
| `--save-txt` | **Supported** | Logs are written to the mounted `./runs` volume. |
| `--device` | **CPU/CUDA** | Use `cpu` by default; requires NVIDIA Docker for GPU. |

## Troubleshooting

*   **Result Persistence:** All outputs are saved to the `./runs` directory on your host machine via Docker volumes.
*   **Performance:** Object tracking is CPU intensive. Ensure your Docker engine is allocated at least 4 CPUs and 8GB of RAM.
