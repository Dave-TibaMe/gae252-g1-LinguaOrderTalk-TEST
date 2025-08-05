SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;


CREATE TABLE `languages` (
  `lang_code` varchar(5) COLLATE utf8mb4_bin NOT NULL COMMENT '語言代碼，如 en, zh, jp',
  `lang_name` varchar(50) COLLATE utf8mb4_bin NOT NULL COMMENT '語言名稱，如英文、中文、日文'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='語言代碼表';

CREATE TABLE `menus` (
  `menu_id` bigint(20) NOT NULL COMMENT '菜單 ID',
  `store_id` int(11) NOT NULL COMMENT '對應店家 ID',
  `template_id` int(11) DEFAULT NULL COMMENT '對應模板 ID（VIP店家選用）',
  `version` int(11) NOT NULL DEFAULT '1' COMMENT '菜單版本號',
  `effective_date` datetime NOT NULL COMMENT '菜單生效日期',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='菜單主檔，版本控管';

CREATE TABLE `menu_crawls` (
  `crawl_id` bigint(20) NOT NULL COMMENT '菜單爬蟲紀錄 ID',
  `store_id` int(11) NOT NULL COMMENT '店家 ID',
  `crawl_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '爬取時間',
  `menu_version` int(11) DEFAULT NULL COMMENT '菜單版本號',
  `menu_version_hash` varchar(64) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '菜單版本雜湊值',
  `has_update` tinyint(1) DEFAULT '0' COMMENT '是否有更新',
  `store_reviews_popular` json DEFAULT NULL COMMENT '店家評論及人氣菜色 JSON'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='定時爬蟲合作店家菜單版本紀錄';

CREATE TABLE `menu_items` (
  `menu_item_id` bigint(20) NOT NULL COMMENT '菜單品項 ID',
  `menu_id` bigint(20) NOT NULL COMMENT '對應菜單 ID',
  `item_name` varchar(100) COLLATE utf8mb4_bin NOT NULL COMMENT '品項名稱',
  `price_big` int(11) DEFAULT NULL COMMENT '大份量價格',
  `price_small` int(11) NOT NULL COMMENT '小份量價格',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='菜單品項明細';

CREATE TABLE `menu_templates` (
  `template_id` int(11) NOT NULL COMMENT '菜單模板 ID',
  `template_name` varchar(100) COLLATE utf8mb4_bin NOT NULL COMMENT '模板名稱',
  `description` text COLLATE utf8mb4_bin COMMENT '模板說明'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='VIP 店家菜單模板';

CREATE TABLE `menu_translations` (
  `menu_translation_id` bigint(20) NOT NULL COMMENT '菜單多語言描述 ID',
  `menu_item_id` bigint(20) NOT NULL COMMENT '菜單品項 ID',
  `lang_code` varchar(5) COLLATE utf8mb4_bin NOT NULL COMMENT '語言代碼',
  `description` text COLLATE utf8mb4_bin COMMENT '品項介紹'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='菜單品項多語言介紹';

CREATE TABLE `ocr_menus` (
  `ocr_menu_id` bigint(20) NOT NULL COMMENT 'OCR 菜單 ID',
  `user_id` bigint(20) NOT NULL COMMENT '上傳者使用者 ID',
  `store_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '非合作店家名稱',
  `upload_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '上傳時間'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='非合作店家用戶OCR菜單主檔';

CREATE TABLE `ocr_menu_items` (
  `ocr_menu_item_id` bigint(20) NOT NULL COMMENT 'OCR 菜單品項 ID',
  `ocr_menu_id` bigint(20) NOT NULL COMMENT 'OCR 菜單 ID',
  `item_name` varchar(100) COLLATE utf8mb4_bin NOT NULL COMMENT '品項名稱',
  `price_big` int(11) DEFAULT NULL COMMENT '大份量價格',
  `price_small` int(11) NOT NULL COMMENT '小份量價格',
  `translated_desc` text COLLATE utf8mb4_bin COMMENT '翻譯後介紹'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='OCR菜單品項明細';

CREATE TABLE `orders` (
  `order_id` bigint(20) NOT NULL COMMENT '訂單 ID',
  `user_id` bigint(20) NOT NULL COMMENT '下單使用者 ID',
  `store_id` int(11) NOT NULL COMMENT '點餐店家 ID',
  `order_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '下單時間',
  `language_used` varchar(5) COLLATE utf8mb4_bin DEFAULT 'zh' COMMENT '系統使用的語言代碼（預設國語 zh）',
  `total_amount` int(11) NOT NULL DEFAULT '0' COMMENT '訂單總金額'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='訂單總表，包含總金額';

CREATE TABLE `order_items` (
  `order_item_id` bigint(20) NOT NULL COMMENT '訂單品項 ID',
  `order_id` bigint(20) NOT NULL COMMENT '所屬訂單 ID',
  `menu_item_id` bigint(20) NOT NULL COMMENT '點選菜單品項 ID',
  `quantity_big` int(11) NOT NULL DEFAULT '0' COMMENT '大份量數量',
  `quantity_small` int(11) NOT NULL DEFAULT '0' COMMENT '小份量數量',
  `price_big` int(11) DEFAULT NULL COMMENT '大份量價格',
  `price_small` int(11) NOT NULL COMMENT '小份量價格',
  `subtotal` int(11) NOT NULL COMMENT '該品項小計（大份量數量乘大份量價格 + 小份量數量乘小份量價格）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='訂單品項明細，包含數量、價格及小計';

CREATE TABLE `stores` (
  `store_id` int(11) NOT NULL COMMENT '店家 ID',
  `store_name` varchar(100) COLLATE utf8mb4_bin NOT NULL COMMENT '店家名稱',
  `partner_level` tinyint(4) NOT NULL DEFAULT '0' COMMENT '合作等級：0=非合作，1=合作，2=VIP',
  `gps_lat` double DEFAULT NULL COMMENT '店家 GPS 緯度',
  `gps_lng` double DEFAULT NULL COMMENT '店家 GPS 經度',
  `place_id` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Google Map Place ID',
  `review_summary` text COLLATE utf8mb4_bin COMMENT '店家評論摘要',
  `top_dish_1` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '人氣菜色 1',
  `top_dish_2` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '人氣菜色 2',
  `top_dish_3` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '人氣菜色 3',
  `top_dish_4` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '人氣菜色 4',
  `top_dish_5` varchar(100) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '人氣菜色 5',
  `main_photo_url` varchar(255) COLLATE utf8mb4_bin DEFAULT NULL COMMENT '店家招牌照片 URL',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='店家資料表';

CREATE TABLE `store_translations` (
  `store_translation_id` int(11) NOT NULL COMMENT '店家多語言描述 ID',
  `store_id` int(11) NOT NULL COMMENT '對應店家 ID',
  `lang_code` varchar(5) COLLATE utf8mb4_bin NOT NULL COMMENT '語言代碼',
  `description` text COLLATE utf8mb4_bin COMMENT '店家介紹文',
  `reviews` text COLLATE utf8mb4_bin COMMENT '店家評論'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='店家多語言介紹與評論表';

CREATE TABLE `users` (
  `user_id` bigint(20) NOT NULL COMMENT '使用者 ID',
  `line_user_id` varchar(100) COLLATE utf8mb4_bin NOT NULL COMMENT 'LINE 使用者唯一識別 ID',
  `preferred_lang` varchar(5) COLLATE utf8mb4_bin NOT NULL COMMENT '使用者偏好語言代碼',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='使用者資料表，含 LINE UserID 與偏好語言';

CREATE TABLE `user_actions` (
  `action_id` bigint(20) NOT NULL COMMENT '使用者行為紀錄 ID',
  `user_id` bigint(20) NOT NULL COMMENT '使用者 ID',
  `action_type` varchar(50) COLLATE utf8mb4_bin NOT NULL COMMENT '行為類型，如點餐、播放語音、語速調整等',
  `action_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '行為發生時間',
  `details` json DEFAULT NULL COMMENT '行為細節，JSON 格式'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='使用者操作行為紀錄表，用於行為分析與優化';

-- 建立reviews表 added by Davis
CREATE TABLE `reviews` (
  `review_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '評論 ID',
  `store_id` int(11) NOT NULL COMMENT '對應店家 ID',
  `place_id` varchar(100) COLLATE utf8mb4_bin NOT NULL COMMENT 'Google Place ID',
  `review_data` json NOT NULL COMMENT 'Google評論完整JSON資料',
  `review_time` datetime NOT NULL COMMENT '評論時間',
  `rating` int(1) DEFAULT NULL COMMENT '評分 1-5',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '資料建立時間',
  PRIMARY KEY (`review_id`),
  KEY `idx_store_id` (`store_id`),
  KEY `idx_place_id` (`place_id`),
  KEY `idx_review_time` (`review_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='Google評論資料表';

-- 建立crawl_logs表 added by Davis
CREATE TABLE `crawl_logs` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '日誌 ID',
  `store_id` int(11) NOT NULL COMMENT '對應店家 ID',
  `last_crawl_time` datetime NOT NULL COMMENT '最後抓取時間',
  `reviews_count` int(11) DEFAULT 0 COMMENT '本次抓取評論數量',
  `status` varchar(20) DEFAULT 'success' COMMENT '抓取狀態',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間',
  PRIMARY KEY (`log_id`),
  UNIQUE KEY `uk_store_id` (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='爬蟲抓取日誌表';

ALTER TABLE `languages`
  ADD PRIMARY KEY (`lang_code`);

ALTER TABLE `menus`
  ADD PRIMARY KEY (`menu_id`),
  ADD KEY `store_id` (`store_id`),
  ADD KEY `template_id` (`template_id`);

ALTER TABLE `menu_crawls`
  ADD PRIMARY KEY (`crawl_id`),
  ADD KEY `store_id` (`store_id`);

ALTER TABLE `menu_items`
  ADD PRIMARY KEY (`menu_item_id`),
  ADD KEY `menu_id` (`menu_id`);

ALTER TABLE `menu_templates`
  ADD PRIMARY KEY (`template_id`);

ALTER TABLE `menu_translations`
  ADD PRIMARY KEY (`menu_translation_id`),
  ADD UNIQUE KEY `menu_item_id` (`menu_item_id`,`lang_code`),
  ADD KEY `lang_code` (`lang_code`);

ALTER TABLE `ocr_menus`
  ADD PRIMARY KEY (`ocr_menu_id`),
  ADD KEY `user_id` (`user_id`);

ALTER TABLE `ocr_menu_items`
  ADD PRIMARY KEY (`ocr_menu_item_id`),
  ADD KEY `ocr_menu_id` (`ocr_menu_id`);

ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `store_id` (`store_id`),
  ADD KEY `language_used` (`language_used`);

ALTER TABLE `order_items`
  ADD PRIMARY KEY (`order_item_id`),
  ADD KEY `order_id` (`order_id`),
  ADD KEY `menu_item_id` (`menu_item_id`);

ALTER TABLE `stores`
  ADD PRIMARY KEY (`store_id`);

ALTER TABLE `store_translations`
  ADD PRIMARY KEY (`store_translation_id`),
  ADD UNIQUE KEY `store_id` (`store_id`,`lang_code`),
  ADD KEY `lang_code` (`lang_code`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `line_user_id` (`line_user_id`),
  ADD KEY `preferred_lang` (`preferred_lang`);

ALTER TABLE `user_actions`
  ADD PRIMARY KEY (`action_id`),
  ADD KEY `user_id` (`user_id`);


ALTER TABLE `menus`
  MODIFY `menu_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '菜單 ID';

ALTER TABLE `menu_crawls`
  MODIFY `crawl_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '菜單爬蟲紀錄 ID';

ALTER TABLE `menu_items`
  MODIFY `menu_item_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '菜單品項 ID';

ALTER TABLE `menu_templates`
  MODIFY `template_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '菜單模板 ID';

ALTER TABLE `menu_translations`
  MODIFY `menu_translation_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '菜單多語言描述 ID';

ALTER TABLE `ocr_menus`
  MODIFY `ocr_menu_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'OCR 菜單 ID';

ALTER TABLE `ocr_menu_items`
  MODIFY `ocr_menu_item_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'OCR 菜單品項 ID';

ALTER TABLE `orders`
  MODIFY `order_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '訂單 ID';

ALTER TABLE `order_items`
  MODIFY `order_item_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '訂單品項 ID';

ALTER TABLE `stores`
  MODIFY `store_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '店家 ID';

ALTER TABLE `store_translations`
  MODIFY `store_translation_id` int(11) NOT NULL AUTO_INCREMENT COMMENT '店家多語言描述 ID';

ALTER TABLE `user_actions`
  MODIFY `action_id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '使用者行為紀錄 ID';


ALTER TABLE `menus`
  ADD CONSTRAINT `menus_ibfk_1` FOREIGN KEY (`store_id`) REFERENCES `stores` (`store_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `menus_ibfk_2` FOREIGN KEY (`template_id`) REFERENCES `menu_templates` (`template_id`);

ALTER TABLE `menu_crawls`
  ADD CONSTRAINT `menu_crawls_ibfk_1` FOREIGN KEY (`store_id`) REFERENCES `stores` (`store_id`);

ALTER TABLE `menu_items`
  ADD CONSTRAINT `menu_items_ibfk_1` FOREIGN KEY (`menu_id`) REFERENCES `menus` (`menu_id`) ON DELETE CASCADE;

ALTER TABLE `menu_translations`
  ADD CONSTRAINT `menu_translations_ibfk_1` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`menu_item_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `menu_translations_ibfk_2` FOREIGN KEY (`lang_code`) REFERENCES `languages` (`lang_code`);

ALTER TABLE `ocr_menus`
  ADD CONSTRAINT `ocr_menus_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);

ALTER TABLE `ocr_menu_items`
  ADD CONSTRAINT `ocr_menu_items_ibfk_1` FOREIGN KEY (`ocr_menu_id`) REFERENCES `ocr_menus` (`ocr_menu_id`) ON DELETE CASCADE;

ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`store_id`) REFERENCES `stores` (`store_id`),
  ADD CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`language_used`) REFERENCES `languages` (`lang_code`);

ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`menu_item_id`);

ALTER TABLE `store_translations`
  ADD CONSTRAINT `store_translations_ibfk_1` FOREIGN KEY (`store_id`) REFERENCES `stores` (`store_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `store_translations_ibfk_2` FOREIGN KEY (`lang_code`) REFERENCES `languages` (`lang_code`);

ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`preferred_lang`) REFERENCES `languages` (`lang_code`);

ALTER TABLE `user_actions`
  ADD CONSTRAINT `user_actions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
