FROM nvidia/cuda:10.0-cudnn7-devel as opencv_builder

RUN DEBIAN_FRONTEND=noninteractive apt update --assume-yes
RUN DEBIAN_FRONTEND=noninteractive apt full-upgrade --assume-yes
RUN DEBIAN_FRONTEND=noninteractive apt install --assume-yes apt-transport-https ca-certificates gnupg software-properties-common wget
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
RUN apt-add-repository -y 'deb https://apt.kitware.com/ubuntu/ bionic main'
RUN DEBIAN_FRONTEND=noninteractive apt update --assume-yes
RUN DEBIAN_FRONTEND=noninteractive apt install --assume-yes apt-utils build-essential pkg-config cmake git wget curl unzip libjpeg8-dev libtiff5-dev \
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
        -D BUILD_DOCS=OFF \
        -D BUILD_PERF_TESTS=OFF \
        -D BUILD_TESTS=OFF \
        ../opencv
RUN make -j `nproc`
RUN make install

FROM nvidia/cuda:10.0-cudnn7-devel as openpose_builder

COPY --from=opencv_builder /opencv/ready /

RUN DEBIAN_FRONTEND=noninteractive apt --assume-yes update
RUN DEBIAN_FRONTEND=noninteractive apt --assume-yes full-upgrade
RUN DEBIAN_FRONTEND=noninteractive apt --assume-yes install build-essential libatlas-base-dev libprotobuf-dev \
libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler libgflags-dev libgoogle-glog-dev liblmdb-dev \
python-setuptools python-dev build-essential python-pip python3-setuptools python3.7-dev build-essential python3-pip \
opencl-headers ocl-icd-opencl-dev libviennacl-dev apt-transport-https ca-certificates gnupg software-properties-common \
wget git libgtk-3-0 ffmpeg
RUN DEBIAN_FRONTEND=noninteractive apt --assume-yes install --no-install-recommends libboost-all-dev
RUN pip install --upgrade numpy protobuf
RUN python3.7 -m pip install numpy protobuf
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
RUN apt-add-repository -y 'deb https://apt.kitware.com/ubuntu/ bionic main'
RUN DEBIAN_FRONTEND=noninteractive apt update --assume-yes
RUN DEBIAN_FRONTEND=noninteractive apt install cmake  --assume-yes


WORKDIR /staf/STAF
COPY STAF .
RUN chmod 700 models/getModels.sh && cd models && sh getModels.sh

WORKDIR /staf/build
RUN cmake -D CMAKE_INSTALL_PREFIX=/staf/ready -D BUILD_python=ON -D USE_OPENCV=ON ../STAF
RUN make -j `nproc`
RUN make install

FROM ubuntu:18.04 as blender_builder

RUN DEBIAN_FRONTEND=noninteractive apt --assume-yes update
RUN DEBIAN_FRONTEND=noninteractive apt --assume-yes full-upgrade
RUN DEBIAN_FRONTEND=noninteractive apt install --assume-yes apt-transport-https ca-certificates gnupg software-properties-common wget
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
RUN apt-add-repository -y 'deb https://apt.kitware.com/ubuntu/ bionic main'
RUN DEBIAN_FRONTEND=noninteractive apt update --assume-yes
RUN DEBIAN_FRONTEND=noninteractive apt install --assume-yes sudo build-essential git subversion \
libx11-dev libxxf86vm-dev libxcursor-dev libxi-dev libxrandr-dev libxinerama-dev libglew-dev cmake && apt clean

WORKDIR /blender-git/blender
COPY blender .
RUN chmod 777 build_files/build_environment/install_deps.sh && build_files/build_environment/install_deps.sh

