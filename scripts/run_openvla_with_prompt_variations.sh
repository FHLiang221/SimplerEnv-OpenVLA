#!/bin/bash
# Script to evaluate OpenVLA with different prompt variations
# This tests robustness to instruction phrasing

set -e  # Exit on error

# Check if required arguments are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <checkpoint_path> <prompt_yaml_path> [device_id]"
    echo "Example: $0 openvla/openvla-7b prompt_variations.yaml 0"
    exit 1
fi

CKPT_PATH=$1
PROMPT_YAML=$2
DEVICE_ID=${3:-0}  # Default to GPU 0
MODEL_NAME="openvla"
ACTION_ENSEMBLE_TEMP=-0.8

# Check if YAML file exists
if [ ! -f "$PROMPT_YAML" ]; then
    echo "Error: Prompt YAML file '$PROMPT_YAML' not found!"
    exit 1
fi

# Define tasks that match those in run_openvla.sh
tasks=(
  google_robot_pick_coke_can_multi_object
  google_robot_pick_apple_multi_object
  google_robot_pick_sponge_multi_object
  google_robot_open_top_drawer_multi_object
  google_robot_close_bottom_drawer_multi_object
)

# Base logging directory
BASE_LOGGING_DIR="results_prompt_variations/$(basename $CKPT_PATH)${ACTION_ENSEMBLE_TEMP}"
mkdir -p "$BASE_LOGGING_DIR"

echo "=================================================="
echo "🚀 Running OpenVLA with Prompt Variations"
echo "=================================================="
echo "Checkpoint: $CKPT_PATH"
echo "Prompt YAML: $PROMPT_YAML"
echo "Device: $DEVICE_ID"
echo "Logging to: $BASE_LOGGING_DIR"
echo "=================================================="

# Python script to parse YAML and run evaluations
python3 << EOF
import yaml
import os
import subprocess
import sys

# Load prompt variations from YAML
with open('$PROMPT_YAML', 'r') as f:
    prompt_variations = yaml.safe_load(f)

tasks = [
    'google_robot_pick_coke_can_multi_object',
    'google_robot_pick_apple_multi_object',
    'google_robot_pick_sponge_multi_object',
    'google_robot_open_top_drawer_multi_object',
    'google_robot_close_bottom_drawer_multi_object'
]

for task_name in tasks:
    print(f"\n{'='*60}")
    print(f"📋 Task: {task_name}")
    print(f"{'='*60}")

    if task_name not in prompt_variations or not prompt_variations[task_name]:
        print(f"⚠️  No prompt variations found for {task_name}, skipping...")
        continue

    prompts = prompt_variations[task_name]
    print(f"Testing {len(prompts)} prompt variations")

    for prompt_idx, prompt in enumerate(prompts):
        print(f"\n🔹 Prompt {prompt_idx + 1}/{len(prompts)}: '{prompt}'")

        # Create logging directory for this prompt variation
        prompt_logging_dir = f"$BASE_LOGGING_DIR/{task_name}/prompt_{prompt_idx}"
        os.makedirs(prompt_logging_dir, exist_ok=True)

        # Save the prompt to a file for reference
        with open(f"{prompt_logging_dir}/prompt.txt", 'w') as f:
            f.write(prompt)

        # Build the command to run the evaluation
        cmd = [
            'python', 'simpler_env/main_inference.py',
            '--policy-model', '$MODEL_NAME',
            '--ckpt-path', '$CKPT_PATH',
            '--action-ensemble-temp', str($ACTION_ENSEMBLE_TEMP),
            '--logging-dir', prompt_logging_dir,
            '--use-proprio',
            '--robot', 'google_robot_static',
            '--control-freq', '3',
            '--sim-freq', '513',
            '--obj-variation-mode', 'episode',
            '--obj-episode-range', '0', '10',
            '--randomize-robot-pos',
            '--env-name', task_name,
            '--instruction', prompt
        ]

        # Set max-episode-steps based on task
        if 'drawer' in task_name:
            cmd.extend(['--max-episode-steps', '150'])
        else:
            cmd.extend(['--max-episode-steps', '120'])

        # Set CUDA device
        env = os.environ.copy()
        env['CUDA_VISIBLE_DEVICES'] = '$DEVICE_ID'

        print(f"Running command: {' '.join(cmd)}")

        # Run the evaluation
        try:
            result = subprocess.run(cmd, env=env, check=True, capture_output=False)
            print(f"✅ Completed prompt variation {prompt_idx + 1}")
        except subprocess.CalledProcessError as e:
            print(f"❌ Error running prompt variation {prompt_idx + 1}: {e}")
            sys.exit(1)

print(f"\n{'='*60}")
print("🎉 All evaluations completed!")
print(f"Results saved to: $BASE_LOGGING_DIR")
print(f"{'='*60}")
EOF

# Calculate aggregated metrics for each task
echo ""
echo "=================================================="
echo "📊 Calculating metrics for each task..."
echo "=================================================="

for task_name in "${tasks[@]}"; do
    task_dir="$BASE_LOGGING_DIR/$task_name"
    if [ -d "$task_dir" ]; then
        echo ""
        echo "Task: $task_name"
        python tools/calc_metrics_evaluation_videos.py \
            --log-dir-root "$task_dir" \
            > "$task_dir/aggregated_metrics.txt"
        echo "Metrics saved to: $task_dir/aggregated_metrics.txt"
    fi
done

echo ""
echo "=================================================="
echo "✅ All done! Check results in: $BASE_LOGGING_DIR"
echo "=================================================="
