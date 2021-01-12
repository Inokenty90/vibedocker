# Build

1. Go to [SMPL website](https://smpl.is.tue.mpg.de/) and create an account.
1. Download the Unity-compatible FBX file through the [link](https://psfiles.is.tuebingen.mpg.de/downloads/smpl/SMPL_unity_v-1-0-0-zip)
1. Unzip the contents and locate them `./SMPL_unity_v.1.0.0`.
1. ```git submodule update --init --recursive```
1. ```cd STAF```
1. ```git submodule update --init --recursive```
1. ```docker build .```

