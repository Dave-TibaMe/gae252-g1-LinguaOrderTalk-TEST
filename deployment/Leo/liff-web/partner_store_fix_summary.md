# 合作店家標題覆蓋問題修復總結

## 問題描述

當店家是合作店家但無菜單時，會出現以下不一致的畫面：
- 第二張卡片：顯示 "Partner Store" 徽章（正確）
- 第三張卡片：顯示 "Non-Partner Store" 標題（錯誤）

## 問題分析

### 根本原因
語言刷新機制覆蓋了正確設定的標題文案。

### 關鍵流程
1. `checkStorePartnerStatus()` 判定為**合作店家但無菜單**時，呼叫 `showNonPartnerInterface(storeName, true)`
2. `showNonPartnerInterface()` 正確設定上傳區塊標題為「合作店家（無菜單）」
3. 但在 `initializeParameters()` 裡，**最後才呼叫** `updateInterfaceLanguage()`
4. `updateInterfaceLanguage()` **不分情形**地把上傳區塊文字重設成「Non-Partner Store」
5. 結果：第 1 步設定的正確文案被第 4 步覆蓋

## 解決方案

採用**方案 B：加狀態旗標避免覆蓋**

### 修改內容

#### 1. 修改 `showNonPartnerInterface()` 函數
```javascript
function showNonPartnerInterface(storeName = '', isPartnerStore = false) {
    const ocrSection = document.getElementById('ocr-section');
    ocrSection.classList.remove('hidden');
    
    // 設定模式旗標，避免被 updateInterfaceLanguage 覆蓋
    ocrSection.dataset.mode = isPartnerStore ? 'partner-no-menu' : 'non-partner';
    
    // ... 其他邏輯保持不變
}
```

#### 2. 修改 `updateInterfaceLanguage()` 函數
```javascript
function updateInterfaceLanguage() {
    // ... 其他更新邏輯
    
    // 更新 OCR 介面（根據模式決定是否覆蓋）
    const ocrSection = document.getElementById('ocr-section');
    if (ocrSection && ocrSection.dataset.mode !== 'partner-no-menu') {
        // 只有在非合作店家無菜單模式時才覆蓋標題和描述
        document.getElementById('ocr-title').textContent = texts.ocrTitle;
        document.getElementById('ocr-description').textContent = texts.ocrDescription;
    }
    
    // ... 其他更新邏輯
}
```

### 修復原理

1. **狀態追蹤**：使用 `data-mode` 屬性追蹤 OCR 區塊的當前模式
2. **條件更新**：`updateInterfaceLanguage()` 只在非合作店家無菜單模式時才覆蓋標題
3. **保護機制**：合作店家無菜單模式的標題不會被語言更新覆蓋

## 測試驗證

創建了 `test_partner_store_fix.html` 測試檔案，可驗證：
- 合作店家無菜單模式設定
- 非合作店家模式設定  
- 語言切換時的正確行為

## 預期結果

修復後，當店家是合作店家但無菜單時：
- 第二張卡片：顯示 "Partner Store" 徽章 ✅
- 第三張卡片：顯示 "Partner Store (No Menu)" 標題 ✅

不再出現標題不一致的問題。

## 優點

- **安全性高**：不影響其他正常流程
- **維護性好**：邏輯清晰，易於理解和維護
- **擴展性強**：未來可輕鬆添加其他模式
- **向後相容**：不破壞現有功能
