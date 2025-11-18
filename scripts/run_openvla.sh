#!/bin/bash
# Enhanced run_openvla.sh with optional prompt variation support
#
# Usage:
#   bash scripts/run_openvla.sh                              # Use default prompts, GPU 0
#   bash scripts/run_openvla.sh prompt_variations.yaml       # Use prompt variations, GPU 0
#   bash scripts/run_openvla.sh prompt_variations.yaml 1     # Use prompt variations, GPU 1
#   bash scripts/run_openvla.sh "" 1                         # Use default prompts, GPU 1

set -e

# Parse arguments
PROMPT_YAML=${1:-""}  # Optional YAML file for prompt variations
GPU_ID=${2:-0}        # GPU device ID (default: 0)

model_name=openvla
tasks=(
  # bridge.sh  # WidowX robot task - skip for Google robot checkpoint
  # drawer_variant_agg.sh
  # drawer_visual_matching.sh
  # move_near_variant_agg.sh
  # move_near_visual_matching.sh
  # pick_coke_can_variant_agg.sh
  # pick_coke_can_visual_matching.sh
  # put_in_drawer_variant_agg.sh
  # put_in_drawer_visual_matching.sh
  # Multi-object tasks with distractors (individual scripts for proper metrics)
  multi_object_pick_coke.sh
  multi_object_pick_apple.sh
  multi_object_pick_sponge.sh
  multi_object_open_top_drawer.sh
  multi_object_close_bottom_drawer.sh
)

ckpts=(
  fhliang/google_robot_ERT_20k
  #fhliang/google_robot_base_20k
  #fhliang/google_robot_Qdig_20k
  
  # Notes on custom prompts (for reference):
  # qd_coke_can: "approach the coke can, adjust your grip, gently grasp it, and then lift it carefully"
  # qd_top_drawer: "could you open the top drawer, please?"
  # qd_bottom_drawer: "close the drawer at the bottom, listening for the sound of it clicking shut"
  # human_coke_can: "pick up the soda can"
  # human_sponge: "could you grab that sponge off the table"
)

action_ensemble_temp=-0.8

# Check if prompt YAML is provided and valid
if [ -n "$PROMPT_YAML" ] && [ -f "$PROMPT_YAML" ]; then
  echo "============================================================"
  echo "🎯 PROMPT VARIATION MODE ENABLED"
  echo "   Using prompts from: $PROMPT_YAML"
  echo "   GPU Device: $GPU_ID"
  echo "============================================================"
  USE_PROMPT_VARIATIONS=true
else
  if [ -n "$PROMPT_YAML" ] && [ ! -f "$PROMPT_YAML" ]; then
    echo "⚠️  Warning: YAML file '$PROMPT_YAML' not found. Using default prompts."
  fi
  echo "============================================================"
  echo "🚀 Running with default prompts"
  echo "   GPU Device: $GPU_ID"
  echo "============================================================"
  USE_PROMPT_VARIATIONS=false
fi

for ckpt_path in ${ckpts[@]}; do
  base_dir=$(dirname $ckpt_path)

  # evaluation in simulator
  # logging_dir=$base_dir/simpler_env/$(basename $ckpt_path)${action_ensemble_temp}
  logging_dir=results/$(basename $ckpt_path)${action_ensemble_temp}
  mkdir -p $logging_dir

  for i in ${!tasks[@]}; do
    task=${tasks[$i]}
    echo "🚀 running $task ..."
    device=$GPU_ID
    session_name=CUDA${device}-$(basename $logging_dir)-${task}

    # Pass prompt YAML to task script if using variations
    if [ "$USE_PROMPT_VARIATIONS" = true ]; then
      bash scripts/$task $ckpt_path $model_name $action_ensemble_temp $logging_dir $device "$PROMPT_YAML"
    else
      bash scripts/$task $ckpt_path $model_name $action_ensemble_temp $logging_dir $device
    fi
  done

  # statistics evalution results
  echo "🚀 all tasks DONE! Calculating metrics..."
  python tools/calc_metrics_evaluation_videos.py \
    --log-dir-root $logging_dir \
    >>$logging_dir/total.metrics
done

if [ "$USE_PROMPT_VARIATIONS" = true ]; then
  echo ""
  echo "============================================================"
  echo "📊 Generating prompt summaries..."
  echo "============================================================"
  python tools/generate_prompt_summaries.py \
    --results-dir $logging_dir

  echo ""
  echo "============================================================"
  echo "📊 Analyzing prompt robustness..."
  echo "============================================================"
  python tools/analyze_prompt_robustness.py \
    --results-dir $logging_dir \
    --prompt-yaml "$PROMPT_YAML" \
    --output-json $logging_dir/prompt_robustness_report.json
fi
