## ==============================
FROM tensorflow/tensorflow:1.14.0-gpu-py3  


ARG DEBIAN_FRONTEND=noninteractive


# todo: minimize this even more
RUN apt-get update -qq &&\
	apt-get clean &&\
    apt-get install -qq --no-install-recommends \
        libopenblas-dev liblapack-dev libx11-dev \
        libc6-dev libgdiplus\
        libavcodec-dev libavformat-dev libswscale-dev \
        libtbb2 libtbb-dev libjpeg-dev libboost-all-dev python3 \
        python-pip git g++-8 build-essential wget curl \
        make libprotobuf-dev protobuf-compiler libopencv-dev \
        libpng-dev libtiff-dev cmake apt-utils nano &&\
    rm -rf /var/lib/apt/lists/*
## ====================================================

##======================================================
RUN pip install face_alignment
RUN pip install scipy==1.3.1 
RUN pip install scikit-image==0.15.0 
RUN pip install keras==2.2.0
RUN pip install keras-vggface --no-dependencies 
RUN pip install -U keras_applications==1.0.6 --no-deps 
Run pip install -U scikit-learn 
RUN pip install ffmpeg-python

##======================= Cmake =========================================
ARG DEBIAN_FRONTEND=noninteractive
#replace cmake as old version has CUDA variable bugs
RUN wget https://github.com/Kitware/CMake/releases/download/v3.14.2/cmake-3.14.2-Linux-x86_64.tar.gz && \
    tar xzf cmake-3.14.2-Linux-x86_64.tar.gz -C /opt && \
    rm cmake-3.14.2-Linux-x86_64.tar.gz 

ENV PATH /opt/cmake-3.14.2-Linux-x86_64/bin:$PATH

## ==================== Build-time dependency libs ======================
## This will build and install opencv and dlib into an additional dummy
## directory, /root/diff, so we can later copy in these artifacts,
## minimizing docker layer size
## Protip: ninja is faster than `make -j` and less likely to lock up system

WORKDIR /root/app 

#RUN RUN apt-add-repository ppa:git-core/ppa && apt-get update && apt-get install -y git

RUN wget https://www.ffmpeg.org/releases/ffmpeg-4.0.2.tar.gz
RUN tar -xzf ffmpeg-4.0.2.tar.gz; rm -r ffmpeg-4.0.2.tar.gz
RUN cd ./ffmpeg-4.0.2; ./configure --enable-gpl --enable-libmp3lame --enable-decoder=mjpeg,png --enable-encoder=png --enable-openssl --enable-nonfree


RUN cd ./ffmpeg-4.0.2 #make
RUN  cd ./ffmpeg-4.0.2 # make install




WORKDIR /root/build-dep
ARG DEBIAN_FRONTEND=noninteractive

## ==================== Building dlib ===========================

RUN curl http://dlib.net/files/dlib-19.13.tar.bz2 -LO &&\
    tar xf dlib-19.13.tar.bz2 && \
    rm dlib-19.13.tar.bz2 &&\
    mv dlib-19.13 dlib &&\
    mkdir -p dlib/build &&\
    cd dlib/build &&\
    cmake .. -DCMAKE_CXX_FLAGS="-fPIC" && \
    cmake --build . --config Release -j 4 &&\
    make install && \
    ldconfig 

## ==================== Building OpenCV ======================
WORKDIR /root/build-dep
RUN curl https://github.com/opencv/opencv/archive/4.1.0.zip -LO &&\
    unzip 4.1.0.zip && \
    rm 4.1.0.zip &&\
    mv opencv-4.1.0 opencv

WORKDIR /root/build-dep/opencv/build

#RUN echo $PATH
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D BUILD_TIFF=ON -D WITH_TBB=ON -D BUILD_SHARED_LIBS=OFF .. &&\
    cmake --build . -j 4 && \
    make install
