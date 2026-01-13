#!/bin/bash
set -e

HOST="mysql_server"

# Function to wait for MySQL
wait_for_mysql() {
    echo "正在等待 MySQL ($HOST) 啟動..."
    until mysql -h "$HOST" -u root -proot -e "SELECT 1" >/dev/null 2>&1; do
        sleep 2
    done
    echo "MySQL 已就緒。"
}

# Check Configuration function
check_config() {
    echo "=================================================="
    echo "目前資料庫配置驗證"
    echo "=================================================="
    mysql -h "$HOST" -u root -proot -N -e "SELECT CONCAT('innodb_log_buffer_size: ', FORMAT(@@innodb_log_buffer_size/1024/1024, 2), ' MB')"
    mysql -h "$HOST" -u root -proot -N -e "SELECT CONCAT('MySQL 版本: ', @@version)"
    echo "=================================================="
}

# Prepare function
prepare_db() {
    echo "正在準備測試資料..."
    sysbench oltp_common \
        --mysql-host="$HOST" \
        --mysql-user=root \
        --mysql-password=root \
        --mysql-db=sbtest \
        --tables=5 \
        cleanup >/dev/null 2>&1 || true

    sysbench oltp_common \
        --mysql-host="$HOST" \
        --mysql-user=root \
        --mysql-password=root \
        --mysql-db=sbtest \
        --table-size=100000 \
        --tables=5 \
        prepare
}

# Run Large Transaction Test
run_large_txn() {
    echo "------------------------------------------------"
    echo "正在執行：大事務測試 (Large Transaction Test)"
    echo "每筆事務包含 2000 次索引更新，持續 120 秒"
    echo "------------------------------------------------"

    # Capture initial Innodb_log_waits
    local wait_start=$(mysql -h "$HOST" -u root -proot -N -e "SHOW GLOBAL STATUS LIKE 'Innodb_log_waits';" | awk '{print $2}')
    echo "初始 Innodb_log_waits: $wait_start"

    sysbench oltp_read_write \
        --mysql-host="$HOST" \
        --mysql-user=root \
        --mysql-password=root \
        --mysql-db=sbtest \
        --table-size=100000 \
        --tables=5 \
        --threads=10 \
        --time=120 \
        --report-interval=10 \
        --point_selects=0 \
        --simple_ranges=0 \
        --sum_ranges=0 \
        --order_ranges=0 \
        --distinct_ranges=0 \
        --index_updates=2000 \
        --non_index_updates=0 \
        --delete_inserts=0 \
        run > res_large.txt
    
    # Capture final Innodb_log_waits
    local wait_end=$(mysql -h "$HOST" -u root -proot -N -e "SHOW GLOBAL STATUS LIKE 'Innodb_log_waits';" | awk '{print $2}')
    local wait_delta=$((wait_end - wait_start))

    local tps=$(grep "transactions:" res_large.txt | awk -F'(' '{print $2}' | awk '{print $1}')
    local lat=$(grep "95th percentile:" res_large.txt | awk '{print $3}')
    
    echo "------------------------------------------------"
    echo "測試結果:"
    echo "TPS: $tps"
    echo "95% Latency: $lat ms"
    echo "Innodb_log_waits 增加量: $wait_delta (若 > 0 表示 Log Buffer 不足)"
    echo "------------------------------------------------"
    
    rm res_large.txt
}

# Main Execution
wait_for_mysql
check_config
prepare_db
run_large_txn

echo ""
echo "=================================================="
echo "測試完成。請記錄以上數據，修改配置並重啟後再次執行。"
echo "=================================================="