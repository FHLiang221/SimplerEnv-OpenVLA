## Installation

Prerequisites:
- CUDA version >=11.8 (this is required if you want to perform a full installation of this repo and perform RT-1 or Octo inference)
- An NVIDIA GPU (ideally RTX; for non-RTX GPUs, such as 1080Ti and A100, environments that involve ray tracing will be slow). Currently TPU is not supported as SAPIEN requires a GPU to run.

Create an anaconda environment:
```
conda create -n eval python=3.10 (any version above 3.10 should be fine)
conda activate eval
```

Clone this repo:
```
git clone https://github.com/FHLiang221/SimplerEnv-OpenVLA.git
```

Clone ManiSkill2:
```
cd SimplerEnv && git clone https://github.com/FHLiang221/ManiSkill2_real2sim.git
cd ManiSkill2_real2sim
git checkout git checkout SimplerEnv-OpenVLA
```

Install numpy<2.0 (otherwise errors in IK might occur in pinocchio):
```
pip install numpy==1.24.4
```

Install ManiSkill2 real-to-sim environments and their dependencies:
```
cd {this_repo}/ManiSkill2_real2sim
pip install -e .
```

Install this package:
```
cd {this_repo}
pip install -e .
```

**If you'd like to perform evaluations on our provided agents (e.g., RT-1, Octo, OpenVLA), or add new robots and environments, please additionally follow the full installation instructions [here](#full-installation-rt-1-octo-openvla-inference-env-building).**


## Full Installation (RT-1, Octo, OpenVLA Inference, Env Building)

If you'd like to perform evaluations on our provided agents (e.g., RT-1, Octo), or add new robots and environments, please follow the full installation instructions below.

```
sudo apt install ffmpeg
```

```
pip install tensorflow==2.15.0
pip install -r requirements_full_install.txt
pip install tensorflow[and-cuda]==2.15.1 # tensorflow gpu support
```

Install simulated annealing utils for system identification:
```
pip install git+https://github.com/nathanrooy/simulated-annealing
```

### OpenVLA Inference Setup

```
pip install torch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0
pip install transformers==4.40.1 tokenizers==0.19.1 accelerate==0.32.1
pip install flash-attn==2.6.1 --no-build-isolation
pip install "timm>=0.9.10,<1.0.0"
pip install json_numpy
pip install draccus
pip install tensorflow_graphics
pip install jsonlines
pip install diffusers

# install what pip wants/needs
```

### OpenVLA Inference Running

```
bash scripts/run_openvla.sh #to change prompts and number of runs edit run_openvla_jaco.sh
```