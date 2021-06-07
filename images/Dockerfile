FROM prefecthq/prefect:0.14.19-python3.8

COPY requirements.txt requirements.txt

RUN apt-get update && apt-get install -y git

RUN python3 -m pip install --upgrade pip && \
    pip install -r requirements.txt

