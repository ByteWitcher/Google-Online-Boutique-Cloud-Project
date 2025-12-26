import os
import pandas as pd
import matplotlib.pyplot as plt

BASE_DIR = "advanced_steps/2_performance_evaluation/results"

results = []

# Iterate over users_* directories
for d in sorted(os.listdir(BASE_DIR)):
    if not d.startswith("users_"):
        continue

    users = int(d.split("_")[1])
    stats_file = os.path.join(BASE_DIR, d, f"locust_{users}_stats.csv")

    if not os.path.exists(stats_file):
        print(f"Missing stats file for {users} users")
        continue

    df = pd.read_csv(stats_file)

    # Extract Aggregated row
    agg = df[df["Name"] == "Aggregated"]
    if agg.empty:
        print(f"No Aggregated row for {users} users")
        continue

    row = agg.iloc[0]

    results.append({
        "users": users,
        "requests_per_sec": row["Requests/s"],
        "failure_rate": (
            row["Failure Count"] / row["Request Count"]
            if row["Request Count"] > 0 else 0
        ),
        "p50": row["50%"],
        "p95": row["95%"],
        "p99": row["99%"]
    })

# Convert to DataFrame
res_df = pd.DataFrame(results).sort_values("users")

# Plot 1: Throughput
plt.figure()
plt.plot(res_df["users"], res_df["requests_per_sec"], marker="o")
plt.xlabel("Concurrent users")
plt.ylabel("Requests per second")
plt.title("Throughput vs Concurrent Users")
plt.grid(True)
plt.tight_layout()
plt.savefig("advanced_steps/2_performance_evaluation/results/plots/throughput_vs_users.png")
plt.close()

# Plot 2: Latency
plt.figure()
plt.plot(res_df["users"], res_df["p50"], marker="o", label="p50")
plt.plot(res_df["users"], res_df["p95"], marker="o", label="p95")
plt.plot(res_df["users"], res_df["p99"], marker="o", label="p99")
plt.xlabel("Concurrent users")
plt.ylabel("Response time (ms)")
plt.title("Latency vs Concurrent Users")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("advanced_steps/2_performance_evaluation/results/plots/latency_vs_users.png")
plt.close()

# Plot 3: Failure rate
plt.figure()
plt.plot(res_df["users"], res_df["failure_rate"] * 100, marker="o")
plt.xlabel("Concurrent users")
plt.ylabel("Failure rate (%)")
plt.title("Failure Rate vs Concurrent Users")
plt.grid(True)
plt.tight_layout()
plt.savefig("advanced_steps/2_performance_evaluation/results/plots/failure_rate_vs_users.png")
plt.close()

print("Plots generated:")
print("- throughput_vs_users.png")
print("- latency_vs_users.png")
print("- failure_rate_vs_users.png")
