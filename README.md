# Description
GPU-ready VIBE

## Versions
* UBUNTU 18.04
* Cuda 10.0
* CuDNN 7.6.5
* Opencv 3.4.13
* OpenPose 1.5.0 (STAF)
* Blender 2.83

# Build
1. Go to [SMPL website](https://smpl.is.tue.mpg.de/) and create an account.
1. Download the Unity-compatible FBX file through the [link](https://psfiles.is.tuebingen.mpg.de/downloads/smpl/SMPL_unity_v-1-0-0-zip)
1. Unzip the contents and locate them `./SMPL_unity_v.1.0.0`.
1. ```git submodule update --init --recursive```
1. ```docker build .```

# Usage
1. Install [Nvidia Docker](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker)
1. ```nvidia-docker run -it inokenty/vibe```
1. Use ```python3.7```
