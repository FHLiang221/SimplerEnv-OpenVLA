#!/usr/bin/env python3
"""
Analyze prompt robustness results across different prompt variations.
This script aggregates metrics from multiple prompt variations and computes statistics.
"""

import argparse
import json
import os
from pathlib import Path
from collections import defaultdict
import yaml


def parse_metrics_file(metrics_file):
    """Parse a metrics file and extract success rate."""
    with open(metrics_file, 'r') as f:
        content = f.read()
        # Look for "Success Rate: X.XX"
        for line in content.split('\n'):
            if 'Success Rate' in line or 'success rate' in line.lower():
                # Extract the number
                parts = line.split(':')
                if len(parts) >= 2:
                    try:
                        rate = float(parts[1].strip().rstrip('%'))
                        return rate
                    except ValueError:
                        continue
    return None


def analyze_prompt_variations(results_dir, prompt_yaml=None):
    """Analyze results from prompt variation experiments."""
    results_dir = Path(results_dir)

    # Load prompt texts if YAML provided
    prompts_dict = {}
    if prompt_yaml and os.path.exists(prompt_yaml):
        with open(prompt_yaml, 'r') as f:
            prompts_dict = yaml.safe_load(f)

    # Find all task directories
    task_results = defaultdict(lambda: {'prompts': [], 'success_rates': []})

    for task_dir in results_dir.iterdir():
        if not task_dir.is_dir():
            continue

        task_name = task_dir.name

        # Find all prompt variation directories
        for prompt_dir in task_dir.iterdir():
            if not prompt_dir.is_dir() or not prompt_dir.name.startswith('prompt_'):
                continue

            prompt_idx = int(prompt_dir.name.split('_')[1])

            # Read the prompt text
            prompt_file = prompt_dir / 'prompt.txt'
            if prompt_file.exists():
                with open(prompt_file, 'r') as f:
                    prompt_text = f.read().strip()
            else:
                prompt_text = f"Prompt {prompt_idx}"

            # Look for metrics in video directories
            success_count = 0
            total_count = 0

            for video_dir in prompt_dir.iterdir():
                if video_dir.is_dir() and video_dir.name.startswith('episode_'):
                    # Check for success in the directory name or info file
                    if 'success' in video_dir.name:
                        success_count += 1
                    total_count += 1

            if total_count > 0:
                success_rate = (success_count / total_count) * 100
                task_results[task_name]['prompts'].append(prompt_text)
                task_results[task_name]['success_rates'].append(success_rate)

    return task_results


def print_analysis(task_results):
    """Print formatted analysis of results."""
    print("\n" + "="*80)
    print("📊 PROMPT ROBUSTNESS ANALYSIS")
    print("="*80)

    for task_name, results in sorted(task_results.items()):
        print(f"\n{'─'*80}")
        print(f"📋 Task: {task_name}")
        print(f"{'─'*80}")

        prompts = results['prompts']
        success_rates = results['success_rates']

        if not success_rates:
            print("  ⚠️  No results found")
            continue

        # Compute statistics
        mean_rate = sum(success_rates) / len(success_rates)
        min_rate = min(success_rates)
        max_rate = max(success_rates)
        std_rate = (sum((x - mean_rate) ** 2 for x in success_rates) / len(success_rates)) ** 0.5

        print(f"\n  📈 Overall Statistics:")
        print(f"     • Mean Success Rate: {mean_rate:.1f}%")
        print(f"     • Min Success Rate:  {min_rate:.1f}%")
        print(f"     • Max Success Rate:  {max_rate:.1f}%")
        print(f"     • Std Deviation:     {std_rate:.1f}%")
        print(f"     • Prompt Variations: {len(prompts)}")

        print(f"\n  📝 Results by Prompt:")
        for prompt, rate in sorted(zip(prompts, success_rates), key=lambda x: x[1], reverse=True):
            status = "✅" if rate >= mean_rate else "⚠️ "
            print(f"     {status} {rate:5.1f}% | \"{prompt}\"")

    print("\n" + "="*80)

    # Overall summary
    all_rates = []
    for results in task_results.values():
        all_rates.extend(results['success_rates'])

    if all_rates:
        print("\n🎯 OVERALL SUMMARY")
        print(f"   • Total Tasks: {len(task_results)}")
        print(f"   • Total Evaluations: {len(all_rates)}")
        print(f"   • Average Success Rate: {sum(all_rates) / len(all_rates):.1f}%")
        print(f"   • Overall Std Dev: {(sum((x - sum(all_rates)/len(all_rates)) ** 2 for x in all_rates) / len(all_rates)) ** 0.5:.1f}%")

    print("="*80 + "\n")


def save_json_report(task_results, output_file):
    """Save analysis results to JSON file."""
    report = {
        'tasks': {}
    }

    all_rates = []
    for task_name, results in task_results.items():
        prompts = results['prompts']
        success_rates = results['success_rates']

        if not success_rates:
            continue

        mean_rate = sum(success_rates) / len(success_rates)
        std_rate = (sum((x - mean_rate) ** 2 for x in success_rates) / len(success_rates)) ** 0.5

        report['tasks'][task_name] = {
            'mean_success_rate': mean_rate,
            'min_success_rate': min(success_rates),
            'max_success_rate': max(success_rates),
            'std_deviation': std_rate,
            'num_prompts': len(prompts),
            'prompt_results': [
                {'prompt': p, 'success_rate': r}
                for p, r in zip(prompts, success_rates)
            ]
        }

        all_rates.extend(success_rates)

    if all_rates:
        report['overall'] = {
            'num_tasks': len(task_results),
            'num_evaluations': len(all_rates),
            'average_success_rate': sum(all_rates) / len(all_rates),
            'std_deviation': (sum((x - sum(all_rates)/len(all_rates)) ** 2 for x in all_rates) / len(all_rates)) ** 0.5
        }

    with open(output_file, 'w') as f:
        json.dump(report, f, indent=2)

    print(f"📄 JSON report saved to: {output_file}")


def main():
    parser = argparse.ArgumentParser(description="Analyze prompt robustness results")
    parser.add_argument(
        '--results-dir',
        type=str,
        required=True,
        help='Directory containing prompt variation results'
    )
    parser.add_argument(
        '--prompt-yaml',
        type=str,
        default=None,
        help='Original prompt YAML file (optional)'
    )
    parser.add_argument(
        '--output-json',
        type=str,
        default=None,
        help='Output JSON file for detailed report'
    )

    args = parser.parse_args()

    # Analyze results
    task_results = analyze_prompt_variations(args.results_dir, args.prompt_yaml)

    # Print analysis
    print_analysis(task_results)

    # Save JSON report if requested
    if args.output_json:
        save_json_report(task_results, args.output_json)


if __name__ == '__main__':
    main()
