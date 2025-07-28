#!/usr/bin/env python3
"""
Script para executar testes do Whisper Transcriber
"""
import sys
import os
import subprocess
import argparse

def check_dependencies():
    """Verifica se as dependências estão instaladas"""
    try:
        import flask
        import docker
        print("✅ Dependências Python encontradas")
        return True
    except ImportError as e:
        print(f"❌ Dependência faltando: {e}")
        print("💡 Execute: pip install -r transcriber_web_app/requirements.txt")
        return False

def check_docker():
    """Verifica se Docker está disponível"""
    try:
        result = subprocess.run(['docker', '--version'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ Docker encontrado")
            return True
    except FileNotFoundError:
        pass
    
    print("⚠️  Docker não encontrado - alguns testes serão pulados")
    return False

def run_local_tests():
    """Executa testes que não dependem do Docker"""
    print("\n🧪 Executando testes locais...")
    print("=" * 50)
    
    os.chdir('transcriber_web_app')
    result = subprocess.run([sys.executable, 'test_local.py'], 
                          capture_output=False)
    return result.returncode == 0

def run_full_tests():
    """Executa todos os testes (incluindo Docker)"""
    print("\n🧪 Executando todos os testes...")
    print("=" * 50)
    
    os.chdir('transcriber_web_app')
    result = subprocess.run([sys.executable, '-m', 'pytest', 'test_app.py', '-v'], 
                          capture_output=False)
    return result.returncode == 0

def run_coverage_tests():
    """Executa testes com relatório de cobertura"""
    print("\n📊 Executando testes com cobertura de código...")
    print("=" * 50)
    
    os.chdir('transcriber_web_app')
    result = subprocess.run([
        sys.executable, '-m', 'pytest', 
        'test_app.py', 
        '--cov=.', 
        '--cov-report=term-missing',
        '--cov-report=html',
        '-v'
    ], capture_output=False)
    
    if result.returncode == 0:
        print("\n📈 Relatório de cobertura gerado em htmlcov/index.html")
    
    return result.returncode == 0

def run_specific_test(test_pattern):
    """Executa teste específico baseado no padrão fornecido"""
    print(f"\n🎯 Executando teste específico: {test_pattern}")
    print("=" * 50)
    
    os.chdir('transcriber_web_app')
    result = subprocess.run([
        sys.executable, '-m', 'pytest', 
        f'test_app.py::{test_pattern}',
        '-v'
    ], capture_output=False)
    
    return result.returncode == 0

def main():
    parser = argparse.ArgumentParser(
        description='Executar testes do Whisper Transcriber',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos de uso:
  python run_tests.py                    # Execução automática
  python run_tests.py --local           # Apenas testes locais
  python run_tests.py --full            # Todos os testes
  python run_tests.py --coverage        # Testes com cobertura
  python run_tests.py --test TestSecurity  # Teste específico
        """
    )
    
    parser.add_argument('--local', action='store_true', 
                       help='Executar apenas testes locais (sem Docker)')
    parser.add_argument('--full', action='store_true', 
                       help='Executar todos os testes (incluindo Docker)')
    parser.add_argument('--coverage', action='store_true',
                       help='Executar testes com relatório de cobertura')
    parser.add_argument('--test', type=str,
                       help='Executar teste específico (ex: TestSecurity)')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Saída detalhada')
    
    args = parser.parse_args()
    
    print("🎙️ Whisper Transcriber - Executor de Testes")
    print("=" * 50)
    
    # Verificar dependências
    if not check_dependencies():
        return 1
    
    # Verificar Docker
    docker_available = check_docker()
    
    # Executar teste específico
    if args.test:
        if not docker_available and 'Docker' in args.test:
            print("❌ Docker necessário para este teste")
            return 1
        success = run_specific_test(args.test)
    # Executar com cobertura
    elif args.coverage:
        if not docker_available:
            print("❌ Docker necessário para testes de cobertura completos")
            return 1
        success = run_coverage_tests()
    # Executar apenas locais
    elif args.local:
        success = run_local_tests()
    # Executar completos
    elif args.full:
        if not docker_available:
            print("❌ Docker necessário para testes completos")
            return 1
        success = run_full_tests()
    else:
        # Automático: local se Docker não disponível, completo se disponível
        if docker_available:
            print("🚀 Docker disponível - executando testes completos")
            success = run_full_tests()
        else:
            print("🏠 Docker não disponível - executando testes locais")
            success = run_local_tests()
    
    if success:
        print("\n✅ Todos os testes passaram!")
        print("\n💡 Dicas:")
        print("   • Para testes rápidos: python run_tests.py --local")
        print("   • Para cobertura: python run_tests.py --coverage")
        print("   • Para teste específico: python run_tests.py --test TestSecurity")
        return 0
    else:
        print("\n❌ Alguns testes falharam")
        print("\n🔧 Troubleshooting:")
        print("   • Verifique se as dependências estão instaladas")
        print("   • Para Docker: verifique se está rodando")
        print("   • Consulte TESTING.md para mais detalhes")
        return 1

if __name__ == '__main__':
    sys.exit(main())
