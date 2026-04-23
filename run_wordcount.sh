#!/bin/bash
# ============================================================
# SCRIPT 4: Run this on the MASTER NODE
# Compiles WordCount.java and runs it on the input book
# ============================================================
# BEFORE RUNNING:
#   Make sure WordCount.java and input.txt are in the same
#   directory as this script

set -e

HADOOP_HOME=/home/hadoop/hadoop
INPUT_FILE="input.txt"
JAVA_FILE="WordCount.java"

echo "======================================"
echo " Step 1: Check Required Files"
echo "======================================"
if [ ! -f "$INPUT_FILE" ]; then
  echo "ERROR: $INPUT_FILE not found in current directory!"
  echo "Please place your book text file here as input.txt"
  exit 1
fi

if [ ! -f "$JAVA_FILE" ]; then
  echo "ERROR: $JAVA_FILE not found in current directory!"
  exit 1
fi

echo "Found $INPUT_FILE and $JAVA_FILE. Continuing..."

echo "======================================"
echo " Step 2: Compile WordCount.java"
echo "======================================"
mkdir -p wordcount_classes

$HADOOP_HOME/bin/hadoop com.sun.tools.javac.Main \
  -classpath $($HADOOP_HOME/bin/hadoop classpath) \
  -d wordcount_classes \
  $JAVA_FILE

echo "Compilation successful."

echo "======================================"
echo " Step 3: Package into JAR"
echo "======================================"
jar -cvf wordcount.jar -C wordcount_classes .
echo "JAR created: wordcount.jar"

echo "======================================"
echo " Step 4: Upload Input File to HDFS"
echo "======================================"
# Remove old input dir if it exists
$HADOOP_HOME/bin/hdfs dfs -rm -r -f /user/hadoop/input

$HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hadoop/input
$HADOOP_HOME/bin/hdfs dfs -put $INPUT_FILE /user/hadoop/input/
echo "Input file uploaded to HDFS at /user/hadoop/input/"

echo "======================================"
echo " Step 5: Run the WordCount Job"
echo "======================================"
# Remove old output if it exists
$HADOOP_HOME/bin/hdfs dfs -rm -r -f /user/hadoop/output

echo "Starting MapReduce job..."
$HADOOP_HOME/bin/hadoop jar wordcount.jar WordCount \
  /user/hadoop/input \
  /user/hadoop/output

echo "======================================"
echo " Step 6: View the Results"
echo "======================================"
echo ""
echo "--- Top 50 word counts ---"
$HADOOP_HOME/bin/hdfs dfs -cat /user/hadoop/output/part-r-00000 | sort -t$'\t' -k2 -rn | head -50

echo ""
echo "======================================"
echo " Step 7: Save Results Locally"
echo "======================================"
$HADOOP_HOME/bin/hdfs dfs -get /user/hadoop/output/part-r-00000 ./wordcount_results.txt
echo "Full results saved to: wordcount_results.txt"

echo ""
echo "============================================================"
echo " JOB COMPLETE!"
echo "============================================================"
echo " Results file: wordcount_results.txt"
echo " Take a screenshot of this output for your PDF report!"
echo "============================================================"
