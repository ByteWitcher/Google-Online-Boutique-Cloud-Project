import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

def generate_service_plots(csv_file):
    df = pd.read_csv(csv_file)
    df = df.dropna(subset=['Pod', 'Experiment'])
    cols_to_clean = ['CPU Requests %', 'CPU Limits %', 'Memory Requests %', 'Memory Limits %']
    for col in cols_to_clean:
        if df[col].dtype == 'object':
            df[col] = df[col].str.replace('%', '').astype(float)
    df['Exp_Num'] = df['Experiment'].str.extract('(\d+)').astype(int)
    df = df.sort_values(by=['Exp_Num', 'Pod'])

    # Plot 1: CPU Requests
    plt.figure(figsize=(12, 6))
    sns.lineplot(data=df, x='Experiment', y='CPU Requests %', hue='Pod', marker='o')
    plt.title('CPU Requests % Trend Across Experiments')
    plt.ylabel('CPU Requests (%)')
    plt.xlabel('Experiment')
    plt.xticks(rotation=45)
    plt.legend(title='Service (Pod)', bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, linestyle='--', alpha=0.6)
    plt.tight_layout()
    plt.savefig('advanced_steps/2_performance_evaluation/results/plots/cpu_requests_trend.png')
    print("Saved: cpu_requests_trend.png")

    # Plot 2: Memory Requests
    plt.figure(figsize=(12, 6))
    sns.lineplot(data=df, x='Experiment', y='Memory Requests %', hue='Pod', marker='o')
    plt.title('Memory Requests % Trend Across Experiments')
    plt.ylabel('Memory Requests (%)')
    plt.xlabel('Experiment')
    plt.xticks(rotation=45)
    plt.legend(title='Service (Pod)', bbox_to_anchor=(1.05, 1), loc='upper left')
    plt.grid(True, linestyle='--', alpha=0.6)
    plt.tight_layout()
    plt.savefig('advanced_steps/2_performance_evaluation/results/plots/memory_requests_trend.png')
    print("Saved: memory_requests_trend.png")

    # Plot 3: CPU Heatmap
    pivot_cpu = df.pivot(index='Pod', columns='Experiment', values='CPU Requests %')
    
    sorted_columns = sorted(pivot_cpu.columns, key=lambda x: int(x[1:]))
    pivot_cpu = pivot_cpu[sorted_columns]

    plt.figure(figsize=(14, 8))
    sns.heatmap(pivot_cpu, annot=True, fmt=".1f", cmap="YlGnBu", cbar_kws={'label': 'CPU Requests %'})
    plt.title('Heatmap of CPU Requests % by Pod and Experiment')
    plt.ylabel('Service (Pod)')
    plt.xlabel('Experiment')
    plt.tight_layout()
    plt.savefig('advanced_steps/2_performance_evaluation/results/plots/cpu_heatmap.png')
    print("Saved: cpu_heatmap.png")

if __name__ == "__main__":
    generate_service_plots('advanced_steps/2_performance_evaluation/results/quota.csv')