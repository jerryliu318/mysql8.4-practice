# MySQL 窗口函數 (Window Function) 練習環境

這個目錄包含了一個預先配置好的 MySQL 8.4 環境，內含 **1000 筆** 隨機生成的電商銷售數據 (分佈於 10 位用戶與 2026/01/01 - 2026/02/01 之間)，專供練習 Window Functions 使用。

## 資料表結構

資料表名稱: `order_items`

| 欄位名稱 | 類型 | 說明 |
| :--- | :--- | :--- |
| `id` | INT | 主鍵 |
| `user_id` | INT | 用戶 ID |
| `category` | VARCHAR | 商品類別 (Electronics, Clothing, Books, Home) |
| `item_name` | VARCHAR | 商品名稱 |
| `price` | DECIMAL | 商品價格 |
| `pay_date` | DATETIME | 購買日期與時間 |

## 快速開始

1. **啟動資料庫**
   ```bash
   docker-compose up -d
   ```

2. **進入 MySQL console**
   ```bash
   docker exec -it mysql_window_practice mysql -uroot -proot shop
   ```

3. **直接執行 SQL 檔案**
   如果您有寫好的 `.sql` 檔案（例如 `top3_no_window.sql`），可以使用以下指令直接執行並查看結果：
   ```bash
   docker exec -i mysql_window_practice mysql -uroot -proot shop < top3_no_window.sql
   ```

4. **開始練習**
   您可以嘗試執行如下查詢：

   *   **計算每個用戶的累積消費金額**：
       ```sql
       SELECT user_id, pay_date, price,
              SUM(price) OVER (PARTITION BY user_id ORDER BY pay_date) as cumulative_spend
       FROM order_items;
       ```

   *   **計算用戶平均購買間隔 (天)**：
       ```sql
       -- 使用 LEAD (下一筆)
       SELECT user_id,
              AVG(TIMESTAMPDIFF(HOUR, pay_date, next_pay)) / 24.0 as avg_days
       FROM (
           SELECT user_id, pay_date,
                  LEAD(pay_date) OVER (PARTITION BY user_id ORDER BY pay_date) as next_pay
           FROM order_items
       ) t
       GROUP BY user_id;
       ```

   *   **計算同類別商品的價格排名**：
       ```sql
       SELECT category, item_name, price,
              RANK() OVER (PARTITION BY category ORDER BY price DESC) as price_rank
       FROM order_items;
       ```

## 清理環境

```bash
docker-compose down
```
