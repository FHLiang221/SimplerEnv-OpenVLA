# Proprioception Integration for SimplerEnv-OpenVLA

This document describes the proprioception support that has been integrated into SimplerEnv-OpenVLA, ported from the Proprio_SimplerEnv_OpenVLA repository.

## Overview

Proprioception (robot state information) support has been added to SimplerEnv-OpenVLA to enable the use of models that were trained with proprioceptive inputs. This allows the policy to condition on the robot's current state (joint positions, end-effector pose, gripper state) in addition to visual observations.

## What Was Added

### 1. New Files

- **`simpler_env/policies/openvla/prismatic/`** - Complete prismatic VLA framework directory
  - Contains custom VLA model implementations with proprioception support
  - Includes action heads, projectors, and model configurations
  - Key files:
    - `prismatic/extern/hf/modeling_prismatic.py` - Custom OpenVLA model with proprio support
    - `prismatic/extern/hf/configuration_prismatic.py` - Model configuration
    - `prismatic/models/action_heads.py` - L1 regression and diffusion action heads
    - `prismatic/models/projectors.py` - Proprioception projector module

- **`simpler_env/policies/openvla/openvla_utils.py`** - Utility functions for VLA loading
  - `get_vla()` - Load VLA model with proprioception support
  - `get_proprio_projector()` - Initialize proprioception projector
  - `get_action_head()` - Initialize action head (L1 regression or diffusion)
  - Helper functions for checkpoint loading and normalization

### 2. Modified Files

- **`simpler_env/policies/openvla/openvla_model.py`** - Updated OpenVLA inference class
  - Added proprioception support via `use_proprio` parameter
  - Maintains backward compatibility with non-proprio models
  - Supports action chunking for proprio-enabled models

### 3. New Components in `openvla_model.py`

#### Constants
```python
ACTION_DIM = 7              # 7-DOF action space (3 pos + 3 rot + 1 gripper)
PROPRIO_DIM = 8             # 8-dimensional proprioception (7D eef_pos + 1D gripper)
NUM_ACTIONS_CHUNK = 8       # Number of actions in action chunking
```

#### New Classes
- **`GenerateConfig`** - Dataclass for VLA configuration
- **`ProprioProjector`** - Projects proprioception into LLM embedding space
- **`MLPResNetBlock`** - ResNet block for action head
- **`MLPResNet`** - MLP with residual connections
- **`L1RegressionActionHead`** - Continuous action prediction via L1 regression

#### Helper Functions
- **`find_checkpoint_file()`** - Find specific checkpoint files
- **`load_component_state_dict()`** - Load checkpoint with DDP handling

## Usage

### Standard Mode (No Proprioception)

```python
from simpler_env.policies.openvla.openvla_model import OpenVLAInference

# Initialize standard model (backward compatible)
model = OpenVLAInference(
    saved_model_path="openvla/openvla-7b",
    policy_setup="google_robot",
    use_proprio=False  # Default is False
)

# Use without observation dict
image = env.get_observation()  # shape: (H, W, 3), dtype: uint8
raw_action, action = model.step(
    image=image,
    task_description="pick up the coke can"
)
```

### Proprioception Mode

```python
from simpler_env.policies.openvla.openvla_model import OpenVLAInference

# Initialize proprioception-enabled model
model = OpenVLAInference(
    saved_model_path="fhliang/jaco_adv_500",  # Checkpoint with proprio components
    policy_setup="jaco",
    use_proprio=True  # Enable proprioception
)

# Use with observation dict containing robot state
obs = env.get_observation()
# obs structure:
# {
#     'image': {...},
#     'agent': {
#         'eef_pos': np.ndarray,  # shape: (8,) - 7D pose + gripper width
#         'qpos': np.ndarray,     # shape: (N,) - joint positions
#         'qvel': np.ndarray,     # shape: (N,) - joint velocities
#     }
# }

raw_action, action = model.step(
    image=obs['image']['overhead_camera']['rgb'],
    task_description="pick up the object",
    obs=obs  # Pass full observation dict
)
```

