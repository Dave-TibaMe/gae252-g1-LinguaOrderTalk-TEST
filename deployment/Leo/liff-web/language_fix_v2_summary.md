# 語言設定問題修復總結 v2

## 問題描述
用戶發現以下文字沒有根據用戶語言設定進行變更：
1. **問候語**："你好 游宗翰(Leo)！"
2. **支援拍照文字**："支援拍照或從相簿選擇"
3. **檔案選擇彈窗**："照片圖庫"、"拍照"、"選擇檔案"、"取消"

## 修復內容

### 1. 問候語修復
**問題位置**: `index.html` 第 580 行
- **修復前**: 問候語在 LIFF 初始化時使用硬編碼的中文
- **修復後**: 
  - 在語言切換函數中添加問候語更新邏輯
  - 自動檢測並更新問候語文字
  - 支援四種語言：中文、英文、日文、韓文

### 2. 支援拍照文字修復
**問題位置**: `index.html` 第 86 行
- **修復前**: 硬編碼的中文文字
- **修復後**: 
  - 添加到翻譯表中
  - 在語言切換時自動更新
  - 支援四種語言

### 3. 檔案選擇對話框自定義
**問題**: 系統原生檔案選擇彈窗無法自定義語言
**解決方案**: 
- 創建自定義檔案選擇對話框
- 完全控制對話框的文字內容
- 支援 iOS 和 Android 兩個平台
- 提供三種選擇方式：相簿、拍照、檔案

## 新增翻譯項目

### 中文 (zh-TW)
```javascript
supportPhotoText: '支援拍照或從相簿選擇',
modalTitle: '選擇照片',
modalDescription: '請選擇您要上傳的菜單照片',
galleryText: '照片圖庫',
cameraText: '拍照',
fileText: '選擇檔案',
cancelText: '取消'
```

### 英文 (en-US)
```javascript
supportPhotoText: 'Support taking photos or selecting from albums',
modalTitle: 'Select Photo',
modalDescription: 'Please select the menu photo you want to upload',
galleryText: 'Photo Gallery',
cameraText: 'Take Photo',
fileText: 'Choose File',
cancelText: 'Cancel'
```

### 日文 (ja-JP)
```javascript
supportPhotoText: '写真撮影またはアルバムからの選択をサポート',
modalTitle: '写真を選択',
modalDescription: 'アップロードするメニュー写真を選択してください',
galleryText: '写真ギャラリー',
cameraText: '写真を撮影',
fileText: 'ファイルを選択',
cancelText: 'キャンセル'
```

### 韓文 (ko-KR)
```javascript
supportPhotoText: '사진 촬영 또는 앨범에서 선택 지원',
modalTitle: '사진 선택',
modalDescription: '업로드할 메뉴 사진을 선택해 주세요',
galleryText: '사진 갤러리',
cameraText: '사진 촬영',
fileText: '파일 선택',
cancelText: '취소'
```

## 技術實現

### 1. 自定義檔案選擇對話框
```html
<!-- 自定義檔案選擇對話框 -->
<div id="file-select-modal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 hidden">
    <div class="bg-white rounded-lg p-6 mx-4 max-w-sm w-full">
        <!-- 對話框內容 -->
    </div>
</div>
```

### 2. 檔案選擇邏輯
```javascript
// 從相簿選擇
galleryBtn.addEventListener('click', () => {
    fileInput.accept = 'image/*';
    fileInput.click();
    fileSelectModal.classList.add('hidden');
});

// 拍照
cameraBtn.addEventListener('click', () => {
    fileInput.accept = 'image/*';
    fileInput.capture = 'environment';
    fileInput.click();
    fileSelectModal.classList.add('hidden');
});

// 選擇檔案
fileBtn.addEventListener('click', () => {
    fileInput.accept = 'image/*';
    fileInput.capture = null;
    fileInput.click();
    fileSelectModal.classList.add('hidden');
});
```

### 3. 語言切換更新邏輯
```javascript
// 更新支援拍照文字
const supportPhotoElement = document.getElementById('support-photo-text');
if (supportPhotoElement) {
    supportPhotoElement.textContent = texts.supportPhotoText;
}

// 更新自定義對話框文字
const modalTitle = document.getElementById('modal-title');
const modalDescription = document.getElementById('modal-description');
// ... 其他元素更新

// 更新問候語
const liffStatus = document.getElementById('liff-status');
if (liffStatus && liffStatus.textContent.includes('你好') || ...) {
    const match = liffStatus.textContent.match(/(你好|Hello|こんにちは|안녕하세요)\s+(.+?)！/);
    if (match && match[2]) {
        const userName = match[2];
        liffStatus.textContent = `${texts.helloUser} ${userName}！`;
    }
}
```

## 測試驗證

創建了 `test_language_fix_v2.html` 來驗證修復效果：
- ✅ 問候語多語言切換
- ✅ 支援拍照文字多語言切換
- ✅ 自定義檔案選擇對話框多語言切換
- ✅ iOS 和 Android 平台兼容性

## 預期效果

修復後，用戶在切換語言時：
1. **問候語**會正確顯示對應語言的問候詞
2. **支援拍照文字**會顯示對應語言的說明
3. **檔案選擇對話框**會顯示對應語言的選項
4. 所有文字都會即時更新，無需重新載入頁面

## 兼容性

- ✅ iOS Safari
- ✅ Android Chrome
- ✅ LINE 內建瀏覽器
- ✅ 桌面瀏覽器（開發測試用）

## 更新時間
2025-01-27 - 完成第二版語言修復
