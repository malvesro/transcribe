#!/usr/bin/env python3
"""
Healthcheck script para verificar se a aplicação está funcionando corretamente
"""
import requests
import sys
import os

def check_webapp_health():
    """Verifica se a webapp está respondendo"""
    try:
        response = requests.get('http://localhost:5000/', timeout=10)
        if response.status_code == 200:
            print("✅ WebApp está funcionando")
            return True
        else:
            print(f"❌ WebApp retornou status {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Erro ao conectar com WebApp: {e}")
        return False

def check_directories():
    """Verifica se os diretórios necessários existem"""
    directories = ['videos', 'results']
    all_good = True
    
    for directory in directories:
        if os.path.exists(directory) and os.path.isdir(directory):
            print(f"✅ Diretório {directory}/ existe")
        else:
            print(f"❌ Diretório {directory}/ não encontrado")
            all_good = False
    
    return all_good

def main():
    """Executa todos os checks de saúde"""
    print("🔍 Executando healthcheck...")
    
    checks = [
        check_webapp_health(),
        check_directories()
    ]
    
    if all(checks):
        print("✅ Todos os checks passaram!")
        sys.exit(0)
    else:
        print("❌ Alguns checks falharam!")
        sys.exit(1)

if __name__ == '__main__':
    main()