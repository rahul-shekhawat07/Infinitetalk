# InfiniteTalk RunPod Serverless
# L4 / CUDA 12.8 / PyTorch 2.8
FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

# System dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        git \
        git-lfs \
        libgl1 \
        libglib2.0-0 \
        libsndfile1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Basic Python dependencies
# IMPORTANT:
# Do NOT install xformers, sageattention or flash-attn here.
RUN pip install --no-cache-dir \
        misaki[en] \
        "huggingface_hub[hf_transfer]" \
        runpod \
        websocket-client \
        librosa

WORKDIR /

# ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI && \
    cd /ComfyUI && \
    pip install --no-cache-dir -r requirements.txt

# Remove unnecessary frontend packages for headless Serverless use
RUN pip uninstall -y \
        comfyui-frontend-package \
        comfyui-workflow-templates \
        comfyui-workflow-templates-core \
        comfyui-workflow-templates-media-api \
        comfyui-workflow-templates-media-image \
        comfyui-workflow-templates-media-other \
        comfyui-workflow-templates-media-video \
        comfyui-embedded-docs \
        2>/dev/null || true

# Custom nodes
RUN cd /ComfyUI/custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF && \
    git clone https://github.com/kijai/ComfyUI-KJNodes && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite && \
    git clone https://github.com/orssorbit/ComfyUI-wanBlockswap && \
    git clone https://github.com/kijai/ComfyUI-MelBandRoFormer && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper

# Install custom-node requirements
RUN cd /ComfyUI/custom_nodes/ComfyUI-GGUF && \
    pip install --no-cache-dir -r requirements.txt && \
    cd /ComfyUI/custom_nodes/ComfyUI-KJNodes && \
    pip install --no-cache-dir -r requirements.txt && \
    cd /ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite && \
    pip install --no-cache-dir -r requirements.txt && \
    cd /ComfyUI/custom_nodes/ComfyUI-MelBandRoFormer && \
    pip install --no-cache-dir -r requirements.txt && \
    cd /ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper && \
    pip install --no-cache-dir -r requirements.txt

# Remove git metadata and Python cache
RUN find /ComfyUI -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true && \
    find /ComfyUI -name "*.pyc" -delete 2>/dev/null || true && \
    find /ComfyUI -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Copy worker files
COPY . /

RUN chmod +x /entrypoint.sh

ENV RUNPOD_PING_INTERVAL=3000
ENV RUNPOD_INIT_TIMEOUT=600

CMD ["/entrypoint.sh"]