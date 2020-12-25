FROM nvidia/cuda:10.0-cudnn7-devel

RUN apt update -y && \
DEBIAN_FRONTEND=noninteractive apt upgrade -y --no-install-recommends && \
DEBIAN_FRONTEND=noninteractive apt install -y apt-transport-https ca-certificates gnupg software-properties-common wget && \
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
apt-add-repository -y 'deb https://apt.kitware.com/ubuntu/ bionic main' && \
apt update -y && \
DEBIAN_FRONTEND=noninteractive apt install -y apt-utils build-essential pkg-config cmake git wget curl unzip libjpeg8-dev libtiff5-dev \
libpng-dev libgtk-3-dev ffmpeg libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libavresample-dev \
libyaml-cpp-dev libgoogle-glog-dev libgflags-dev libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev \
libv4l-dev libatlas-base-dev gfortran libhdf5-serial-dev python3.7-dev python3-pip && \
apt clean
RUN python3.7 -m pip install numpy

WORKDIR /opencv
COPY opencv opencv
COPY opencv_contrib opencv_contrib

WORKDIR /opencv/build
RUN cmake \
        -D BUILD_SHARED_LIBS=OFF \
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/opencv/ready \
        -D PYTHON3_EXECUTABLE=/usr/bin/python3.7 \
        -D BUILD_opencv_python3=ON \
        -D PYTHON3_INCLUDE_DIRS=/usr/include/python3.7m \
        -D PYTHON3_LIBRARY=/usr/lib/python3.7/site-packages \
        -D WITH_CUDA=ON \
        -D ENABLE_FAST_MATH=1 \
        -D CUDA_FAST_MATH=1 \
        -D WITH_CUBLAS=1 \
        -D INSTALL_PYTHON_EXAMPLES=ON \
        -D OPENCV_EXTRA_MODULES_PATH=/opencv/opencv_contrib/modules \
        -D BUILD_opencv_cudacodec=OFF \
        ../opencv
RUN make -j `nproc`