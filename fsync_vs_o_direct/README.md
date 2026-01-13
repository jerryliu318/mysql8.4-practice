# MySQL 8.0 vs 8.4 (fsync vs O_DIRECT)

此目錄包含一組設定，用於比較配置為 `fsync` 的 MySQL 8.0 和配置為 `O_DIRECT` 的 MySQL 8.4。我們包含了一個 `sysbench` 容器來進行效能基準測試。

## 開始使用

1. 啟動容器（這會同時建置 sysbench 映像檔）：
   ```bash
   docker-compose up -d --build
   ```

## 如何檢查 `innodb_flush_method`

您可以連線到每個容器並執行 SQL 查詢以驗證刷新方法 (flush method)。

### 檢查 MySQL 8.0 (配置為 `fsync`)

1. 連線到容器：
   ```bash
   docker exec -it mysql80_fsync_check mysql -uroot -proot
   ```

2. 執行查詢：
   ```sql
   SHOW VARIABLES LIKE 'innodb_flush_method';
   SHOW VARIABLES LIKE 'innodb_use_fdatasync';
   ```
   **預期輸出：** `fsync` `ON`

### 檢查 MySQL 8.4 (配置為 `O_DIRECT`)

1. 連線到容器：
   ```bash
   docker exec -it mysql84_odirect_check mysql -uroot -proot
   ```

2. 執行查詢：
   ```sql
   SHOW VARIABLES LIKE 'innodb_flush_method';
   ```
   **預期輸出：** `O_DIRECT`

## 效能測試與觀察 (針對大量寫入)

為了觀察 `fsync` 與 `O_DIRECT` 在大量寫入時的 CPU 與效能差異，請依照以下步驟操作。

**測試策略：**
*   使用 `oltp_write_only` 腳本專注於寫入效能。
*   增加 `threads` 數量以模擬高併發寫入。
*   同時開啟另一個終端機觀察 CPU 使用率。

### 1. 準備工作 (開啟兩個終端機視窗)

*   **視窗 A**：用於執行 Sysbench 測試指令。
*   **視窗 B**：用於監控系統資源。

在 **視窗 B** 中執行以下指令，即時觀察 MySQL 容器的 CPU 和記憶體使用量：
```bash
docker stats mysql80_fsync_check mysql84_odirect_check
```

### 2. 進入 Sysbench 容器 (在視窗 A)

```bash
docker exec -it sysbench_runner bash
```

---

### 3. 測試 MySQL 8.0 (fsync)

**步驟 A: 準備資料 (Prepare)**
```bash
sysbench oltp_write_only \
  --mysql-host=mysql80 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=root \
  --mysql-db=sys \
  --tables=10 \
  --table-size=100000 \
  --threads=8 \
  prepare
```

**步驟 B: 執行大量寫入測試 (Run)**
*執行時請觀察視窗 B 的 CPU 使用率變化*
```bash
sysbench oltp_write_only \
  --mysql-host=mysql80 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=root \
  --mysql-db=sys \
  --tables=10 \
  --table-size=100000 \
  --threads=16 \
  --time=60 \
  --report-interval=2 \
  run
```

**步驟 C: 清理資料 (Cleanup)**
```bash
sysbench oltp_write_only \
  --mysql-host=mysql80 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=root \
  --mysql-db=sys \
  --tables=10 \
  --table-size=100000 \
  cleanup
```

---

### 4. 測試 MySQL 8.4 (O_DIRECT)

**步驟 A: 準備資料 (Prepare)**
```bash
sysbench oltp_write_only \
  --mysql-host=mysql84 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=root \
  --mysql-db=sys \
  --tables=10 \
  --table-size=100000 \
  --threads=8 \
  prepare
```

**步驟 B: 執行大量寫入測試 (Run)**
*執行時請觀察視窗 B 的 CPU 使用率變化*
```bash
sysbench oltp_write_only \
  --mysql-host=mysql84 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=root \
  --mysql-db=sys \
  --tables=10 \
  --table-size=100000 \
  --threads=16 \
  --time=60 \
  --report-interval=2 \
  run
```

**步驟 C: 清理資料 (Cleanup)**
```bash
sysbench oltp_write_only \
  --mysql-host=mysql84 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=root \
  --mysql-db=sys \
  --tables=10 \
  --table-size=100000 \
  cleanup
```

## 清理環境

停止並移除所有容器：
```bash
docker-compose down
```

## 結果 (MAC M3 使用 Colima 且 mount_type=virtiofs)

筆者使用 MAC M3 虛擬機為 Colima mount_type=virtiofs **觀察不出兩者的差異** (或許可以加大資料量及增加測試時長🤔)
但關於 fsync vs o_direct 的差異可以參考官方文件 [Optimizing InnoDB Disk I/O](https://dev.mysql.com/doc/refman/8.4/en/optimizing-innodb-diskio.html)

