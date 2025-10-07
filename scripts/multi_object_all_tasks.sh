#!/bin/bash

ckpt_path=$1
policy_model=$2
action_ensemble_temp=$3
logging_dir=$4
gpu_id=$5

# Multi-object tasks with distractors
declare -a tasks=(
  "MultiObjectGraspSingleOpenedCokeCanInScene-v0"
  "MultiObjectGraspSingleAppleInScene-v0"
  "MultiObjectGraspSingleSpongeInScene-v0"
  "MultiObjectOpenTopDrawerCustomInScene-v0"
  "MultiObjectCloseBottomDrawerCustomInScene-v0"
)

# Scene name - adjust if needed based on your setup
scene_name=google_pick_coke_can_1_v4

echo "============================================"
echo "Running Multi-Object Tasks with Distractors"
echo "============================================"

for env_name in "${tasks[@]}"; do
  echo ""
  echo "🚀 Running task: ${env_name}"
  echo "--------------------------------------------"
  
  CUDA_VISIBLE_DEVICES=${gpu_id} python simpler_env/main_inference.py \
    --policy-model ${policy_model} \
    --ckpt-path ${ckpt_path} \
    --action-ensemble-temp ${action_ensemble_temp} \
    --logging-dir ${logging_dir} \
    --use-proprio \
    --robot google_robot_static \
    --control-freq 3 --sim-freq 513 --max-episode-steps 80 \
    --env-name ${env_name} \
    --scene-name ${scene_name} \
    --robot-init-x 0.35 0.35 1 \
    --robot-init-y 0.20 0.20 1 \
    --robot-init-rot-quat-center 0 0 0 1 \
    --robot-init-rot-rpy-range 0 0 1 0 0 1 0 0 1
  
  echo "✅ Completed: ${env_name}"
done

echo ""
echo "============================================"
echo "All Multi-Object Tasks Completed!"
echo "============================================"
