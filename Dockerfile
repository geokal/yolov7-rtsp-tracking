# Use an official Python runtime as a parent image
# Using 3.7-slim to match the project's Pipfile requirements
FROM python:3.7-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies for OpenCV and other libraries
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy the requirements file into the container
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Set environment variables
ENV PYTHONUNBUFFERED=1

# The command to run the tracker
# We use a placeholder for the RTSP source which will be passed via docker-compose
ENTRYPOINT ["python", "detect_and_track.py"]
