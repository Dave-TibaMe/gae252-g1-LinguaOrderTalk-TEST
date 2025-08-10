# 後端修復建議 - 解決 500 錯誤

## 問題根源
根據日誌分析，錯誤發生在 `routes.py` 第 355 行的 `db.session.commit()`，具體錯誤是：
```
pymysql.err.OperationalError: (1364, "Field 'user_id' doesn't have a default value")
```

## 解決方案

### 方案一：修改資料庫模型（推薦）

#### 1. 修改 User 模型
在 `models.py` 中修改 User 類別：

```python
class User(db.Model):
    __tablename__ = 'users'
    
    # 將 user_id 改為自動遞增主鍵
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    line_user_id = db.Column(db.String(64), unique=True, nullable=False)
    preferred_lang = db.Column(db.String(8), default='zh-TW')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # 移除原本的 user_id 欄位，或將其設為可選
    # user_id = db.Column(db.String(64), nullable=True)  # 如果需要的話
```

#### 2. 修改 Order 模型
確保 Order 模型正確引用 User：

```python
class Order(db.Model):
    __tablename__ = 'orders'
    
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    store_id = db.Column(db.String(64), nullable=False)
    items = db.Column(db.Text, nullable=False)  # JSON 格式
    total_amount = db.Column(db.Numeric(10, 2), nullable=False)
    status = db.Column(db.String(20), default='pending')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # 關聯到 User
    user = db.relationship('User', backref='orders')
```

#### 3. 修改 create_order 函數
在 `routes.py` 中修改 `create_order` 函數：

```python
@app.route('/api/orders', methods=['POST'])
def create_order():
    try:
        data = request.get_json()
        
        # 驗證必要欄位
        if not data.get('line_user_id'):
            return jsonify({'error': '缺少 line_user_id'}), 400
        if not data.get('store_id'):
            return jsonify({'error': '缺少 store_id'}), 400
        if not data.get('items'):
            return jsonify({'error': '缺少 items'}), 400
            
        line_user_id = data['line_user_id']
        store_id = data['store_id']
        items = data['items']
        total_amount = data.get('total', 0)
        
        # 1. 取得或創建用戶
        user = User.query.filter_by(line_user_id=line_user_id).first()
        if not user:
            user = User(
                line_user_id=line_user_id,
                preferred_lang=data.get('language', 'zh-TW')
            )
            db.session.add(user)
            db.session.flush()  # 產生 user.id
        
        # 2. 創建訂單
        order = Order(
            user_id=user.id,  # 使用 user.id 而不是 user_id
            store_id=store_id,
            items=json.dumps(items),
            total_amount=total_amount
        )
        db.session.add(order)
        db.session.commit()
        
        # 3. 回傳成功回應
        return jsonify({
            'order_id': order.id,
            'user_id': user.id,
            'message': '訂單創建成功'
        }), 201
        
    except Exception as e:
        db.session.rollback()
        print(f"創建訂單時發生錯誤: {str(e)}")
        return jsonify({'error': '伺服器內部錯誤'}), 500
```

### 方案二：資料庫遷移（如果無法修改模型）

如果無法修改模型，可以執行以下 SQL 來修改資料庫：

```sql
-- 為 user_id 欄位添加預設值
ALTER TABLE users MODIFY COLUMN user_id VARCHAR(64) DEFAULT NULL;

-- 或者，如果 user_id 是主鍵，可以改為自動遞增
ALTER TABLE users MODIFY COLUMN user_id INT AUTO_INCREMENT PRIMARY KEY;
```

### 方案三：臨時修復（快速解決）

在 `create_order` 函數中添加 user_id 處理：

```python
@app.route('/api/orders', methods=['POST'])
def create_order():
    try:
        data = request.get_json()
        line_user_id = data.get('line_user_id')
        
        # 查找或創建用戶
        user = User.query.filter_by(line_user_id=line_user_id).first()
        if not user:
            # 創建新用戶時同時設定 user_id
            user = User(
                line_user_id=line_user_id,
                user_id=line_user_id,  # 使用 line_user_id 作為 user_id
                preferred_lang=data.get('language', 'zh-TW')
            )
            db.session.add(user)
            db.session.flush()
        
        # 其餘邏輯保持不變...
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': '伺服器內部錯誤'}), 500
```

## 測試建議

1. **本地測試**：
   ```bash
   # 測試訂單創建
   curl -X POST http://localhost:5000/api/orders \
     -H "Content-Type: application/json" \
     -d '{
       "line_user_id": "test_user_123",
       "store_id": "test_store",
       "items": [{"menu_item_id": 1, "qty": 2}],
       "total": 100
     }'
   ```

2. **部署前檢查**：
   - 確保資料庫連接正常
   - 檢查所有必要的欄位都有預設值
   - 驗證外鍵關係正確

## 預防措施

1. **添加資料庫約束檢查**：
   ```python
   # 在模型定義中添加約束
   __table_args__ = (
       db.CheckConstraint('user_id IS NOT NULL', name='user_id_not_null'),
   )
   ```

2. **添加日誌記錄**：
   ```python
   import logging
   logger = logging.getLogger(__name__)
   
   # 在關鍵操作處添加日誌
   logger.info(f"創建訂單: user_id={user.id}, store_id={store_id}")
   ```

3. **添加錯誤處理**：
   ```python
   try:
       db.session.commit()
   except Exception as e:
       logger.error(f"資料庫操作失敗: {str(e)}")
       db.session.rollback()
       raise
   ```

## 部署步驟

1. **備份資料庫**
2. **執行資料庫遷移**（如果使用方案一）
3. **部署新代碼**
4. **測試訂單創建功能**
5. **監控錯誤日誌**

選擇方案一（修改模型）是最乾淨的解決方案，建議優先採用。 