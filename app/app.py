from flask import Flask, jsonify
import os
import socket
import datetime

app = Flask(__name__)

@app.route('/')
def home():
    """メインエンドポイント - 現在の環境情報を返す"""
    environment = os.environ.get('ENVIRONMENT', 'UNKNOWN')
    version = os.environ.get('VERSION', '1.0.0')
    hostname = socket.gethostname()
    
    # B/G環境の識別
    if environment.upper() == 'BLUE':
        color = '🔵 BLUE'
        bg_color = '#0066cc'
    elif environment.upper() == 'GREEN':
        color = '🟢 GREEN'
        bg_color = '#009900'
    else:
        color = '⚪ UNKNOWN'
        bg_color = '#666666'
    
    response_data = {
        'environment': color,
        'version': version,
        'hostname': hostname,
        'timestamp': datetime.datetime.now().isoformat(),
        'message': f'Hello from {color} environment!',
        'bg_color': bg_color
    }
    
    return jsonify(response_data)

@app.route('/health')
def health():
    """ヘルスチェックエンドポイント"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.datetime.now().isoformat()
    })

@app.route('/info')
def info():
    """詳細情報エンドポイント"""
    return jsonify({
        'environment': os.environ.get('ENVIRONMENT', 'UNKNOWN'),
        'version': os.environ.get('VERSION', '1.0.0'),
        'hostname': socket.gethostname(),
        'python_version': os.sys.version,
        'environment_variables': {
            key: value for key, value in os.environ.items()
            if not key.startswith('AWS_') and key not in ['PATH', 'PYTHONPATH']
        }
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)