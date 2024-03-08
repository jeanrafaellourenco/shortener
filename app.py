from flask import Flask, request, redirect, render_template, flash, url_for
import sqlite3
import random
import string
import validators
import logging

app = Flask(__name__)
app.secret_key = '4f34721670c51d047ed1204936f55890'  

# Configuração de logging
logging.basicConfig(filename='/var/log/url_shortener.log', level=logging.INFO)
logger = logging.getLogger('shortener')

def get_db_connection():
    conn = sqlite3.connect('url_shortener.db')
    conn.row_factory = sqlite3.Row
    return conn

def create_table():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS urls
                      (id INTEGER PRIMARY KEY AUTOINCREMENT,
                       short_code TEXT UNIQUE,
                       original_url TEXT)''')
    conn.commit()
    conn.close()

def generate_unique_short_code():
    conn = get_db_connection()
    cursor = conn.cursor()
    while True:
        short_code = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(8))
        cursor.execute("SELECT COUNT(*) FROM urls WHERE short_code=?", (short_code,))
        count = cursor.fetchone()[0]
        if count == 0:
            conn.close()
            return short_code

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        original_url = request.form.get('original_url')
        if original_url and validators.url(original_url):
            short_code = generate_unique_short_code()
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("INSERT INTO urls (short_code, original_url) VALUES (?, ?)", (short_code, original_url))
            conn.commit()
            conn.close()
            flash(f'Sua URL encurtada: http://{request.host}/{short_code}', 'success')
        else:
            flash('URL inválida. Certifique-se de fornecer uma URL válida.', 'danger')
    
    return render_template('index.html')

@app.route('/<short_code>')
def redirect_to_original(short_code):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT original_url FROM urls WHERE short_code=?", (short_code,))
    row = cursor.fetchone()
    conn.close()
    if row:
        original_url = row['original_url']
        logger.info(f'Redirecionando de {short_code} para {original_url}')
        return redirect(original_url)
    flash('URL não encontrada.', 'danger')
    return render_template('error.html')

if __name__ == '__main__':
    from waitress import serve
    try:
        logger.info("Servidor online em http://0.0.0.0:8080")
        print("Servidor online em http://0.0.0.0:8080")
        create_table()
        serve(app, host="0.0.0.0", port=8080)
    except Exception as e:
        print(("Erro ao subir o servidor: %s", str(e)))
        logger.error("Erro ao subir o servidor: %s", str(e))