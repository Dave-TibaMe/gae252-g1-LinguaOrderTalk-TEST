# 點餐傳聲筒 - LIFF Web App

一個基於 LINE LIFF 的點餐系統，支援多語言介面和 OCR 菜單辨識功能。

## 功能特色

- 🌐 多語言支援（中文、英文、日文、韓文）
- 📸 OCR 菜單辨識（非合作店家）
- 🛒 購物車功能
- 📱 響應式設計
- 🔗 LINE LIFF 整合

## 快速開始

1. 將此專案推送到你的 GitHub 倉庫
2. 在 Azure Static Web Apps 中連接你的 GitHub 倉庫
3. 設定 LIFF ID 在 `index.html` 中
4. 部署完成後即可使用

## 檔案結構

```
liff-web/
├── index.html                    # 主要應用程式
├── .github/workflows/            # GitHub Actions 部署配置
└── README.md                     # 專案說明
```

## 部署

此專案使用 Azure Static Web Apps 進行自動部署。每次推送到 `main` 分支時會自動部署。

## 技術棧

- HTML5
- CSS3 (Tailwind CSS)
- JavaScript (Vanilla)
- LINE LIFF SDK
- Azure Static Web Apps # Updated at 2025年 8月 7日 週四 18時21分03秒 CST
