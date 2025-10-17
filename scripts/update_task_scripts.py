#!/usr/bin/env python3
"""
Helper script to update all multi-object task scripts to support prompt variations.
This generates the updated script content for each task.
"""

TASK_CONFIGS = [
    {
        'script': 'multi_object_pick_apple.sh',
        'task_name': 'google_robot_pick_apple_multi_object',
        'display_name': 'Multi-Object Pick Apple Task',
        'note': 'Object positions are hardcoded in the environment',
        'max_steps': 120,
    },
    {
        'script': 'multi_object_pick_sponge.sh',
        'task_name': 'google_robot_pick_sponge_multi_object',
        'display_name': 'Multi-Object Pick Sponge Task',
        'note': 'Object positions are hardcoded in the environment',
        'max_steps': 120,
    },
    {
        'script': 'multi_object_open_top_drawer.sh',
        'task_name': 'google_robot_open_top_drawer_multi_object',
        'display_name': 'Multi-Object Open Top Drawer Task',
        'note': '3 objects on table, bottom drawer pre-opened',
        'max_steps': 150,
    },
    {
        'script': 'multi_object_close_bottom_drawer.sh',
        'task_name': 'google_robot_close_bottom_drawer_multi_object',
        'display_name': 'Multi-Object Close Bottom Drawer Task',
        'note': '3 objects on table, bottom drawer starts open',
        'max_steps': 150,
    },
]

TEMPLATE = '''#!/bin/bash

ckpt_path=$1
policy_model=$2
action_ensemble_temp=$3
logging_dir=$4
gpu_id=$5
prompt_yaml=$6  # Optional: YAML file with prompt variations

declare -a arr=($ckpt_path)

# Use the proper task name that goes through simpler_env.make()
# This ensures prepackaged_config=True and correct scene setup
task_name={task_name}

echo "🎯 Running {display_name}"
echo "   Task: ${{task_name}}"
echo "   Note: {note}"

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
    print(f"⚠️  No prompts found for {{task_name}} in YAML, using default")
    prompts = [None]  # Will use default prompt

for prompt_idx, prompt in enumerate(prompts):
    # Create a safe directory name from the prompt
    if prompt:
        # Shorten and sanitize the prompt for directory name
        safe_prompt = re.sub(r'[^\\w\\s-]', '', prompt).strip()
        safe_prompt = re.sub(r'[-\\s]+', '_', safe_prompt)[:50]  # Max 50 chars
        prompt_suffix = f"prompt_{{prompt_idx}}_{{safe_prompt}}"
        print(f"\\n{{'='*60}}")
        print(f"🔹 Prompt {{prompt_idx + 1}}/{{len(prompts)}}: '{{prompt}}'")
        print(f"{{'='*60}}")
    else:
        prompt_suffix = "default_prompt"
        print(f"\\n{{'='*60}}")
        print(f"📋 Using default prompt")
        print(f"{{'='*60}}")

    # Create logging directory for this prompt
    prompt_logging_dir = f"$logging_dir/{{task_name}}/{{prompt_suffix}}"
    os.makedirs(prompt_logging_dir, exist_ok=True)

    # Save the prompt to a file
    if prompt:
        with open(f"{{prompt_logging_dir}}/prompt.txt", 'w') as f:
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
        '--max-episode-steps', '{max_steps}',
        '--obj-variation-mode', 'episode',
        '--obj-episode-range', '0', '10',
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
        print(f"✅ Completed prompt variation {{prompt_idx + 1}}")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error: {{e}}")
        sys.exit(1)
EOF

else
  echo "   Mode: Default prompt"
  echo ""

  # Original behavior - single run with default prompt
  for ckpt_path in "${{arr[@]}}";
  do CUDA_VISIBLE_DEVICES=${{gpu_id}} python simpler_env/main_inference.py \\
    --policy-model ${{policy_model}} \\
    --ckpt-path ${{ckpt_path}} \\
    --action-ensemble-temp ${{action_ensemble_temp}} \\
    --logging-dir ${{logging_dir}} \\
    --use-proprio \\
    --robot google_robot_static \\
    --control-freq 3 --sim-freq 513 --max-episode-steps {max_steps} \\
    --obj-variation-mode episode \\
    --obj-episode-range 0 10 \\
    --randomize-robot-pos \\
    --env-name ${{task_name}};
  done
fi
'''

def main():
    import os
    script_dir = os.path.dirname(os.path.abspath(__file__))

    for config in TASK_CONFIGS:
        content = TEMPLATE.format(**config)
        script_path = os.path.join(script_dir, config['script'])

        with open(script_path, 'w') as f:
            f.write(content)

        # Make executable
        os.chmod(script_path, 0o755)

        print(f"✅ Updated {config['script']}")

    print("\n🎉 All task scripts updated successfully!")

if __name__ == '__main__':
    main()
