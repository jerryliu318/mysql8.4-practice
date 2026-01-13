# MySQL 8.4 Log Buffer Size 效能測試 (單機手動版)

本目錄提供一個簡化的環境，讓您可以手動調整 `innodb_log_buffer_size` 並重複執行基準測試，專注於觀測「大事務」下的效能表現。

## 執行流程

### 1. 啟動資料庫 (預設 16M)
```bash
docker-compose up -d --build
```

### 2. 執行第一次測試
```bash
docker-compose exec sysbench ./run_tests.sh
```
請記錄終端機輸出的 **TPS** 與 **Latency** 數值。

### 3. 修改配置
編輯 `docker-compose.yml`，將 `mysql_server` 的 `command` 改為您想測試的值，例如：
```yaml
command: --innodb_log_buffer_size=64M --mysql-native-password=ON
```

### 4. 重啟資料庫
```bash
docker-compose up -d
```
*(注意：Docker 會偵測到配置變更並自動重啟該容器)*

### 5. 執行第二次測試
```bash
docker-compose exec sysbench ./run_tests.sh
```

### 6. 比較數據
對比兩次輸出的 `TPS` 與 `95% Latency` 數值。

## 測試內容說明
- **大事務測試**：模擬單筆大批量寫入（每筆事務 2000 次索引更新，持續 120 秒），觀察 Log Buffer 空間對 Commit 速度與 I/O 等待的影響。
