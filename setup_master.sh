#!/bin/bash
# ============================================================
# SCRIPT 1: Run this on the MASTER NODE only
# EC2 Ubuntu 22.04 - Hadoop 3.3.6 Master Setup
# ============================================================

set -e  # Exit on any error

echo "======================================"
echo " Step 1: System Update & Java Install"
echo "======================================"
sudo apt-get update -y
sudo apt-get install -y openjdk-11-jdk wget ssh pdsh

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
# IMPORTANT: Replace MASTER_PRIVATE_IP below with your master node's private IP
MASTER_IP="MASTER_PRIVATE_IP"

sudo -u hadoop bash -c "cat > /home/hadoop/hadoop/etc/hadoop/core-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://${MASTER_IP}:9000</value>
  </property>
  <property>
    <name>hadoop.tmp.dir</name>
    <value>/home/hadoop/hadooptmpdata</value>
  </property>
</configuration>
EOF"

echo "======================================"
echo " Step 7: Configure hdfs-site.xml"
echo "======================================"
sudo -u hadoop mkdir -p /home/hadoop/hdfs/namenode
sudo -u hadoop mkdir -p /home/hadoop/hdfs/datanode

sudo -u hadoop bash -c "cat > /home/hadoop/hadoop/etc/hadoop/hdfs-site.xml << EOF
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>2</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///home/hadoop/hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
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
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>mapreduce.application.classpath</name>
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
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>${MASTER_IP}</value>
  </property>
</configuration>
EOF"

echo "======================================"
echo " Step 10: Generate SSH Key (Master)"
echo "======================================"
sudo -u hadoop bash -c "
  mkdir -p /home/hadoop/.ssh
  chmod 700 /home/hadoop/.ssh
  if [ ! -f /home/hadoop/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 2048 -f /home/hadoop/.ssh/id_rsa -N ''
    echo 'SSH key generated.'
  else
    echo 'SSH key already exists.'
  fi
  cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys
  chmod 600 /home/hadoop/.ssh/authorized_keys
"

echo ""
echo "============================================================"
echo " MASTER SETUP COMPLETE"
echo "============================================================"
echo ""
echo " NEXT STEPS:"
echo " 1. Note your master node's PRIVATE IP address:"
echo "    Run: hostname -I | awk '{print \$1}'"
echo ""
echo " 2. Copy the master's public SSH key to both worker nodes:"
echo "    Run: cat /home/hadoop/.ssh/id_rsa.pub"
echo "    Then paste that into /home/hadoop/.ssh/authorized_keys on each worker"
echo ""
echo " 3. Run 2_setup_worker.sh on BOTH worker nodes"
echo " 4. Then come back and run 3_configure_cluster.sh on this master"
echo "============================================================"
