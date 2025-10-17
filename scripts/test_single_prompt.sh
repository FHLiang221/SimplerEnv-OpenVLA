#!/bin/bash
# Quick test script for testing a single task with a custom prompt
# Useful for debugging and quick validation

set -e

# Check arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <checkpoint_path> <task_name> <custom_prompt> [device_id] [n_episodes]"
    echo ""
    echo "Example:"
    echo "  $0 openvla/openvla-7b google_robot_pick_coke_can_multi_object \"grab the red soda can\" 0 5"
    echo ""
    echo "Available tasks:"
    echo "  - google_robot_pick_coke_can_multi_object"
    echo "  - google_robot_pick_apple_multi_object"
    echo "  - google_robot_pick_sponge_multi_object"
    echo "  - google_robot_open_top_drawer_multi_object"
    echo "  - google_robot_close_bottom_drawer_multi_object"
    exit 1
fi

CKPT_PATH=$1
TASK_NAME=$2
CUSTOM_PROMPT=$3
DEVICE_ID=${4:-0}
N_EPISODES=${5:-5}

MODEL_NAME="openvla"
ACTION_ENSEMBLE_TEMP=-0.8
LOGGING_DIR="./test_prompt_results/${TASK_NAME}_$(date +%Y%m%d_%H%M%S)"

# Determine max episode steps based on task
if [[ "$TASK_NAME" == *"drawer"* ]]; then
    MAX_STEPS=150
else
    MAX_STEPS=120
fi

echo "=================================================="
echo "🧪 Testing Single Prompt"
echo "=================================================="
echo "Checkpoint:    $CKPT_PATH"
echo "Task:          $TASK_NAME"
echo "Custom Prompt: \"$CUSTOM_PROMPT\""
echo "Device:        $DEVICE_ID"
echo "Episodes:      $N_EPISODES"
echo "Max Steps:     $MAX_STEPS"
echo "Logging to:    $LOGGING_DIR"
echo "=================================================="
echo ""

# Save prompt for reference
mkdir -p "$LOGGING_DIR"
echo "$CUSTOM_PROMPT" > "$LOGGING_DIR/prompt.txt"

# Run evaluation
CUDA_VISIBLE_DEVICES=$DEVICE_ID python simpler_env/main_inference.py \
    --policy-model $MODEL_NAME \
    --ckpt-path "$CKPT_PATH" \
    --action-ensemble-temp $ACTION_ENSEMBLE_TEMP \
    --logging-dir "$LOGGING_DIR" \
    --use-proprio \
    --robot google_robot_static \
    --control-freq 3 \
    --sim-freq 513 \
    --max-episode-steps $MAX_STEPS \
    --obj-variation-mode episode \
    --obj-episode-range 0 $N_EPISODES \
    --randomize-robot-pos \
    --env-name "$TASK_NAME" \
    --instruction "$CUSTOM_PROMPT"

echo ""
echo "=================================================="
echo "✅ Test completed!"
echo "=================================================="
echo "Results saved to: $LOGGING_DIR"
echo ""
echo "To calculate metrics, run:"
echo "  python tools/calc_metrics_evaluation_videos.py --log-dir-root $LOGGING_DIR"
echo "=================================================="
