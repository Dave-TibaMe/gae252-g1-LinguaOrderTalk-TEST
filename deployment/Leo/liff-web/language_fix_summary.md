# 語言設定問題修復總結

## 問題描述
用戶在LINE Bot中成功將語言設定為English，但進入LIFF網頁後仍然顯示中文介面。

## 根本原因分析

### 1. LINE Bot URL參數缺失
**問題位置**: `../linebot/app/main.py` 第472行
```python
# 修復前
uri=f"line://app/{Config.LIFF_ID}?store_id={store_id}&store_name={quote(store_name)}&is_partner={is_partner}"

# 修復後  
uri=f"line://app/{Config.LIFF_ID}?store_id={store_id}&store_name={quote(store_name)}&is_partner={is_partner}&preferred_lang={user_state.get('preferred_lang', 'zh-TW')}"
```

**問題**: LINE Bot生成LIFF URL時沒有包含用戶的語言偏好設定。

### 2. 語言代碼不匹配
**問題**: LINE Bot使用簡短語言代碼（如 `en`），但LIFF網頁使用完整語言代碼（如 `en-US`）。

**修復位置**: `index.html` 的 `initializeParameters` 函數
```javascript
// 語言代碼轉換：將 LINE Bot 的簡短代碼轉換為 LIFF 網頁的完整代碼
const languageCodeMapping = {
    'en': 'en-US',
    'zh-TW': 'zh-TW', 
    'ja': 'ja-JP',
    'ko': 'ko-KR'
};
const normalizedLanguage = languageCodeMapping[language] || language;
```

### 3. HTML初始文字硬編碼
**問題位置**: `index.html` 第49行
```html
<!-- 修復前 -->
<p id="current-language-display" class="text-sm text-gray-600 mb-2">Display Language: <span id="language-name">English</span></p>
<p class="text-xs text-gray-400">Language is set in LINE Bot</p>

<!-- 修復後 -->
<p id="current-language-display" class="text-sm text-gray-600 mb-2">顯示語言：<span id="language-name">中文</span></p>
<p class="text-xs text-gray-400">語言已在 LINE Bot 中設定</p>
```

**問題**: 初始載入時顯示硬編碼的英文文字，即使JavaScript會更新，但會造成閃爍。

## 修復步驟

### 步驟1: 修復LINE Bot URL生成
- 在 `handle_location_message` 函數中添加 `preferred_lang` 參數
- 確保用戶語言偏好被正確傳遞到LIFF網頁

### 步驟2: 添加語言代碼轉換邏輯
- 在LIFF網頁中添加語言代碼映射表
- 將LINE Bot的簡短代碼轉換為LIFF網頁的完整代碼

### 步驟3: 修復HTML初始文字
- 將硬編碼的英文文字改為中文
- 避免初始載入時的語言不一致

### 步驟4: 更新API請求參數
- 確保向後端發送的API請求使用正確的語言代碼

## 測試驗證

創建了 `test_language_fix.html` 來驗證語言代碼轉換邏輯：
- 測試英文 (`en` → `en-US`)
- 測試中文 (`zh-TW` → `zh-TW`) 
- 測試日文 (`ja` → `ja-JP`)
- 測試韓文 (`ko` → `ko-KR`)

## 預期效果

修復後，用戶在LINE Bot中設定語言為English後：
1. LINE Bot會將 `preferred_lang=en` 參數包含在LIFF URL中
2. LIFF網頁會將 `en` 轉換為 `en-US`
3. 整個介面會正確顯示英文
4. 語言顯示會正確顯示 "Display Language: English"

## 新增功能：自動語言偵測

### 功能描述
除了修復原有的語言設定問題外，還新增了自動語言偵測功能，提供更流暢的用戶體驗。

### 語言偵測優先順序
1. **URL參數優先**: 如果URL中有 `preferred_lang` 參數，優先使用
2. **LIFF自動偵測**: 如果沒有URL參數，自動偵測用戶的LINE語言設定
3. **瀏覽器語言備用**: 如果LIFF偵測失敗，使用瀏覽器語言設定
4. **預設值**: 最後使用 `zh-TW` 作為預設值

### 實現代碼
```javascript
// 語言偵測邏輯
let detectedLanguage = preferredLang || urlLang;

// 如果沒有URL參數，嘗試自動偵測LINE語言
if (!detectedLanguage && liffInitialized) {
    try {
        const liffLanguage = liff.getLanguage();
        console.log('LIFF自動偵測語言:', liffLanguage);
        detectedLanguage = liffLanguage;
    } catch (error) {
        console.log('LIFF語言偵測失敗，使用瀏覽器語言');
        detectedLanguage = navigator.language || 'zh-TW';
    }
}

// 語言代碼轉換
const languageCodeMapping = {
    'en': 'en-US',
    'zh-TW': 'zh-TW', 
    'ja': 'ja-JP',
    'ko': 'ko-KR',
    'zh': 'zh-TW',  // 支援簡體中文轉繁體
    'en-US': 'en-US',
    'ja-JP': 'ja-JP',
    'ko-KR': 'ko-KR'
};
```

### 使用情境
1. **用戶在LINE Bot中設定語言**: 會通過URL參數傳遞，優先使用
2. **用戶直接進入LIFF網頁**: 會自動偵測用戶的LINE語言設定
3. **非LINE環境**: 會使用瀏覽器語言設定
4. **所有情況都失敗**: 使用中文作為預設值

### 測試檔案
- `test_auto_language_detection.html`: 測試自動語言偵測功能
- 包含多種測試情境，驗證語言偵測的優先順序

## 語言參數傳遞修復

### 問題描述
前端傳遞的語言代碼（如 `en-US`）與後端期望的語言代碼（如 `en`）不匹配，導致菜單無法正確顯示用戶語言。

### 修復內容

#### 1. 前端語言代碼轉換
在 `index.html` 中添加語言代碼轉換邏輯：
```javascript
// 語言代碼轉換：將完整代碼轉換為後端期望的簡短代碼
const backendLanguageMapping = {
    'en-US': 'en',
    'zh-TW': 'zh',
    'ja-JP': 'ja',
    'ko-KR': 'ko'
};
const backendLanguage = backendLanguageMapping[language] || language;
```

#### 2. API端點修復
- 合作店家菜單API: `/api/menu/{store_id}?lang={language}`
- OCR上傳API: `/api/upload-menu-image` (POST with lang parameter)

#### 3. 語言代碼對應關係
| 前端代碼 | 後端代碼 | 說明 |
|---------|---------|------|
| en-US | en | 英文 |
| zh-TW | zh | 中文 |
| ja-JP | ja | 日文 |
| ko-KR | ko | 韓文 |

### 測試檔案
- `test_language_api_integration.html`: 測試前端到後端的語言參數傳遞
- 驗證語言代碼轉換和API調用的正確性

## 部署注意事項

1. 需要重新部署LINE Bot服務
2. 需要重新部署LIFF網頁
3. 建議在部署前先在測試環境驗證修復效果
4. 測試自動語言偵測功能在不同環境下的表現
5. 驗證菜單API的語言參數傳遞是否正確
