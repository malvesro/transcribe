#!/usr/bin/env python3
"""
Script utilitário para gerenciar configurações do Whisper Transcriber
"""
import os
import argparse
import sys
from config import Config

def show_current_config():
    """Mostra as configurações atuais"""
    print("🔧 Configurações Atuais do Whisper Transcriber")
    print("=" * 50)
    
    config = Config()
    
    print(f"📁 Limite de Arquivo: {config.MAX_FILE_SIZE_DISPLAY}")
    print(f"📊 Tamanho em Bytes: {config.MAX_CONTENT_LENGTH:,}")
    print(f"⏱️  Timeout Transcrição: {config.TRANSCRIPTION_TIMEOUT}s")
    print(f"🔄 Intervalo de Polling: {config.STATUS_POLL_INTERVAL}ms")
    print(f"📂 Pasta de Upload: {config.UPLOAD_FOLDER}")
    print(f"📂 Pasta de Resultados: {config.RESULTS_FOLDER}")
    print(f"🐳 Projeto Docker: {config.COMPOSE_PROJECT_NAME}")
    print(f"📝 Extensões Permitidas: {', '.join(sorted(config.ALLOWED_EXTENSIONS))}")
    
    print("\n🌍 Variáveis de Ambiente:")
    env_vars = [
        'MAX_FILE_SIZE_GB',
        'TRANSCRIPTION_TIMEOUT', 
        'STATUS_POLL_INTERVAL',
        'FLASK_ENV',
        'SECRET_KEY',
        'COMPOSE_PROJECT_NAME'
    ]
    
    for var in env_vars:
        value = os.environ.get(var, 'Não definida')
        if var == 'SECRET_KEY' and value != 'Não definida':
            value = '***OCULTA***'
        print(f"  {var}: {value}")

def validate_file_size(size_gb):
    """Valida se o tamanho do arquivo é razoável"""
    if size_gb <= 0:
        print("❌ Erro: Tamanho deve ser maior que 0")
        return False
    
    if size_gb > 1000:  # 1TB
        print("⚠️  Aviso: Tamanho muito grande (>1TB). Tem certeza?")
        response = input("Continuar? (s/N): ").lower()
        return response in ['s', 'sim', 'y', 'yes']
    
    if size_gb < 0.1:  # 100MB
        print("⚠️  Aviso: Tamanho muito pequeno (<100MB). Pode limitar funcionalidade.")
        response = input("Continuar? (s/N): ").lower()
        return response in ['s', 'sim', 'y', 'yes']
    
    return True

def set_file_size_limit(size_gb):
    """Define o limite de tamanho de arquivo"""
    if not validate_file_size(size_gb):
        return False
    
    # Verificar se existe arquivo .env
    env_file = '.env'
    env_example_file = '.env.example'
    
    if not os.path.exists(env_file):
        if os.path.exists(env_example_file):
            print(f"📋 Copiando {env_example_file} para {env_file}")
            with open(env_example_file, 'r') as src, open(env_file, 'w') as dst:
                dst.write(src.read())
        else:
            print(f"📝 Criando novo arquivo {env_file}")
            with open(env_file, 'w') as f:
                f.write("# Configurações do Whisper Transcriber\n")
                f.write("FLASK_ENV=development\n")
                f.write("COMPOSE_PROJECT_NAME=transcribe\n")
    
    # Ler arquivo .env atual
    env_lines = []
    max_file_size_found = False
    
    with open(env_file, 'r') as f:
        for line in f:
            if line.startswith('MAX_FILE_SIZE_GB='):
                env_lines.append(f'MAX_FILE_SIZE_GB={size_gb}\n')
                max_file_size_found = True
            else:
                env_lines.append(line)
    
    # Se não encontrou a linha, adicionar
    if not max_file_size_found:
        env_lines.append(f'MAX_FILE_SIZE_GB={size_gb}\n')
    
    # Escrever arquivo atualizado
    with open(env_file, 'w') as f:
        f.writelines(env_lines)
    
    print(f"✅ Limite de arquivo atualizado para {size_gb}GB")
    print(f"📁 Configuração salva em {env_file}")
    print("🔄 Reinicie a aplicação para aplicar as mudanças")
    
    return True

def estimate_disk_space(file_size_gb, concurrent_jobs=5):
    """Estima o espaço em disco necessário"""
    print(f"💾 Estimativa de Espaço em Disco para {file_size_gb}GB por arquivo:")
    print("=" * 60)
    
    # Espaço para arquivos originais
    original_space = file_size_gb * concurrent_jobs
    
    # Espaço para resultados (muito pequeno, ~1MB por job)
    results_space = 0.001 * concurrent_jobs
    
    # Espaço para cache do Whisper (~1-5GB dependendo dos modelos)
    whisper_cache = 5
    
    # Margem de segurança (20%)
    total_space = (original_space + results_space + whisper_cache) * 1.2
    
    print(f"📁 Arquivos originais ({concurrent_jobs} jobs): {original_space:.1f}GB")
    print(f"📄 Resultados de transcrição: {results_space:.3f}GB")
    print(f"🧠 Cache de modelos Whisper: {whisper_cache}GB")
    print(f"🛡️  Margem de segurança (20%): {total_space * 0.2:.1f}GB")
    print("-" * 40)
    print(f"💽 Total recomendado: {total_space:.1f}GB")
    
    if total_space > 100:
        print("⚠️  Aviso: Espaço significativo necessário. Considere:")
        print("   - Usar armazenamento em nuvem")
        print("   - Implementar limpeza automática de arquivos antigos")
        print("   - Monitorar uso de disco")

def main():
    parser = argparse.ArgumentParser(description='Gerenciar configurações do Whisper Transcriber')
    parser.add_argument('command', choices=[
        'show', 'set-size', 'estimate-disk'
    ], help='Comando a executar')
    
    parser.add_argument('--size', type=float, help='Tamanho limite em GB')
    parser.add_argument('--jobs', type=int, default=5, help='Número de jobs concorrentes para estimativa')
    
    args = parser.parse_args()
    
    if args.command == 'show':
        show_current_config()
    
    elif args.command == 'set-size':
        if not args.size:
            print("❌ Erro: --size é obrigatório para set-size")
            print("Exemplo: python manage_config.py set-size --size 25")
            sys.exit(1)
        
        success = set_file_size_limit(args.size)
        sys.exit(0 if success else 1)
    
    elif args.command == 'estimate-disk':
        size = args.size or float(os.environ.get('MAX_FILE_SIZE_GB', '15'))
        estimate_disk_space(size, args.jobs)

if __name__ == '__main__':
    main()