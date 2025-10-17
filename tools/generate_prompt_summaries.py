#!/usr/bin/env python3
"""
Generate summary.txt files for each prompt variation directory.
This creates a quick text file showing success rate for each prompt.
"""

import argparse
from pathlib import Path


def count_successes(prompt_dir):
    """Count successes and total episodes in a prompt directory."""
    success_count = 0
    total_count = 0

    for episode_dir in prompt_dir.iterdir():
        if episode_dir.is_dir() and episode_dir.name.startswith('episode_'):
            total_count += 1
            if 'success' in episode_dir.name.lower():
                success_count += 1

    return success_count, total_count


def generate_summary(prompt_dir):
    """Generate summary.txt for a single prompt directory."""
    # Read the prompt
    prompt_file = prompt_dir / 'prompt.txt'
    if prompt_file.exists():
        with open(prompt_file, 'r') as f:
            prompt_text = f.read().strip()
    else:
        prompt_text = "Unknown prompt"

    # Count successes
    success_count, total_count = count_successes(prompt_dir)

    if total_count == 0:
        return None  # No episodes yet

    success_rate = (success_count / total_count) * 100

    # Generate summary content
    summary = f"""Prompt Evaluation Summary
{'='*60}

Prompt:
  "{prompt_text}"

Results:
  Successes:    {success_count}/{total_count}
  Success Rate: {success_rate:.1f}%
  Failures:     {total_count - success_count}

Episode Breakdown:
"""

    # List all episodes
    episodes = sorted([d for d in prompt_dir.iterdir()
                      if d.is_dir() and d.name.startswith('episode_')])

    for episode_dir in episodes:
        episode_name = episode_dir.name
        status = "✓ SUCCESS" if 'success' in episode_name.lower() else "✗ FAILURE"
        summary += f"  {episode_name}: {status}\n"

    summary += f"\n{'='*60}\n"
    summary += f"Generated from: {prompt_dir}\n"

    return summary


def process_results_dir(results_dir, overwrite=False):
    """Process all prompt directories in results directory."""
    results_dir = Path(results_dir)
    processed = 0
    skipped = 0

    print(f"Processing results in: {results_dir}")
    print("=" * 60)

    # Find all prompt directories
    for task_dir in results_dir.iterdir():
        if not task_dir.is_dir():
            continue

        task_name = task_dir.name

        for prompt_dir in task_dir.iterdir():
            if not prompt_dir.is_dir() or not prompt_dir.name.startswith('prompt_'):
                continue

            summary_file = prompt_dir / 'summary.txt'

            # Skip if already exists and not overwriting
            if summary_file.exists() and not overwrite:
                print(f"⏭️  Skipping (exists): {prompt_dir.relative_to(results_dir)}")
                skipped += 1
                continue

            # Generate summary
            summary_content = generate_summary(prompt_dir)

            if summary_content:
                with open(summary_file, 'w') as f:
                    f.write(summary_content)

                # Extract success rate for display
                success_count, total_count = count_successes(prompt_dir)
                success_rate = (success_count / total_count) * 100

                print(f"✅ Generated: {prompt_dir.relative_to(results_dir)}")
                print(f"   Success: {success_count}/{total_count} ({success_rate:.1f}%)")
                processed += 1
            else:
                print(f"⚠️  No episodes: {prompt_dir.relative_to(results_dir)}")

    print("\n" + "=" * 60)
    print(f"Summary:")
    print(f"  Processed: {processed}")
    print(f"  Skipped:   {skipped}")
    print(f"  Total:     {processed + skipped}")


def main():
    parser = argparse.ArgumentParser(
        description='Generate summary.txt files for each prompt variation'
    )
    parser.add_argument(
        '--results-dir',
        type=str,
        required=True,
        help='Results directory containing prompt variations'
    )
    parser.add_argument(
        '--overwrite',
        action='store_true',
        help='Overwrite existing summary.txt files'
    )

    args = parser.parse_args()

    process_results_dir(args.results_dir, overwrite=args.overwrite)


if __name__ == '__main__':
    main()
