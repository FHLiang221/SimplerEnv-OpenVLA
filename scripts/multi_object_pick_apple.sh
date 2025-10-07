#!/bin/bash

ckpt_path=$1
policy_model=$2
action_ensemble_temp=$3
logging_dir=$4
gpu_id=$5

declare -a arr=($ckpt_path)

# Use the proper task name that goes through simpler_env.make()
# This ensures prepackaged_config=True and correct scene setup
task_name=google_robot_pick_apple_multi_object

echo "🎯 Running Multi-Object Pick Apple Task"
echo "   Task: ${task_name}"
echo "   Note: Object positions are hardcoded in the environment"
echo ""

for ckpt_path in "${arr[@]}";

do CUDA_VISIBLE_DEVICES=${gpu_id} python simpler_env/main_inference.py \
  --policy-model ${policy_model} \
  --ckpt-path ${ckpt_path} \
  --action-ensemble-temp ${action_ensemble_temp} \
  --logging-dir ${logging_dir} \
  --use-proprio \
  --robot google_robot_static \
  --control-freq 3 --sim-freq 513 --max-episode-steps 120 \
  --obj-episode-range 0 50 \
  --env-name ${task_name};

done
