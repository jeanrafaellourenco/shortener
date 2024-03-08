#!/bin/bash

echo -e "Servidor online em http://0.0.0.0:8080"
. venv/bin/activate &&  python3 app.py
