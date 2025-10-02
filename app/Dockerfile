FROM python:3.11-slim

WORKDIR /app

# 依存関係のコピーとインストール
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションコードのコピー
COPY app.py .

# ポート8080を公開
EXPOSE 8080

# 非rootユーザーの作成
RUN useradd --create-home --shell /bin/bash app && chown -R app:app /app
USER app

# Gunicornでアプリケーションを起動
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]