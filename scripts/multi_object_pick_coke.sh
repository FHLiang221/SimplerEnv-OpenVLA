#!/bin/bash

ckpt_path=$1
policy_model=$2
action_ensemble_temp=$3
logging_dir=$4
gpu_id=$5
prompt_yaml=$6  # Optional: YAML file with prompt variations

declare -a arr=($ckpt_path)

# Use the proper task name that goes through simpler_env.make()
# This ensures prepackaged_config=True and correct scene setup
task_name=google_robot_pick_coke_can_multi_object

echo "🎯 Running Multi-Object Pick Coke Can Task"
echo "   Task: ${task_name}"
echo "   Note: Object positions are hardcoded in the environment"

# Check if prompt variations should be used
if [ -n "$prompt_yaml" ] && [ -f "$prompt_yaml" ]; then
  echo "   Mode: Prompt Variations from $prompt_yaml"
  echo ""

  # Parse YAML and run for each prompt variation
  python3 << EOF
import yaml
import os
import subprocess
import sys
import re

# Load prompt variations
with open('$prompt_yaml', 'r') as f:
    prompt_variations = yaml.safe_load(f)

task_name = '$task_name'
prompts = prompt_variations.get(task_name, [])

if not prompts:
    print(f"⚠️  No prompts found for {task_name} in YAML, using default")
    prompts = [None]  # Will use default prompt

for prompt_idx, prompt in enumerate(prompts):
    # Create a safe directory name from the prompt
    if prompt:
        # Shorten and sanitize the prompt for directory name
        safe_prompt = re.sub(r'[^\w\s-]', '', prompt).strip()
        safe_prompt = re.sub(r'[-\s]+', '_', safe_prompt)[:50]  # Max 50 chars
        prompt_suffix = f"prompt_{prompt_idx}_{safe_prompt}"
        print(f"\n{'='*60}")
        print(f"🔹 Prompt {prompt_idx + 1}/{len(prompts)}: '{prompt}'")
        print(f"{'='*60}")
    else:
        prompt_suffix = "default_prompt"
        print(f"\n{'='*60}")
        print(f"📋 Using default prompt")
        print(f"{'='*60}")

    # Create logging directory for this prompt
    prompt_logging_dir = f"$logging_dir/{task_name}/{prompt_suffix}"
    os.makedirs(prompt_logging_dir, exist_ok=True)

    # Save the prompt to a file
    if prompt:
        with open(f"{prompt_logging_dir}/prompt.txt", 'w') as f:
            f.write(prompt)

    # Build command
    cmd = [
        'python', 'simpler_env/main_inference.py',
        '--policy-model', '$policy_model',
        '--ckpt-path', '$ckpt_path',
        '--action-ensemble-temp', '$action_ensemble_temp',
        '--logging-dir', prompt_logging_dir,
        '--use-proprio',
        '--robot', 'google_robot_static',
        '--control-freq', '3',
        '--sim-freq', '513',
        '--max-episode-steps', '120',
        '--obj-variation-mode', 'episode',
        '--obj-episode-range', '0', '50',
        '--randomize-robot-pos',
        '--env-name', task_name,
    ]

    # Add instruction if custom prompt provided
    if prompt:
        cmd.extend(['--instruction', prompt])

    # Set environment
    env = os.environ.copy()
    env['CUDA_VISIBLE_DEVICES'] = '$gpu_id'

    # Run
    try:
        subprocess.run(cmd, env=env, check=True)
        print(f"✅ Completed prompt variation {prompt_idx + 1}")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
EOF

else
  echo "   Mode: Default prompt"
  echo ""

  # Original behavior - single run with default prompt
  for ckpt_path in "${arr[@]}";
  do CUDA_VISIBLE_DEVICES=${gpu_id} python simpler_env/main_inference.py \
    --policy-model ${policy_model} \
    --ckpt-path ${ckpt_path} \
    --action-ensemble-temp ${action_ensemble_temp} \
    --logging-dir ${logging_dir} \
    --use-proprio \
    --robot google_robot_static \
    --control-freq 3 --sim-freq 513 --max-episode-steps 120 \
    --obj-variation-mode episode \
    --obj-episode-range 0 50 \
    --randomize-robot-pos \
    --env-name ${task_name};
  done
fi
