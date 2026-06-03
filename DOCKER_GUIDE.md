### **Tutorial Guide for YOLOv7 Object Tracking with RTSP Simulation**

Below is a self-contained tutorial for containerizing the YOLOv7 object tracking project and integrating it with an RTSP simulation stack (Server + Producer). This guide follows a structured approach to transition from local execution to a containerized multi-service environment.

---

### **Project Folder Structure and File List**

```
yolov7-object-tracking/
├── Dockerfile              # AI Inference Environment
├── docker-compose.yaml     # Service Orchestration
├── detect_and_track.py     # Main Entry Point
├── yolov7.pt               # Model Weights
├── requirements.txt        # Python Dependencies
├── sample_video.mp4        # Source for RTSP Simulation
├── sort.py                 # Tracking Logic
├── models/                 # YOLOv7 Model Definitions
├── utils/                  # Utility Functions
└── runs/                   # Output Directory (Mounted at Runtime)
```

---

## **Step-by-Step Tutorial**

### **Stage 1: Containerization of the Inference Engine**

**What**
Encapsulation of the YOLOv7 and SORT tracking environment into a reproducible Docker image.

**Why**
Eliminates environment drift (e.g., OpenCV dependency issues, Python version mismatches) and ensures consistent performance across different host machines.

**Dockerfile Implementation**
Create a file named `Dockerfile` in the root directory with the following content:

```dockerfile
FROM python:3.7-slim

WORKDIR /app

# Install system dependencies for OpenCV and glib
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["python", "detect_and_track.py"]
```

**Where it helps**
Provides a baseline for deployment in cloud or edge environments where manual setup is impractical.

---

### **Stage 2: RTSP Simulation Stack**

**What**
Integration of a MediaMTX server and an FFmpeg-based producer to simulate a live IP camera feed. The producer uses a loop flag to ensure the stream never ends.

**Service Implementation**
Add the following services to your `docker-compose.yaml`:

```yaml
  rtsp-server:
    image: bluenviron/mediamtx:latest
    container_name: rtsp-server
    ports:
      - "8554:8554"

  rtsp-producer:
    image: jrottenberg/ffmpeg:4.4-ubuntu
    container_name: rtsp-producer
    depends_on:
      - rtsp-server
    volumes:
      - ./sample_video.mp4:/video/sample_video.mp4:ro
    command: >
      -re -stream_loop -1 -i /video/sample_video.mp4
      -c copy -f rtsp rtsp://rtsp-server:8554/live
```

**How they work together**
1. **rtsp-server (MediaMTX)**: Acts as a central ingestion and distribution hub. It listens for incoming RTSP streams and makes them available to consumers via a specific path (e.g., `/live`).
2. **rtsp-producer (FFmpeg)**: Acts as the "camera." It reads the local video file, processes it, and "pushes" the data to the server at the internal address `rtsp://rtsp-server:8554/live`.
3. **Internal Networking**: Docker's internal DNS allows the producer to find the server using the service name `rtsp-server` instead of an IP address.

**FFmpeg Command Breakdown**
- `-re`: Reads the input at its native frame rate (simulates real-time capture).
- `-stream_loop -1`: Loops the input video indefinitely (-1 means infinite).
- `-i /video/sample_video.mp4`: Specifies the input video file path inside the container.
- `-c copy`: Copies the stream without re-encoding (extremely low CPU usage).
- `-f rtsp`: Sets the output format to RTSP.
- `rtsp://rtsp-server:8554/live`: The target destination for the stream.

**Why**
Allows for full-lifecycle testing of network-based inference without requiring physical hardware. The infinite loop simulates a 24/7 live camera environment, ensuring the tracker remains active.

**Where it helps**
Validation of stream reconnection logic, network buffer handling, and multi-stream processing capabilities.

---

### **Stage 3: Service Orchestration and Runtime**

**What**
Using `docker-compose` to manage dependencies, internal networking, and volume persistence.

**Why**
Ensures the RTSP server is reachable via internal DNS (`rtsp-server`) and automates the startup sequence of the producer and consumer.

**Docker Compose Implementation**
Create a file named `docker-compose.yaml` in the root directory with the following content:

```yaml
version: '3.8'

services:
  rtsp-server:
    image: bluenviron/mediamtx:latest
    container_name: rtsp-server
    ports:
      - "8554:8554"

  rtsp-producer:
    image: jrottenberg/ffmpeg:4.4-ubuntu
    container_name: rtsp-producer
    depends_on:
      - rtsp-server
    volumes:
      - ./sample_video.mp4:/video/sample_video.mp4:ro
    command: >
      -re -stream_loop -1 -i /video/sample_video.mp4
      -c copy -f rtsp rtsp://rtsp-server:8554/live

  yolov7-tracker:
    build: .
    container_name: yolov7-tracker
    depends_on:
      - rtsp-server
      - rtsp-producer
    command: >
      --source rtsp://rtsp-server:8554/live
      --weights yolov7.pt
      --device cpu
      --nosave
    volumes:
      - ./runs:/app/runs
```

**How to run**
```bash
# Execute the full stack
docker-compose up --build
```

**Where it helps**
Integrated testing of the complete pipeline from capture to inference and result persistence.

---

### **Stage 4: Results Persistence and Analysis**

**What**
Mounting the local `runs/` directory to the container to persist inference results (videos and logs).

**Why**
Allows for post-execution analysis of tracking accuracy and performance metrics without needing to enter the container filesystem.

**Where it helps**
Benchmarking different model weights or confidence thresholds across repeated simulation runs.

---

### **Technical Notes and Troubleshooting**

- **Startup Latency**: The `yolov7-tracker` may attempt to connect before the `rtsp-producer` has initialized the stream. If a connection error occurs, restart the tracker service: `docker-compose restart yolov7-tracker`.
- **Headless Execution**: The `--nosave` flag is used by default in Compose to prevent unnecessary I/O. For visual validation, check the generated files in the `./runs` directory on the host.
- **Resource Limits**: Object tracking is CPU intensive. Ensure Docker Desktop is allocated at least 4 CPUs and 8GB of RAM for optimal performance.
