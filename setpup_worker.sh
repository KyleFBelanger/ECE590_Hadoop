#!/bin/bash
# ============================================================
# SCRIPT 2: Run this on BOTH WORKER NODES
# EC2 Ubuntu 22.04 - Hadoop 3.3.6 Worker Setup
# ============================================================
# BEFORE RUNNING: Replace MASTER_PRIVATE_IP with actual IP

set -e

MASTER_IP="MASTER_PRIVATE_IP"  # <-- CHANGE THIS

echo "======================================"
echo " Step 1: System Update & Java Install"
echo "======================================"
sudo apt-get update -y
sudo apt-get install -y openjdk-11-jdk wget ssh

java -version
echo "Java installed successfully."

echo "======================================"
echo " Step 2: Create Hadoop User"
echo "======================================"
sudo adduser --disabled-password --gecos "" hadoop || echo "User hadoop already exists"
sudo usermod -aG sudo hadoop

echo "======================================"
echo " Step 3: Download & Install Hadoop"
echo "======================================"
cd /home/hadoop
sudo -u hadoop wget -q https://downloads.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
sudo -u hadoop tar -xzf hadoop-3.3.6.tar.gz
sudo -u hadoop mv hadoop-3.3.6 hadoop
rm -f hadoop-3.3.6.tar.gz
echo "Hadoop downloaded and extracted."

echo "======================================"
echo " Step 4: Set Environment Variables"
echo "======================================"
JAVA_HOME_PATH=$(readlink -f /usr/bin/java | sed "s:bin/java::")

sudo -u hadoop bash -c "cat >> /home/hadoop/.bashrc << 'EOF'

# Hadoop Environment Variables
export JAVA_HOME=${JAVA_HOME_PATH}
export HADOOP_HOME=/home/hadoop/hadoop
export HADOOP_INSTALL=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin
export HADOOP_OPTS=\"-Djava.library.path=\$HADOOP_HOME/lib/native\"
EOF"

echo "======================================"
echo " Step 5: Configure hadoop-env.sh"
echo "======================================"
sudo -u hadoop bash -c "echo 'export JAVA_HOME=${JAVA_HOME_PATH}' >> /home/hadoop/hadoop/etc/hadoop/hadoop-env.sh"

echo "======================================"
echo " Step 6: Configure core-site.xml"
echo "======================================"
sudo -u hadoop bash -c "cat > /home/hadoop/hadoop/etc/hadoop/core-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
  <property>
    <n>fs.defaultFS</n>
    <value>hdfs://${MASTER_IP}:9000</value>
  </property>
  <property>
    <n>hadoop.tmp.dir</n>
    <value>/home/hadoop/hadooptmpdata</value>
  </property>
</configuration>
EOF"

echo "======================================"
echo " Step 7: Configure hdfs-site.xml"
echo "======================================"
sudo -u hadoop mkdir -p /home/hadoop/hdfs/datanode

sudo -u hadoop bash -c "cat > /home/hadoop/hadoop/etc/hadoop/hdfs-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
  <property>
    <n>dfs.replication</n>
    <value>2</value>
  </property>
  <property>
    <n>dfs.datanode.data.dir</n>
    <value>file:///home/hadoop/hdfs/datanode</value>
  </property>
</configuration>
EOF"

echo "======================================"
echo " Step 8: Configure mapred-site.xml"
echo "======================================"
sudo -u hadoop bash -c "cat > /home/hadoop/hadoop/etc/hadoop/mapred-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
  <property>
    <n>mapreduce.framework.name</n>
    <value>yarn</value>
  </property>
  <property>
    <n>mapreduce.application.classpath</n>
    <value>\$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:\$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
  </property>
</configuration>
EOF"

echo "======================================"
echo " Step 9: Configure yarn-site.xml"
echo "======================================"
sudo -u hadoop bash -c "cat > /home/hadoop/hadoop/etc/hadoop/yarn-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
  <property>
    <n>yarn.nodemanager.aux-services</n>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <n>yarn.resourcemanager.hostname</n>
    <value>${MASTER_IP}</value>
  </property>
</configuration>
EOF"

echo "======================================"
echo " Step 10: Setup SSH for hadoop user"
echo "======================================"
sudo -u hadoop bash -c "
  mkdir -p /home/hadoop/.ssh
  chmod 700 /home/hadoop/.ssh
  touch /home/hadoop/.ssh/authorized_keys
  chmod 600 /home/hadoop/.ssh/authorized_keys
"

echo ""
echo "============================================================"
echo " WORKER SETUP COMPLETE"
echo "============================================================"
echo ""
echo " NEXT STEPS:"
echo " 1. Get this worker's private IP:"
echo "    Run: hostname -I | awk '{print \$1}'"
echo "    Give this IP to whoever is running 3_configure_cluster.sh"
echo ""
echo " 2. Paste the master's public SSH key into this worker:"
echo "    Run: echo \"<MASTER_PUBLIC_KEY>\" >> /home/hadoop/.ssh/authorized_keys"
echo "    (Get the master's public key from: cat /home/hadoop/.ssh/id_rsa.pub on master)"
echo "============================================================"
