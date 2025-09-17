<<<<<<< HEAD
# SimplerEnv: Simulated Manipulation Policy Evaluation Environments for Real Robot Setups

[![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/simpler-env/SimplerEnv/blob/main/example.ipynb)

![](./images/teaser.png)

Significant progress has been made in building generalist robot manipulation policies, yet their scalable and reproducible evaluation remains challenging, as real-world evaluation is operationally expensive and inefficient. We propose employing physical simulators as efficient, scalable, and informative complements to real-world evaluations. These simulation evaluations offer valuable quantitative metrics for checkpoint selection, insights into potential real-world policy behaviors or failure modes, and standardized setups to enhance reproducibility.

This repository's code is based in the [SAPIEN](https://sapien.ucsd.edu/) simulator and the CPU based [ManiSkill2](https://maniskill2.github.io/) benchmark. We have also integrated the Bridge dataset environments into ManiSkill3, which offers GPU parallelization and can run 10-15x faster than the ManiSkill2 version. For instructions on how to use the GPU parallelized environments and evaluate policies on them, see: https://github.com/simpler-env/SimplerEnv/tree/maniskill3

This repository encompasses 2 real-to-sim evaluation setups:
- `Visual Matching` evaluation: Matching real & sim visual appearances for policy evaluation by overlaying real-world images onto simulation backgrounds and adjusting foreground object and robot textures in simulation.
- `Variant Aggregation` evaluation: creating different sim environment variants (e.g., different backgrounds, lightings, distractors, table textures, etc) and averaging their results.

We hope that our work guides and inspires future real-to-sim evaluation efforts.

- [SimplerEnv: Simulated Manipulation Policy Evaluation Environments for Real Robot Setups](#simplerenv-simulated-manipulation-policy-evaluation-environments-for-real-robot-setups)
  - [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Examples](#examples)
  - [Current Environments](#current-environments)
  - [Compare Your Policy Evaluation Approach to SIMPLER](#compare-your-policy-evaluation-approach-to-simpler)
  - [Code Structure](#code-structure)
  - [Adding New Policies](#adding-new-policies)
  - [Adding New Real-to-Sim Evaluation Environments and Robots](#adding-new-real-to-sim-evaluation-environments-and-robots)
  - [Full Installation (RT-1 and Octo Inference, Env Building)](#full-installation-rt-1-and-octo-inference-env-building)
    - [RT-1 Inference Setup](#rt-1-inference-setup)
    - [Octo Inference Setup](#octo-inference-setup)
  - [Troubleshooting](#troubleshooting)
  - [Citation](#citation)


## Getting Started

Follow the [Installation](#installation) section to install the minimal requirements for our environments. Then you can run the following minimal inference script with interactive python. The scripts creates prepackaged environments for our `visual matching` evaluation setup.

```python
import simpler_env
from simpler_env.utils.env.observation_utils import get_image_from_maniskill2_obs_dict

env = simpler_env.make('google_robot_pick_coke_can')
obs, reset_info = env.reset()
instruction = env.get_language_instruction()
print("Reset info", reset_info)
print("Instruction", instruction)

done, truncated = False, False
while not (done or truncated):
   # action[:3]: delta xyz; action[3:6]: delta rotation in axis-angle representation;
   # action[6:7]: gripper (the meaning of open / close depends on robot URDF)
   image = get_image_from_maniskill2_obs_dict(env, obs)
   action = env.action_space.sample() # replace this with your policy inference
   obs, reward, done, truncated, info = env.step(action) # for long horizon tasks, you can call env.advance_to_next_subtask() to advance to the next subtask; the environment might also autoadvance if env._elapsed_steps is larger than a threshold
   new_instruction = env.get_language_instruction()
   if new_instruction != instruction:
      # for long horizon tasks, we get a new instruction when robot proceeds to the next subtask
      instruction = new_instruction
      print("New Instruction", instruction)

episode_stats = info.get('episode_stats', {})
print("Episode stats", episode_stats)
```

Additionally, you can play with our environments in an interactive manner through [`ManiSkill2_real2sim/mani_skill2_real2sim/examples/demo_manual_control_custom_envs.py`](https://github.com/simpler-env/ManiSkill2_real2sim/blob/main/mani_skill2_real2sim/examples/demo_manual_control_custom_envs.py). See the script for more details and commands.

=======
>>>>>>> 28a849ea285801567ef9133c05e414c37ca63e7d
## Installation

Prerequisites:
- CUDA version >=11.8 (this is required if you want to perform a full installation of this repo and perform RT-1 or Octo inference)
- An NVIDIA GPU (ideally RTX; for non-RTX GPUs, such as 1080Ti and A100, environments that involve ray tracing will be slow). Currently TPU is not supported as SAPIEN requires a GPU to run.

Create an anaconda environment:
```
<<<<<<< HEAD
conda create -n simpler_env python=3.10 (3.10 or 3.11)
conda activate simpler_env
=======
conda create -n eval python=3.10 (any version above 3.10 should be fine)
conda activate eval
>>>>>>> 28a849ea285801567ef9133c05e414c37ca63e7d
```

Clone this repo:
```
git clone https://github.com/FHLiang221/SimplerEnv-OpenVLA.git
```

Clone ManiSkill2:
```
cd SimplerEnv && git clone https://github.com/allenzren/ManiSkill2_real2sim.git
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

```