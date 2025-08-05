import google.generativeai as genai
from utils.logger import setup_logger
import mysql.connector
from mysql.connector import Error

logger = setup_logger('translator')

class ReviewTranslator:
    def __init__(self, config):
        self.api_key = config['api_keys']['REVIEW_GEMINI_API_KEY']
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel('gemini-2.5-pro')
        
        # 資料庫配置
        self.db_config = config
        self.connection = None
        self.cursor = None
        
        # 語言對應表 - 將從資料庫動態載入
        self.language_mapping = {}
        
        # 初始化資料庫連接並載入語言設定
        self._initialize_database()
    
    def _initialize_database(self):
        """初始化資料庫連接並載入語言設定"""
        try:
            self.connection = mysql.connector.connect(
                host=self.db_config['mysql']['host'],
                database=self.db_config['mysql']['database'],
                user=self.db_config['mysql']['user'],
                password=self.db_config['mysql']['password'],
                port=int(self.db_config['mysql']['port']),
                charset='utf8mb4',
                collation='utf8mb4_unicode_ci'
            )
            
            if self.connection.is_connected():
                self.cursor = self.connection.cursor(dictionary=True)
                logger.info("翻譯器資料庫連接成功")
                
                # 載入語言設定
                self._load_languages()
                
        except Error as e:
            logger.error(f"翻譯器資料庫連接失敗: {e}")
            raise
    
    def _load_languages(self):
        """從資料庫載入語言設定"""
        try:
            query = "SELECT lang_code, lang_name FROM languages"
            self.cursor.execute(query)
            languages = self.cursor.fetchall()
            
            # 建立語言對應表
            for lang in languages:
                lang_code = lang['lang_code']
                lang_name = lang['lang_name']
                
                # 根據語言代碼設定英文名稱（用於翻譯提示）
                if lang_code == 'en':
                    self.language_mapping[lang_code] = 'English'
                elif lang_code == 'ja':
                    self.language_mapping[lang_code] = 'Japanese'
                elif lang_code == 'ko':
                    self.language_mapping[lang_code] = 'Korean'
                elif lang_code == 'zh-TW':
                    self.language_mapping[lang_code] = 'Traditional Chinese (Taiwan)'
                else:
                    # 其他語言使用資料庫中的名稱
                    self.language_mapping[lang_code] = lang_name
            
            logger.info(f"成功載入 {len(self.language_mapping)} 種語言設定")
            
        except Error as e:
            logger.error(f"載入語言設定失敗: {e}")
            # 使用預設語言設定
            self.language_mapping = {
                'en': 'English',
                'ja': 'Japanese', 
                'ko': 'Korean',
                'zh-TW': 'Traditional Chinese (Taiwan)'
            }
    
    def translate_review_summary(self, review_summary, target_lang_code):
        """翻譯評論摘要"""
        try:
            if not review_summary or not review_summary.strip():
                logger.warning("評論摘要為空，跳過翻譯")
                return ""
            
            # 如果目標語言是繁體中文（台灣），直接返回原文
            if target_lang_code == 'zh-TW':
                logger.info(f"目標語言為繁體中文 ({target_lang_code})，直接返回原文")
                return review_summary
            
            # 取得目標語言名稱
            target_language = self.language_mapping.get(target_lang_code, target_lang_code)
            
            # 針對資料庫中的不同語言設計翻譯提示

            # 其他語言或未知語言使用通用模板
            prompt = f"""
請將以下繁體中文的餐廳評論摘要翻譯成{target_language}，保持原有格式和結構，不要加任何前言或說明：

{review_summary}

翻譯要求：
1. 保持原有的標題格式（## 標題）
2. 保持菜品Top5的編號格式
3. 翻譯要自然流暢，符合目標語言的表達習慣
4. 菜品名稱可以保留中文並加上{target_language}翻譯
5. 數字和統計資訊保持不變
6. 使用專業的餐廳評論術語
7. 直接輸出分析報告，不要有「好的，這是...」等開場白
"""
            
            logger.info(f"開始翻譯評論摘要到 {target_language} ({target_lang_code})")
            response = self.model.generate_content(prompt)
            
            if response and response.text:
                translated_text = response.text.strip()
                logger.info(f"成功翻譯評論摘要到 {target_language}")
                logger.debug(f"翻譯結果長度: {len(translated_text)} 字符")
                return translated_text
            else:
                logger.error(f"Gemini API 翻譯失敗，沒有返回結果")
                return ""
                
        except Exception as e:
            logger.error(f"翻譯評論摘要到 {target_lang_code} 時發生錯誤: {e}")
            return ""
    
    def batch_translate_and_save(self, store_id, review_summary):
        """批量翻譯並儲存到資料庫"""
        try:
            if not review_summary or not review_summary.strip():
                logger.warning("評論摘要為空，跳過批量翻譯")
                return {}
            
            # 取得所有語言（排除繁體中文，因為原文就是繁體中文）
            target_languages = [
                lang_code for lang_code in self.language_mapping.keys() 
                if lang_code != 'zh-TW'
            ]
            
            logger.info(f"開始批量翻譯店家 {store_id} 到 {len(target_languages)} 種語言")
            
            translations = {}
            
            for lang_code in target_languages:
                try:
                    lang_name = self.language_mapping[lang_code]
                    logger.info(f"正在翻譯到 {lang_name} ({lang_code})")
                    
                    # 執行翻譯
                    translation = self.translate_review_summary(review_summary, lang_code)
                    
                    if translation:
                        # 儲存翻譯到資料庫
                        if self._save_translation_to_db(store_id, lang_code, translation):
                            translations[lang_code] = translation
                            logger.info(f"成功翻譯並儲存到 {lang_name}")
                        else:
                            logger.warning(f"翻譯成功但儲存失敗: {lang_name}")
                    else:
                        logger.warning(f"翻譯到 {lang_name} 失敗")
                    
                    # 避免API請求過於頻繁
                    import time
                    time.sleep(1)
                    
                except Exception as e:
                    logger.error(f"處理語言 {lang_code} 時發生錯誤: {e}")
                    continue
            
            # 同時儲存原文（繁體中文）
            if self._save_translation_to_db(store_id, 'zh-TW', review_summary):
                translations['zh-TW'] = review_summary
                logger.info("成功儲存原文（繁體中文）")
            
            logger.info(f"批量翻譯完成，成功翻譯 {len(translations)} 種語言")
            return translations
            
        except Exception as e:
            logger.error(f"批量翻譯處理失敗: {e}")
            return {}
    
    def _save_translation_to_db(self, store_id, lang_code, translation):
        """將翻譯結果儲存到資料庫"""
        try:
            # 檢查是否已存在該店家和語言的翻譯
            check_query = """
                SELECT id FROM store_translations 
                WHERE store_id = %s AND language_code = %s
            """
            self.cursor.execute(check_query, (store_id, lang_code))
            existing = self.cursor.fetchone()
            
            if existing:
                # 更新現有記錄 - 注意這裡 translated_summary 欄位用來存放翻譯後的摘要
                update_query = """
                    UPDATE store_translations 
                    SET translated_summary = %s
                    WHERE store_id = %s AND language_code = %s
                """
                self.cursor.execute(update_query, (translation, store_id, lang_code))
                logger.debug(f"更新店家 {store_id} 語言 {lang_code} 的翻譯")
            else:
                # 插入新記錄 - 注意這裡 translated_summary 欄位用來存放翻譯後的摘要
                insert_query = """
                    INSERT INTO store_translations (
                        store_id, language_code, translated_summary
                    ) VALUES (%s, %s, %s)
                """
                self.cursor.execute(insert_query, (store_id, lang_code, translation))
                logger.debug(f"新增店家 {store_id} 語言 {lang_code} 的翻譯")
            
            self.connection.commit()
            return True
            
        except Error as e:
            logger.error(f"儲存翻譯到資料庫失敗: {e}")
            if self.connection:
                self.connection.rollback()
            return False
    
    def get_translation_from_db(self, store_id, lang_code):
        """從資料庫取得翻譯"""
        try:
            query = """
                SELECT translated_summary FROM store_translations 
                WHERE store_id = %s AND language_code = %s
            """
            self.cursor.execute(query, (store_id, lang_code))
            result = self.cursor.fetchone()
            
            if result:
                return result['translated_summary']
            else:
                logger.info(f"找不到店家 {store_id} 語言 {lang_code} 的翻譯")
                return None
                
        except Error as e:
            logger.error(f"從資料庫取得翻譯失敗: {e}")
            return None
    
    def get_all_translations_for_store(self, store_id):
        """取得店家所有語言的翻譯"""
        try:
            query = """
                SELECT st.language_code, st.translated_summary, l.lang_name
                FROM store_translations st
                JOIN languages l ON st.language_code = l.lang_code
                WHERE st.store_id = %s
            """
            self.cursor.execute(query, (store_id,))
            results = self.cursor.fetchall()
            
            translations = {}
            for row in results:
                translations[row['lang_code']] = {
                    'translation': row['translated_summary'],
                    'lang_name': row['lang_name']
                }
            
            logger.info(f"取得店家 {store_id} 的 {len(translations)} 種語言翻譯")
            return translations
            
        except Error as e:
            logger.error(f"取得店家翻譯失敗: {e}")
            return {}
    
    def validate_translation(self, original_text, translated_text, target_lang_code):
        """驗證翻譯品質（可選功能）"""
        try:
            if not translated_text or len(translated_text.strip()) < 10:
                logger.warning(f"翻譯結果過短，可能翻譯失敗: {target_lang_code}")
                return False
            
            # 檢查是否保持了原有的結構標記
            if "##" in original_text and "##" not in translated_text:
                logger.warning(f"翻譯結果缺少標題格式: {target_lang_code}")
                return False
            
            # 檢查是否保持了Top5列表格式
            if "Top5" in original_text or "top5" in original_text.lower():
                if not any(char.isdigit() for char in translated_text):
                    logger.warning(f"翻譯結果缺少數字編號: {target_lang_code}")
                    return False
            
            return True
            
        except Exception as e:
            logger.error(f"驗證翻譯時發生錯誤: {e}")
            return True  # 驗證失敗時預設為通過
    
    def get_supported_languages(self):
        """取得支援的語言列表"""
        return list(self.language_mapping.keys())
    
    def is_language_supported(self, lang_code):
        """檢查是否支援特定語言"""
        return lang_code in self.language_mapping.keys()
    
    def close_connection(self):
        """關閉資料庫連接"""
        try:
            if self.cursor:
                self.cursor.close()
            if self.connection and self.connection.is_connected():
                self.connection.close()
                logger.info("翻譯器資料庫連接已關閉")
        except Error as e:
            logger.error(f"關閉翻譯器資料庫連接時發生錯誤: {e}")
    
    def __del__(self):
        """析構函數，確保資料庫連接被關閉"""
        self.close_connection()