WORKDIR /blender-git/build
RUN cmake \
            -U *SNDFILE* \
            -U PYTHON* \
            -U *BOOST* \
            -U *Boost* \
            -U *OPENCOLORIO* \
            -U *OPENEXR* \
            -U *OPENIMAGEIO* \
            -U *LLVM* \
            -U *CYCLES* \
            -U *OPENSUBDIV* \
            -U *OPENVDB* \
            -U *COLLADA* \
            -U *FFMPEG* \
            -U *ALEMBIC* \
            -U *USD* \
            -D CMAKE_INSTALL_PREFIX=/blender-git/ready \
            -D WITH_INSTALL_PORTABLE=ON \
            -D WITH_CODEC_SNDFILE=ON \
            -D PYTHON_VERSION=3.7 \
            -D WITH_OPENCOLORIO=ON \
            -D OPENCOLORIO_ROOT_DIR=/opt/lib/ocio \
            -D OPENEXR_ROOT_DIR=/opt/lib/openexr \
            -D WITH_OPENIMAGEIO=ON \
            -D OPENIMAGEIO_ROOT_DIR=/opt/lib/oiio \
            -D WITH_CYCLES_OSL=ON \
            -D WITH_LLVM=ON \
            -D LLVM_VERSION=6.0 \
            -D OSL_ROOT_DIR=/opt/lib/osl \
            -D WITH_OPENSUBDIV=ON \
            -D OPENSUBDIV_ROOT_DIR=/opt/lib/osd \
            -D WITH_OPENVDB=ON \
            -D WITH_OPENVDB_BLOSC=ON \
            -D OPENVDB_ROOT_DIR=/opt/lib/openvdb \
            -D BLOSC_ROOT_DIR=/opt/lib/blosc \
            -D WITH_ALEMBIC=ON \
            -D ALEMBIC_ROOT_DIR=/opt/lib/alembic \
            -D WITH_USD=ON \
            -D USD_ROOT_DIR=/opt/lib/usd \
            -D WITH_CODEC_FFMPEG=ON \
            -D FFMPEG_LIBRARIES='avformat;avcodec;avutil;avdevice;swscale;swresample;lzma;rt;theora;theoradec;theoraenc;vorbis;vorbisenc;vorbisfile;ogg;x264;openjp2' \
            -D WITH_XR_OPENXR=ON \
            -D XR_OPENXR_SDK_ROOT_DIR=/opt/lib/xr-openxr-sdk \
            -D WITH_PYTHON_INSTALL=0 \
            -D WITH_PYTHON_MODULE=1 \
            -D WITH_AUDASPACE=OFF \
            -D PYTHON_SITE_PACKAGES=/usr/lib/python3.7/site-packages \
            ../blender
RUN make -j `nproc`
RUN make install

FROM nvidia/cuda:10.0-cudnn7-devel as vibe

RUN DEBIAN_FRONTEND=noninteractive apt --assume-yes update
RUN DEBIAN_FRONTEND=noninteractive apt --assume-yes full-upgrade
RUN DEBIAN_FRONTEND=noninteractive apt --assume-yes install python3.7 python3.7-dev python3-pip git libsm6 \
libxrender1 libglfw3-dev libgles2-mesa-dev libosmesa6-dev freeglut3-dev ffmpeg libgflags2.2 libgoogle-glog0v5 \
libprotobuf10 libhdf5-100 libatlas3-base libgtk-3-0 unzip
RUN DEBIAN_FRONTEND=noninteractive apt --assume-yes --no-install-recommends install libboost-all-dev && apt clean
RUN python3.7 -m pip install -U setuptools pip

WORKDIR /vibe/vibe
COPY VIBE_fork .
COPY --from=openpose_builder /staf/ready /
COPY --from=openpose_builder /staf/ /staf
COPY --from=openpose_builder /staf/build /staf/STAF/build

RUN python3.7 -m pip install -r requirements.txt
COPY --from=opencv_builder /opencv/ready /
COPY --from=blender_builder /blender-git/ready /usr/local/lib/python3.7/dist-packages/
COPY SMPL_unity_v.1.0.0 /vibe/vibe/data/SMPL_unity_v.1.0.0
ENTRYPOINT /bin/bash
