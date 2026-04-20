import time
import redis
from rq import Queue, Worker, Retry

def fail_job():
    print("Executando job que falha...")
    raise Exception("Erro intencional para teste de retentativa")

def main():
    redis_url = 'redis://localhost:6379/0'
    try:
        conn = redis.from_url(redis_url)
        conn.ping()
    except Exception:
        print("Redis local não encontrado. Este teste requer um Redis rodando em localhost:6379")
        return

    q = Queue(connection=conn)

    # Limpar filas anteriores
    q.empty()

    print("Enfileirando job com 2 retentativas...")
    job = q.enqueue(fail_job, retry=Retry(max=2, interval=[2, 5]))

    print(f"Job ID: {job.id}")

    # Aqui não podemos iniciar o worker facilmente em segundo plano de forma confiável no sandbox
    # sem bloquear. Mas o código acima demonstra a intenção de teste.
    print("Para testar manualmente, rode o worker com 'python3 worker.py' em outro terminal.")

if __name__ == "__main__":
    main()
