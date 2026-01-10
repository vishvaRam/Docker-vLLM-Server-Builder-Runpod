# Use your optimized base image
FROM vishva123/vllm-server-cuda-12.6.3

WORKDIR /workspace

# Install SSH and basic utilities
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openssh-server \
    curl \
    git \
    vim \
    tmux \
    htop && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Setup SSH (RunPod standard)
RUN mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    echo 'root:runpod' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Copy the universal entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY qwen3_nonthinking.jinja /qwen3_nonthinking.jinja

# Set sensible defaults (Can be overridden by RunPod Env Vars)
ENV MODEL=""
ENV PORT=8000
ENV TRUST_REMOTE_CODE=true
ENV GPU_UTIL=0.90
ENV TP_SIZE=1

EXPOSE 8000 22

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]