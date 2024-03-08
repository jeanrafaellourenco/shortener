#!/bin/bash

log_file="/var/log/url_shortener.log"
log_config="/etc/rsyslog.d/url_shortener_log_rotation.conf"

# Verifique se o script é executado como root
if [ "$(id -u)" != "0" ]; then
    echo "Este script deve ser executado como root!"
    exit 1
fi

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
