# deployment/Slash/wsgi.py (Peter 和 Leo 的內容也一樣)

# 1. 從您的主應用程式檔案 (例如 app.py) 匯入 app 物件
# *** 如果您的主檔案不叫 app.py，請務必修改這裡！***
from app import app

# 2. 匯入 ProxyFix 中介軟體
from werkzeug.middleware.proxy_fix import ProxyFix

# 3. 使用 ProxyFix 包裝原始的 app 物件
#    x_prefix=1 是關鍵，它會讀取 Nginx 傳來的 X-Script-Name 標頭
#    我們將包裝後的結果賦予一個新的變數 'application'
application = ProxyFix(
    app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1
)
