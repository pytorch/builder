FROM debian as final
RUN apt-get update && apt-get install -y curl unzip git ssh
# Install awscli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
        unzip awscliv2.zip && \
        ./aws/install && \
        rm -rf aws*
COPY --from=continuumio/miniconda:4.7.12 /opt/conda /opt/conda
ENV PATH "/opt/conda/bin:${PATH}"
RUN conda install -yq anaconda-client
RUN pip install twine
COPY promote/ /promote
WORKDIR /promote
