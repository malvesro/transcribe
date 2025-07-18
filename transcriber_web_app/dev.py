#!/usr/bin/env python3
"""
Script de desenvolvimento para Whisper Transcriber
Facilita tarefas comuns de desenvolvimento
"""
import os
import sys
import subprocess
import argparse

def run_tests():
    """Executa todos os testes"""
    print("🧪 Executando testes...")
    result = subprocess.run([sys.executable, '-m', 'pytest', 'test_app.py', '-v'], 
                          capture_output=False)
    return result.returncode == 0

def run_tests_with_coverage():
    """Executa testes com cobertura"""
    print("📊 Executando testes com cobertura...")
    result = subprocess.run([
        sys.executable, '-m', 'pytest', 
        'test_app.py', 
        '--cov=app', 
        '--cov-report=html',
        '--cov-report=term'
    ], capture_output=False)
    return result.returncode == 0

def lint_code():
    """Executa linting do código"""
    print("🔍 Analisando código...")
    
    # Verificar se flake8 está instalado
    try:
        subprocess.run(['flake8', '--version'], capture_output=True, check=True)
        result = subprocess.run(['flake8', '.', '--max-line-length=120'], 
                              capture_output=False)
        return result.returncode == 0
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("⚠️  flake8 não encontrado. Instale com: pip install flake8")
        return False

def security_check():
    """Executa verificações de segurança"""
    print("🔒 Verificando segurança...")
    
    try:
        # Verificar dependências vulneráveis
        print("Verificando dependências...")
        subprocess.run([sys.executable, '-m', 'pip', 'audit'], 
                      capture_output=False)
        
        # Análise estática com bandit se disponível
        try:
            subprocess.run(['bandit', '--version'], capture_output=True, check=True)
            print("Executando análise estática...")
            result = subprocess.run(['bandit', '-r', '.', '-f', 'json'], 
                                  capture_output=True)
            if result.returncode == 0:
                print("✅ Nenhum problema de segurança encontrado")
            else:
                print("⚠️  Problemas de segurança encontrados")
                print(result.stdout.decode())
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("⚠️  bandit não encontrado. Instale com: pip install bandit")
        
        return True
    except Exception as e:
        print(f"❌ Erro na verificação de segurança: {e}")
        return False

def setup_dev_env():
    """Configura ambiente de desenvolvimento"""
    print("🛠️  Configurando ambiente de desenvolvimento...")
    
    # Instalar dependências de desenvolvimento
    dev_packages = [
        'flake8>=6.0.0',
        'bandit>=1.7.0',
        'black>=23.0.0',
        'isort>=5.12.0'
    ]
    
    for package in dev_packages:
        print(f"Instalando {package}...")
        result = subprocess.run([sys.executable, '-m', 'pip', 'install', package], 
                              capture_output=True)
        if result.returncode == 0:
            print(f"✅ {package} instalado")
        else:
            print(f"❌ Erro ao instalar {package}")

def format_code():
    """Formata o código usando black e isort"""
    print("🎨 Formatando código...")
    
    try:
        # Ordenar imports
        subprocess.run(['isort', '.'], capture_output=False)
        print("✅ Imports organizados")
        
        # Formatar código
        subprocess.run(['black', '.', '--line-length=120'], capture_output=False)
        print("✅ Código formatado")
        
        return True
    except FileNotFoundError:
        print("⚠️  black ou isort não encontrados. Execute: python dev.py setup")
        return False

def clean_cache():
    """Limpa arquivos de cache"""
    print("🧹 Limpando cache...")
    
    cache_dirs = ['__pycache__', '.pytest_cache', 'htmlcov', '.coverage']
    
    for cache_dir in cache_dirs:
        if os.path.exists(cache_dir):
            if os.path.isfile(cache_dir):
                os.remove(cache_dir)
                print(f"✅ Removido {cache_dir}")
            else:
                import shutil
                shutil.rmtree(cache_dir)
                print(f"✅ Removido diretório {cache_dir}")

def main():
    parser = argparse.ArgumentParser(description='Script de desenvolvimento Whisper Transcriber')
    parser.add_argument('command', choices=[
        'test', 'test-cov', 'lint', 'security', 
        'setup', 'format', 'clean', 'all'
    ], help='Comando a executar')
    
    args = parser.parse_args()
    
    if args.command == 'test':
        success = run_tests()
    elif args.command == 'test-cov':
        success = run_tests_with_coverage()
    elif args.command == 'lint':
        success = lint_code()
    elif args.command == 'security':
        success = security_check()
    elif args.command == 'setup':
        success = setup_dev_env()
    elif args.command == 'format':
        success = format_code()
    elif args.command == 'clean':
        clean_cache()
        success = True
    elif args.command == 'all':
        print("🚀 Executando pipeline completo de desenvolvimento...")
        success = all([
            format_code(),
            lint_code(),
            run_tests_with_coverage(),
            security_check()
        ])
        if success:
            print("✅ Pipeline completo executado com sucesso!")
        else:
            print("❌ Pipeline falhou em alguma etapa")
    
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()