FROM frolvlad/alpine-glibc:alpine-3.9
LABEL author="bientd88@gmail.com"

# Set Env
ENV CONDA_DIR="/opt/conda"
ENV PATH="$CONDA_DIR/bin:$PATH"
WORKDIR /app

# Install conda
RUN CONDA_VERSION="4.5.12" && \
    CONDA_MD5_CHECKSUM="866ae9dff53ad0874e1d1a60b1ad1ef8" && \
    \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates bash tzdata git&& \
    \
    mkdir -p "$CONDA_DIR" && \
    wget "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh" -O miniconda.sh && \
    echo "$CONDA_MD5_CHECKSUM  miniconda.sh" | md5sum -c && \
    bash miniconda.sh -f -b -p "$CONDA_DIR" && \
    echo "export PATH=$CONDA_DIR/bin:\$PATH" > /etc/profile.d/conda.sh && \
    rm miniconda.sh && \
    \
    conda update --all --yes && \
    conda config --set auto_update_conda False && \
    rm -r "$CONDA_DIR/pkgs/" && \
    \
    apk del --purge .build-dependencies && \
    \
    mkdir -p "$CONDA_DIR/locks" && \
    chmod 777 "$CONDA_DIR/locks"

# Install dependences
RUN apk add --no-cache -U --virtual=build-dependencies ca-certificates tzdata git cmake gcc make g++ jpeg-dev openjpeg-dev openssl-dev zlib-dev freetype jpeg libjpeg openjpeg zlib libxml2-dev libxslt-dev build-base openblas-dev bash

RUN git clone https://github.com/davisking/dlib.git && cd dlib && git checkout tags/v19.14 -b v19.14

# Download cuda
RUN apk add wget alpine-sdk perl && \
    wget http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux.run

RUN chmod +x cuda_*_linux.run && \
    ./cuda_*_linux.run --tar mxvf && \
    cp InstallUtils.pm /usr/share/perl5/core_perl/ && \
    ./run_files/cuda-linux64-rel-*.run -noprompt && \
    rm -rf cuda_*_linux.run \
           /run_files \
           InstallUtils.pm \
           cuda-installer.pl \
           uninstall_cuda.pl

# Install python lib
ADD  tv_engine_conda.yml .
RUN conda env update -f tv_engine_conda.yml
ENV PATH=/usr/local/cuda-7.5/bin:$PATH LD_LIBRARY_PATH=/usr/local/cuda-7.5/lib64:$LD_LIBRARY_PATH
RUN cd dlib && python setup.py install --yes USE_AVX_INSTRUCTIONS --yes DLIB_USE_CUDA

RUN conda install -y -c akode face_recognition_models
RUN pip install face_recognition
RUN rm -rf /app/*

# Clean up
RUN rm -r "$CONDA_DIR/pkgs/" && \
    apk del build-dependencies && \
    rm -rf ~/.pip && \
    rm -rf ~/.conda && \
    rm -rf /var/cache/apk/*
