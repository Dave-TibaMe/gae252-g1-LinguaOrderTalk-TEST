import configparser
import mysql.connector
from mysql.connector import Error
import os
import re # 導入正則表達式模組

def get_db_config(config_file_path):
    """讀取資料庫設定檔"""
    config = configparser.ConfigParser()
    try:
        config.read(config_file_path)
        db_config = {
            "host": config.get('mysql', 'host'),
            "user": config.get('mysql', 'user'),
            "password": config.get('mysql', 'password'),
            "database": config.get('mysql', 'database'),
            "port": config.getint('mysql', 'port')
        }
        return db_config
    except (configparser.Error, FileNotFoundError) as e:
        print(f"錯誤：無法讀取或解析設定檔 {config_file_path}：{e}")
        return None

def execute_sql_from_file(sql_file_path, db_config):
    """
    連接到 MySQL 資料庫並執行 SQL 檔案中的所有命令。
    此函數會首先嘗試連接到不指定資料庫的執行個體，
    然後切換到目標資料庫，首先執行 DROP TABLE 命令，
    最後執行 SQL 腳本中的 CREATE TABLE 及其他命令。
    """
    conn = None
    cursor = None
    try:
        # 首先嘗試連接到 MySQL 實例，不指定資料庫
        print(f"嘗試連接到 MySQL 執行個體: {db_config['host']}:{db_config['port']}...")
        conn = mysql.connector.connect(
            host=db_config['host'],
            user=db_config['user'],
            password=db_config['password'],
            port=db_config['port']
        )
        cursor = conn.cursor()
        print("成功連接到 MySQL 執行個體。")

        # 檢查資料庫是否存在，如果不存在則創建它
        db_name = db_config['database']
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;")
        print(f"確保資料庫 '{db_name}' 存在。")

        # 切換到目標資料庫
        cursor.execute(f"USE `{db_name}`;")
        print(f"已切換到資料庫 '{db_name}'。")

        # --- 加入 DROP TABLE 命令 ---
        # 暫時禁用外部鍵檢查，以便可以不按順序刪除表格
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
        print("暫時禁用外部鍵檢查。")

        # 從 order_menu.sql 中提取所有 CREATE TABLE 的表格名稱
        tables_to_drop = [
            'account',
            'crawl_logs',
            'gemini_processing',
            'languages',
            'menu_crawls',
            'menu_items',
            'menu_templates',
            'menu_translations',
            'menus',
            'ocr_menu_items',
            'ocr_menus',
            'order_items',
            'orders',
            'store_translations',
            'stores',
            'reviews',
            'user_actions',
            'users'
        ]

        print("正在嘗試刪除所有現有表格 (如果存在)...")
        for table_name in tables_to_drop:
            try:
                cursor.execute(f"DROP TABLE IF EXISTS `{table_name}`;")
                print(f"  - 表格 `{table_name}` 已刪除 (或不存在)。")
            except Error as e:
                # 即使刪除失敗 (例如表格有鎖定)，也嘗試繼續
                print(f"  - 警告：無法刪除表格 `{table_name}`：{e}")
        conn.commit()
        print("所有現有表格的清除操作已完成。")

        # 重新啟用外部鍵檢查
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")
        print("已重新啟用外部鍵檢查。")
        # --- DROP TABLE 命令結束 ---

        # 讀取 SQL 檔案內容
        print(f"讀取 SQL 檔案: {sql_file_path}...")
        with open(sql_file_path, 'r', encoding='utf-8') as file:
            sql_script = file.read()

        # 將 SQL 腳本拆分為單個語句，並過濾掉空語句和註釋
        sql_commands = []
        # 移除多行註釋
        sql_script = re.sub(r'/\*.*?\*/', '', sql_script, flags=re.DOTALL)
        # 按分號分割，同時處理單行註釋
        for statement in sql_script.split(';'):
            clean_statement = statement.strip()
            if clean_statement and not clean_statement.startswith('--') and not clean_statement.startswith('#'):
                sql_commands.append(clean_statement)

        # 執行 SQL 命令
        print(f"正在執行 {len(sql_commands)} 個 SQL 語句以重建表格結構...")
        for i, command in enumerate(sql_commands):
            if command.strip(): # 再次確認不是空字串
                try:
                    cursor.execute(command)
                except Error as e:
                    print(f"執行 SQL 語句失敗 (第 {i+1} 個語句):")
                    print(f"  語句片段: '{command[:100]}...'")
                    print(f"  錯誤: {e}")
                    raise # 這裡選擇拋出異常，以便明確知道哪個語句失敗

        conn.commit()
        print("所有表格已成功重建！")

        # --- 新增：列出資料庫中所有表格 ---
        print("\n--- 資料庫中所有表格列表 ---")
        cursor.execute("SHOW TABLES;")
        tables = cursor.fetchall()
        if tables:
            for table in tables:
                print(f"- {table[0]}")
        else:
            print("目前資料庫中沒有表格。")
        # --- 列出表格結束 ---


    except Error as e:
        print(f"資料庫操作錯誤：{e}")
    except FileNotFoundError:
        print(f"錯誤：找不到 SQL 檔案 '{sql_file_path}'。請確認路徑是否正確。")
    except Exception as e:
        print(f"發生未知錯誤：{e}")
    finally:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()
            print("資料庫連線已關閉。")

if __name__ == "__main__":
    # 根據您的檔案結構，config.ini 在 tools 目錄的上一層
    current_dir = os.path.dirname(os.path.abspath(__file__))
    config_file = os.path.join(current_dir, '..', 'config.ini')
    
    # order_menu.sql 在 rebuild_database.py 相同的 tools 目錄下
    sql_file = os.path.join(current_dir, 'order_menu.sql') 

    db_config = get_db_config(config_file)
    if db_config:
        execute_sql_from_file(sql_file, db_config)