### Key Differences

| Feature | Standard Mode | Proprioception Mode |
|---------|--------------|---------------------|
| Model Loading | HuggingFace AutoModel | Custom VLA loader |
| Input | Image + Task | Image + Task + Robot State |
| Action Output | Single action | Action chunk (8 actions) |
| Components | VLA only | VLA + Proprio Projector + Action Head |
| Normalization | Built-in | Custom dataset statistics |

## Proprioception Data Format

The proprioception input is an 8-dimensional vector extracted from the observation:
```python
proprio = np.concatenate([
    obs['agent']['eef_pos'][:-1],  # First 7 elements: end-effector pose (pos + quat)
    [obs['agent']['qpos'][-1]]     # Last element: gripper joint position
])
```

This is then normalized using dataset statistics before being projected into the LLM's embedding space.

## Action Chunking

When `use_proprio=True`, the model predicts 8 actions at once (action chunking) and executes them sequentially. This improves policy smoothness and reduces re-planning overhead.

```python
# First call: predicts 8 actions and queues them
raw_action1, action1 = model.step(image, task, obs)  # Uses action 1/8

# Next 7 calls: use queued actions
raw_action2, action2 = model.step(image, task, obs)  # Uses action 2/8
raw_action3, action3 = model.step(image, task, obs)  # Uses action 3/8
# ... and so on

# 9th call: predicts new 8 actions
raw_action9, action9 = model.step(image, task, obs)  # Predicts new chunk, uses 1/8
```

## Robot Support

The integration adds support for the "jaco" robot setup:
```python
policy_setup="jaco"  # Uses jaco_dataset normalization
```

Existing setups remain unchanged:
- `"google_robot"` - Google robot with sticky gripper
- `"widowx_bridge"` - WidowX robot from Bridge dataset

## Model Requirements

To use proprioception mode, your checkpoint must contain:
1. **VLA model** - Base vision-language-action model
2. **Proprioception projector** - File: `proprio_projector--*_checkpoint.pt`
3. **Action head** - File: `action_head--*_checkpoint.pt`
4. **Dataset statistics** - File: `dataset_statistics.json`

## Testing

A test script is provided to verify the integration:
```bash
python test_proprio_integration.py
```

This tests:
- Import verification (all modules load correctly)
- Standard mode compatibility
- Proprioception mode functionality

## Implementation Details

### Backward Compatibility

The implementation maintains full backward compatibility:
- Default `use_proprio=False` uses original behavior
- Standard mode doesn't load any proprioception components
- Existing code continues to work without modifications

### Normalization

Proprioception is normalized to [-1, 1] using dataset-specific statistics:
```python
normalized_proprio = np.clip(
    2 * (proprio - proprio_low) / (proprio_high - proprio_low + 1e-8) - 1,
    a_min=-1.0,
    a_max=1.0,
)
```

### Architecture

```
Image → Vision Encoder ─┐
                        ├→ LLM → Action Head → Actions (8-chunk)
Proprio → Projector ───┘
```

## Troubleshooting

### "No module named 'gymnasium'"
This is expected when testing imports at the package level. The integration itself is correct.

### "checkpoint not found"
Proprioception mode requires a specially trained checkpoint with proprio components. Standard OpenVLA checkpoints won't work.

### "obs parameter required"
When `use_proprio=True`, you must pass the `obs` parameter to `step()`.

## Credits

This implementation is ported from the Proprio_SimplerEnv_OpenVLA repository, which provides proprioception support for JACO robot evaluation.

## Future Work

- Support for different proprioception dimensions (currently fixed at 8D)
- Configurable action chunk sizes (currently fixed at 8)
- More robot-specific proprio extraction methods
- Integration with SimEval workflow scripts
