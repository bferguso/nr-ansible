FROM python:3.8.12
LABEL maintainer="OneTeam" 

# Non-root user
RUN useradd -ms /bin/bash runner
USER runner
WORKDIR /home/runner

# Update pip and install ansible
ENV PATH $PATH:/home/runner/.local/bin
RUN python -m pip install --upgrade pip && \
  python -m pip install ansible
