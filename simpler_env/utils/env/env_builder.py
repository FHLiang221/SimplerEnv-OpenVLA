import gymnasium as gym
import mani_skill2_real2sim.envs
from simpler_env import ENVIRONMENT_MAP


def build_maniskill2_env(env_name, **kwargs):
    # Check if env_name is a task name that needs to be mapped to a ManiSkill2 env
    if env_name in ENVIRONMENT_MAP:
        # It's a task name - convert to ManiSkill2 env name and merge kwargs
        maniskill_env_name, default_kwargs = ENVIRONMENT_MAP[env_name]
        
        # Set prepackaged_config for consistency
        if "prepackaged_config" not in kwargs:
            kwargs["prepackaged_config"] = True
        
        # Merge default kwargs (but let passed kwargs override)
        for key, value in default_kwargs.items():
            if key not in kwargs:
                kwargs[key] = value
        
        env_name = maniskill_env_name
        print(f"Task name mapped to ManiSkill2 env: {env_name} with prepackaged_config={kwargs.get('prepackaged_config')}")
    
    # Create environment
    if kwargs.get("rgb_overlay_path", None) is not None:
        if kwargs.get("rgb_overlay_cameras", None) is None:
            # Set the default camera to overlay real images for the visual-matching evaluation setting
            if "google_robot_static" in kwargs.get("robot", ""):
                kwargs["rgb_overlay_cameras"] = ["overhead_camera"]
            elif "widowx" in kwargs.get("robot", ""):
                kwargs["rgb_overlay_cameras"] = ["3rd_view_camera"]
            else:
                raise NotImplementedError()
    env = gym.make(env_name, **kwargs)

    return env

def get_robot_control_mode(robot_name, policy_name):
    if "google_robot_static" in robot_name:
        control_mode = (
            "arm_pd_ee_delta_pose_align_interpolate_by_planner_gripper_pd_joint_target_delta_pos_interpolate_by_planner"
        )
    elif "widowx" in robot_name:
        control_mode = "arm_pd_ee_target_delta_pose_align2_gripper_pd_joint_pos"
        # control_mode = 'arm_pd_ee_delta_pose_align2_gripper_pd_joint_pos'
    else:
        raise NotImplementedError()
    print("Control mode: ", control_mode)
    return control_mode
