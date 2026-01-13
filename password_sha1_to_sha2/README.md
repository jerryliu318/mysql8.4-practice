# MySQL 8.0 到 8.4 升級示範 password sha1 to sha2 (Docker)

本示範將帶您經歷從 MySQL 8.0 升級到 8.4 的過程，特別專注於處理 `mysql_native_password` 驗證插件的變更。

---

## ⚠️ 如何完全重置環境 (重新開始)

如果您想從頭開始測試，請清理所有容器、資料卷與映像檔

**注意**：務必確認 `docker-compose.yml` 已改回 `image: mysql:8.0` 且註解掉 `command`。

---

## 檔案結構

*   `docker-compose.yml`: 定義 MySQL 伺服器與測試用的 Client。
*   `init.sql`: 資料庫初始化腳本，會建立以下兩個使用者來模擬不同時期的應用程式：
    *   `user_sha1`: 模擬舊版 Legacy App (使用 `mysql_native_password` / SHA1)。
    *   `user_sha2`: 模擬新版 Modern App (使用 `caching_sha2_password` / SHA2)。
*   `check_clients.py`: Python 腳本，用來測試上述兩個使用者是否能成功連線。

---

## 步驟 1: 啟動 MySQL 8.0 環境

首先，我們啟動 8.0 環境並確認一切正常。

1.  在終端機進入此目錄：
    ```bash
    cd password_sha1_to_sha2
    ```

2.  啟動容器：
    ```bash
    docker-compose up --build
    ```

3.  **觀察輸出結果**：
    您應該會看到 `client_tester` 服務輸出類似以下的成功訊息，表示兩個使用者都能正常連線：
    ```text
    client_tester_1  | ✅ SUCCESS: Connected to MySQL Server version 8.0.x
    ...
    client_tester_1  | 🎉 All checks PASSED! Both legacy and modern clients can connect.
    ```

4.  測試完成後，按 `Ctrl+C` 停止容器，並移除容器（但保留 Volume 資料以模擬升級）：
    ```bash
    docker-compose down
    ```

---

## 步驟 2: 嘗試直接升級到 8.4 (預期失敗)

MySQL 8.4 預設不再啟用 `mysql_native_password`，這會導致舊版應用程式連線失敗。我們來模擬這個情況。

1.  修改 `docker-compose.yml`：
    將 image 版本從 `mysql:8.0` 改為 `mysql:8.4`。
    ```yaml
    services:
      mysql_server:
        image: mysql:8.4  # <--- 修改這裡
        ...
    ```

2.  重新啟動容器：
    ```bash
    docker-compose up --build
    ```

3.  **觀察錯誤**：
    這次 `client_tester` 應該會報錯，指出 `SHA1` 無法連線，但是 `SHA2` 連線成功：
    ```text
    client_tester_1  | ❌ FAILED: Error while connecting: ... Access denied for user 'user_native' ...
    client_tester_1  | ⚠️  PARTIAL: Only Modern client connected.
    ```
    這證明了直接升級會破壞依賴舊驗證方式的服務。

4.  再次停止容器：
    ```bash
    docker-compose down
    ```

---

## 步驟 3: 正確的升級方式 (開啟過渡期相容模式)

為了讓舊 Client 在升級後繼續運作，我們需要顯式開啟 `mysql_native_password` 支援。

1.  修改 `docker-compose.yml`，在 `mysql_server` 服務下新增 `command`：

    ```yaml
    services:
      mysql_server:
        image: mysql:8.4
        # 新增下面這行指令
        command: --mysql-native-password=ON
        ...
    ```

2.  重新啟動容器：
    ```bash
    docker-compose up --build
    ```

3.  **驗證修復**：
    現在，即使是 MySQL 8.4，`user_native` 也應該能成功連線了！
    ```text
    client_tester_1  | ✅ SUCCESS: Connected to MySQL Server version 8.4.x
    ...
    client_tester_1  | 🎉 All checks PASSED! Both legacy and modern clients can connect.
    ```

---

## 步驟 4: 完成遷移 (移除對 Native Password 的依賴)

最終目標是讓所有使用者都使用更安全的 `caching_sha2_password`。假設舊應用程式已經更新了驅動程式，我們可以更新資料庫使用者的設定。

1.  保持容器執行中，開啟一個新的終端機視窗。

2.  進入 MySQL 容器：
    ```bash
    docker-compose up --build
    ```

3. 連線到 MySLQ 容器：
    ```bash
    docker exec -it mysql_demo_server mysql -u root -proot_password
    ```

4.  執行 SQL 指令查看當前狀態並升級使用者：
    ```sql
    -- 1. 查看目前的驗證插件 (應該是 mysql_native_password)
    SELECT user, host, plugin FROM mysql.user WHERE user LIKE 'user_%';

    -- 2. 修改使用者驗證方式
    ALTER USER 'user_sha1'@'%' IDENTIFIED WITH caching_sha2_password BY 'password_sha1';
    FLUSH PRIVILEGES;

    -- 3. 再次查看 (user_sha1 應該變成了 caching_sha2_password)
    SELECT user, host, plugin FROM mysql.user WHERE user LIKE 'user_%';
    
    EXIT;
    ```

5.  移除 `docker-compose.yml` 中的 `command: --mysql-native-password=ON` 並重啟，確認系統現在完全符合 8.4 的預設安全標準且能正常運作。
