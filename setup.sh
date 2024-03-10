#!/bin/bash

# Verifique se o script é executado como root
if [ "$(id -u)" != "0" ]; then
    echo "Este script deve ser executado com sudo!"
    exit 1
fi

# Python3 Verificação
if ! [ -x "$(command -v python3)" ]; then
    echo '[ERRO] python3 não está instalado.' >&2
    exit 1
fi

# Verificação da Versão do Python3
python_version="$(python3 --version 2>&1 | awk '{print $2}')"
py_major=$(echo "$python_version" | cut -d'.' -f1)
py_minor=$(echo "$python_version" | cut -d'.' -f2)
if [ "$py_major" -eq "3" ] && [ "$py_minor" -ge "8" ]; then
    echo "[INSTALAÇÃO] Python ${python_version} encontrado"
else
    echo "[ERRO] As dependências requerem o Python 3.8 ou superior. Você possui a versão ${python_version} ou python3 aponta para o Python ${python_version}."
    exit 1
fi

# Verificação e Atualização do Pip
python3 -m pip -V
if [ $? -eq 0 ]; then
    echo '[INSTALAÇÃO] Pip encontrado'
    python3 -m pip install --no-cache-dir --upgrade pip --user
else
    echo '[ALERTA] python3-pip não está instalado'
     apt install python3-pip -y
    python3 -m pip install --no-cache-dir --upgrade pip --user
fi

# Instalação do venv
 apt install python3-venv -y
echo '[INSTALAÇÃO] Usando virtualenv Python'
rm -rf ./venv
python3 -m venv ./venv
if [ $? -eq 0 ]; then
    echo '[INSTALAÇÃO] Ativando virtualenv'
    source venv/bin/activate
    pip3 install --upgrade pip
else
    echo '[ERRO] Falha ao criar virtualenv.'
    exit 1
fi

# Instalação do screen
[[ ! $(which screen 2>/dev/null) ]] && echo -e "[ALERTA] screen não está instalado." &&  apt install screen -y

echo '[INSTALAÇÃO] Instalando Requisitos'
pip3 install --no-cache-dir wheel
pip3 install --no-cache-dir --use-deprecated=legacy-resolver -r requirements.txt

# Configuração do log e log rotate
log_file="/var/log/url_shortener.log"
log_config="/etc/rsyslog.d/url_shortener_log_rotation.conf"

# Verifique se o arquivo de log já existe
if [ ! -f "$log_file" ]; then
    # Se não existe, cria o arquivo e define as permissões apropriadas
    touch "$log_file"
    chmod 644 "$log_file"
    chown $SUDO_USER:adm "$log_file"  # Alterado para definir o proprietário apropriado

    echo "Arquivo de log criado em $log_file"

    # Crie o arquivo de configuração de rotação
    cat <<EOF > "$log_config"
$log_file {
    size 5M
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 $SUDO_USER adm
    sharedscripts
    postrotate
        /usr/bin/killall -HUP rsyslogd
    endscript
}
EOF
    echo "Configuração de rotação de log para $log_file foi criada."

    # Reinicie o serviço rsyslog para aplicar as alterações
    systemctl restart rsyslog
else
    echo "O arquivo de log $log_file já existe."
fi

echo -e "Configurações finalizadas"
