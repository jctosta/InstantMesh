FROM --platform=linux/amd64 nvidia/cuda:12.1.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Set Coordinated Universal Time
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime
RUN apt update && apt install -y tzdata && apt clean && rm -rf /var/lib/apt/lists/*

# Install CONDA

## Install base utilities
RUN apt-get update \
    && apt-get install -y build-essential \
    && apt-get install -y wget \
    && apt-get install -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

## Install miniconda
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda

## Put conda in path so we can use conda activate
ENV PATH=$CONDA_DIR/bin:$PATH

# Configure Conda Env
RUN conda init bash \
    && . ~/.bashrc \
    && conda create --name instantmesh python=3.10 -y \
    && conda activate instantmesh \
    && pip install -U pip \
    && conda install Ninja -y \
    && conda install cuda -c nvidia/label/cuda-12.1.0 -y \
    && pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121 \
    && pip install xformers==0.0.22.post7 \
    && pip install triton

# Set the working directory
WORKDIR /app

# Copy the assets
COPY ./assets /app/assets
COPY ./configs /app/configs
COPY ./src /app/src
COPY ./examples /app/examples
COPY ./zero123plus /app/zero123plus
COPY ./app.py /app/app.py
COPY ./run.py /app/run.py
COPY ./train.py /app/train.py
COPY ./requirements.txt /app/requirements.txt

# Install Requirements
RUN . ~/.bashrc \
    && conda activate instantmesh \
    && pip install -r /app/requirements.txt

# Expose port 43839
EXPOSE 43839

# Activate the conda env and Start the gradio demo
CMD . ~/.bashrc && conda activate instantmesh && python /app/app.py

ENV DEBIAN_FRONTEND=