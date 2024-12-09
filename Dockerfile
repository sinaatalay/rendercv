# Use the official Python image as a base
FROM python:3.12-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file and any other necessary files
COPY pyproject.toml ./

# Install Hatch and any dependencies
RUN pip install --no-cache-dir hatch

# Copy the rest of your application code, including the .gitmodules file
COPY . .

# Install git for the submodules
RUN apt update && apt install git -y 

# Initialize and update submodules
RUN git submodule update --init --recursive

# Build the package using Hatch
RUN hatch build

# Install the built package
RUN pip install dist/*.whl

# Change to data directory
WORKDIR /data