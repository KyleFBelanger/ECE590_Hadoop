#!/bin/bash
# ============================================================
# SCRIPT 3: Run this on the MASTER NODE after both workers
#           have completed 2_setup_worker.sh
# EC2 Ubuntu 22.04 - Configure Cluster & Start Hadoop
# ============================================================
# BEFORE RUNNING:
#   Replace WORKER1_PRIVATE_IP and WORKER2_PRIVATE_IP below

set -e

WORKER1_IP="WORKER1_PRIVATE_IP"  # <-- CHANGE THIS
WORKER2_IP="WORKER2_PRIVATE_IP"  # <-- CHANGE THIS

echo "======================================"
echo " Step 1: Register Worker Nodes"
echo "======================================"
sudo -u hadoop bash -c "cat > /home/hadoop/hadoop/etc/hadoop/workers << EOF
${WORKER1_IP}
${WORKER2_IP}
EOF"
echo "Workers registered: ${WORKER1_IP}, ${WORKER2_IP}"

echo "======================================"
echo " Step 2: Add Workers to /etc/hosts"
echo "======================================"
MASTER_IP=$(hostname -I | awk '{print $1}')

sudo bash -c "cat >> /etc/hosts << EOF

# Hadoop Cluster
${MASTER_IP}   hadoop-master
${WORKER1_IP}  hadoop-worker1
${WORKER2_IP}  hadoop-worker2
EOF"
echo "Hosts file updated."

echo "======================================"
echo " Step 3: Test SSH to Worker Nodes"
echo "======================================"
echo "Testing SSH to worker1..."
sudo -u hadoop ssh -o StrictHostKeyChecking=no hadoop@${WORKER1_IP} "echo 'SSH to worker1: OK'"

echo "Testing SSH to worker2..."
sudo -u hadoop ssh -o StrictHostKeyChecking=no hadoop@${WORKER2_IP} "echo 'SSH to worker2: OK'"

echo "======================================"
echo " Step 4: Format the HDFS NameNode"
echo "======================================"
# Only format if not already formatted
if [ ! -d "/home/hadoop/hdfs/namenode/current" ]; then
  sudo -u hadoop /home/hadoop/hadoop/bin/hdfs namenode -format -force
  echo "NameNode formatted."
else
  echo "NameNode already formatted, skipping."
fi

echo "======================================"
echo " Step 5: Start HDFS"
echo "======================================"
sudo -u hadoop /home/hadoop/hadoop/sbin/start-dfs.sh
echo "HDFS started."

echo "======================================"
echo " Step 6: Start YARN"
echo "======================================"
sudo -u hadoop /home/hadoop/hadoop/sbin/start-yarn.sh
echo "YARN started."

echo "======================================"
echo " Step 7: Verify All Services Running"
echo "======================================"
echo "--- Master node JVM processes ---"
sudo -u hadoop /home/hadoop/hadoop/bin/hdfs dfsadmin -report

echo ""
echo "============================================================"
echo " CLUSTER IS UP AND RUNNING!"
echo "============================================================"
echo ""
echo " You can verify in a browser (if port 9870 is open in your"
echo " EC2 security group):"
echo "   HDFS Web UI:  http://${MASTER_IP}:9870"
echo "   YARN Web UI:  http://${MASTER_IP}:8088"
echo ""
echo " Next: Run 4_run_wordcount.sh to execute the MapReduce job"
echo "============================================================"
