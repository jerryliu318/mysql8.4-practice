# MySQL 8.4: fsync vs O_DIRECT 寫入效能測試

此目錄用於在 MySQL 8.4 環境下比較 `fsync` 與 `O_DIRECT` 的寫入效能差異。

為了讓差異更明顯，我們將：
1. **資料量提升至 500萬筆 (10 tables * 50w)**：確保總資料量（約 1GB+）大於預設的 Buffer Pool (128MB)，強迫產生實際的磁碟 I/O。

我們提供了一個自動化腳本來執行測試。

## 測試流程

測試分為兩個階段，你需要手動修改 `docker-compose.yml` 來切換 MySQL 的設定。

### 階段一：測試 O_DIRECT (預設)

1. **確認設定**
   打開 `docker-compose.yml`，確認 `mysql84` 服務的 command 設定為：
   ```yaml
   command: --innodb-flush-method=O_DIRECT
   ```

2. **啟動環境**
   ```bash
   docker-compose up -d --build
   ```

3. **執行測試腳本**
   直接執行以下指令。腳本開始後會**先印出當前的 `innodb_flush_method` 設定**，接著自動準備資料、執行測試並清理。
   ```bash
   docker exec -it sysbench_runner /tests/run_tests.sh
   ```

### 階段二：測試 fsync

1. **修改設定**
   編輯 `docker-compose.yml`，註解掉 O_DIRECT 並啟用 fsync：
   ```yaml
   command: --innodb-flush-method=fsync
   # command: --innodb-flush-method=O_DIRECT
   ```

2. **重啟環境**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

3. **執行測試腳本**
   再次執行測試指令：
   ```bash
   docker exec -it sysbench_runner /tests/run_tests.sh
   ```

## 比較結果

完成兩次測試後，比對兩次輸出的 "測試摘要" (TPS, 95% Latency)。

## 監控資源 (可選)

在測試執行期間，可於另一個視窗監控資源：
```bash
docker stats mysql84_test
```

## 清理環境

```bash
docker-compose down
```
