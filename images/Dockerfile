FROM prefecthq/prefect:0.14.19-python3.8

COPY requirements.txt requirements.txt

RUN apt-get update && apt-get install -y git apt-transport-https ca-certificates curl \
  && rm -rf /var/lib/apt/lists/* \
  && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN python3 -m pip install --upgrade pip && \
    pip install -r requirements.txt

