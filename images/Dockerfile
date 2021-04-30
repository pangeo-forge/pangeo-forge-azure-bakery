FROM prefecthq/prefect:0.14.17-python3.8

RUN python3 -m pip install --upgrade pip && \
    pip install prefect[azure,kubernetes]==0.14.17 && \
    pip install kubernetes==12.0.1

