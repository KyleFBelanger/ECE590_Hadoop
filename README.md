# Hadoop Word Count — ECE Cloud Computing Homework 1
**UMass Amherst | Team Members:** [Name 1], [Name 2], [Name 3]

---

## What This Does
Runs a MapReduce Word Count job across a 3-node Hadoop cluster on AWS EC2.
One master node (NameNode + ResourceManager) and two worker nodes (DataNodes).

---

## Files Included
| File | Purpose |
|------|---------|
| `1_setup_master.sh` | Run once on the master EC2 instance |
| `2_setup_worker.sh` | Run on each of the two worker EC2 instances |
| `3_configure_cluster.sh` | Run on master after both workers are ready |
| `4_run_wordcount.sh` | Compiles the Java code and runs the Hadoop job |
| `WordCount.java` | The MapReduce source code |
| `input.txt` | The book used as input (~1000+ pages) |

---

## EC2 Setup (Do This First in AWS Console)

1. Launch **3 EC2 instances** with these settings:
   - AMI: **Ubuntu 22.04 LTS**
   - Instance type: `t2.medium` (recommended) or `t2.small`
   - Key pair: use the same `.pem` key for all 3
   - Security group: open ports **22, 9000, 9870, 8088** (allow from anywhere or your IP)
   - Name them: `hadoop-master`, `hadoop-worker1`, `hadoop-worker2`

2. Note the **private IP addresses** of all 3 instances from the AWS console.

---

## Step-by-Step Instructions

### Step 1 — Setup the Master Node
SSH into the master instance:
```bash
ssh -i your-key.pem ubuntu@<MASTER_PUBLIC_IP>
```
Upload and run the master setup script:
```bash
scp -i your-key.pem 1_setup_master.sh ubuntu@<MASTER_PUBLIC_IP>:~
ssh -i your-key.pem ubuntu@<MASTER_PUBLIC_IP>
chmod +x 1_setup_master.sh
sudo ./1_setup_master.sh
```
When it finishes, get the master's public SSH key:
```bash
sudo cat /home/hadoop/.ssh/id_rsa.pub
```
**Copy this key — you'll need it for the workers.**

---

### Step 2 — Setup Both Worker Nodes
For each worker (repeat for both `worker1` and `worker2`):

```bash
scp -i your-key.pem 2_setup_worker.sh ubuntu@<WORKER_PUBLIC_IP>:~
ssh -i your-key.pem ubuntu@<WORKER_PUBLIC_IP>
```

**Edit the script first** — open `2_setup_worker.sh` and replace:
```
MASTER_IP="MASTER_PRIVATE_IP"
```
with the actual master private IP, e.g.:
```
MASTER_IP="172.31.10.5"
```

Then run it:
```bash
chmod +x 2_setup_worker.sh
sudo ./2_setup_worker.sh
```

After it finishes, paste the master's SSH public key into the worker:
```bash
sudo -u hadoop bash -c 'echo "<PASTE_MASTER_PUBLIC_KEY_HERE>" >> /home/hadoop/.ssh/authorized_keys'
```

---

### Step 3 — Configure the Cluster (Back on Master)
SSH back into the master node. Upload `3_configure_cluster.sh`.

**Edit the script** — replace the placeholder IPs:
```
WORKER1_IP="WORKER1_PRIVATE_IP"   →   e.g. "172.31.10.6"
WORKER2_IP="WORKER2_PRIVATE_IP"   →   e.g. "172.31.10.7"
```

Then run:
```bash
chmod +x 3_configure_cluster.sh
sudo -u hadoop ./3_configure_cluster.sh
```

✅ If successful, you'll see the HDFS report showing 2 live datanodes.

You can also verify in a browser:
- HDFS UI: `http://<MASTER_PUBLIC_IP>:9870`
- YARN UI: `http://<MASTER_PUBLIC_IP>:8088`

---

### Step 4 — Run the Word Count Job
Upload `4_run_wordcount.sh`, `WordCount.java`, and `input.txt` to the master:
```bash
scp -i your-key.pem 4_run_wordcount.sh WordCount.java input.txt ubuntu@<MASTER_PUBLIC_IP>:~
```

SSH into the master and run:
```bash
chmod +x 4_run_wordcount.sh
sudo -u hadoop ./4_run_wordcount.sh
```

Results will print to screen and also save to `wordcount_results.txt`.

**Take screenshots of:**
- The job running output (map/reduce progress percentages)
- The top word counts printed at the end
- The HDFS Web UI showing your input/output files

---

## Stopping the Cluster
When done, stop Hadoop to avoid unnecessary charges:
```bash
sudo -u hadoop /home/hadoop/hadoop/sbin/stop-yarn.sh
sudo -u hadoop /home/hadoop/hadoop/sbin/stop-dfs.sh
```
Then stop/terminate the EC2 instances from the AWS Console.

---

## Troubleshooting
| Problem | Fix |
|---------|-----|
| SSH to worker fails | Make sure master's public key is in worker's `authorized_keys` |
| "Connection refused" on port 9000 | Check EC2 security group has port 9000 open |
| Only 1 datanode showing | Worker script may not have finished — re-run `2_setup_worker.sh` |
| NameNode won't start | Run `hdfs namenode -format -force` then restart |
