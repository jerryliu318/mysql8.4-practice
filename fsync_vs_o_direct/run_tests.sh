#!/bin/bash
set -e

HOST="mysql84"
DB_USER="root"
DB_PASS="root"
DB_NAME="sys"

# Function to wait for MySQL
wait_for_mysql() {
    echo "正在等待 MySQL ($HOST) 啟動..."
    until mysql -h "$HOST" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1" >/dev/null 2>&1; do
        sleep 2
    done
    echo "MySQL 已就緒。"
}

# Check Configuration function
check_config() {
    echo ""
    echo "=================================================="
    echo "🔍 測試目標配置驗證"
    echo "=================================================="
    FLUSH_METHOD=$(mysql -h "$HOST" -u "$DB_USER" -p"$DB_PASS" -N -s -e "SELECT @@innodb_flush_method")
    BUFFER_POOL=$(mysql -h "$HOST" -u "$DB_USER" -p"$DB_PASS" -N -s -e "SELECT @@innodb_buffer_pool_size/1024/1024")
    MYSQL_VER=$(mysql -h "$HOST" -u "$DB_USER" -p"$DB_PASS" -N -s -e "SELECT @@version")
    echo "MySQL 版本: $MYSQL_VER"
    echo "當前 innodb_flush_method: $FLUSH_METHOD"
    echo "當前 innodb_buffer_pool_size: ${BUFFER_POOL} MB"
    echo "=================================================="
    echo ""
}

# Prepare function
prepare_db() {
    echo "正在準備測試資料..."
    sysbench oltp_write_only \
        --mysql-host="$HOST" \
        --mysql-port=3306 \
        --mysql-user="$DB_USER" \
        --mysql-password="$DB_PASS" \
        --mysql-db="$DB_NAME" \
        --tables=10 \
        --table-size=500000 \
        --threads=8 \
        cleanup >/dev/null 2>&1 || true

    sysbench oltp_write_only \
        --mysql-host="$HOST" \
        --mysql-port=3306 \
        --mysql-user="$DB_USER" \
        --mysql-password="$DB_PASS" \
        --mysql-db="$DB_NAME" \
        --tables=10 \
        --table-size=500000 \
        --threads=8 \
        prepare
}

# Run Benchmark
run_benchmark() {
    echo "------------------------------------------------"
    echo "正在執行：大量寫入測試 (OLTP Write Only)"
    echo "Tables: 10, Size: 100k, Threads: 16, Time: 60s"
    echo "------------------------------------------------"

    sysbench oltp_write_only \
        --mysql-host="$HOST" \
        --mysql-port=3306 \
        --mysql-user="$DB_USER" \
        --mysql-password="$DB_PASS" \
        --mysql-db="$DB_NAME" \
        --tables=10 \
        --table-size=500000 \
        --threads=16 \
        --time=60 \
        --report-interval=2 \
        run > res_benchmark.txt
    
    cat res_benchmark.txt

    local tps=$(grep "transactions:" res_benchmark.txt | awk -F'(' '{print $2}' | awk '{print $1}')
    local lat=$(grep "95th percentile:" res_benchmark.txt | awk '{print $3}')
    
    echo "------------------------------------------------"
    echo "測試摘要:"
    echo "TPS: $tps"
    echo "95% Latency: $lat ms"
    echo "------------------------------------------------"
    
    rm res_benchmark.txt
}

# Cleanup function
cleanup_db() {
    echo "正在清理測試資料..."
    sysbench oltp_write_only \
        --mysql-host="$HOST" \
        --mysql-port=3306 \
        --mysql-user="$DB_USER" \
        --mysql-password="$DB_PASS" \
        --mysql-db="$DB_NAME" \
        --tables=10 \
        --table-size=500000 \
        cleanup >/dev/null 2>&1
}

# Main Execution
wait_for_mysql
check_config
prepare_db
run_benchmark
cleanup_db

echo ""
echo "=================================================="
echo "測試完成。"
echo "=================================================="
