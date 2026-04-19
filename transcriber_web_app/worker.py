import sys
sys.path.append('/app')

import os
import redis
from rq import Worker, Queue


listen = ['default']

redis_url = os.getenv('REDIS_URL', 'redis://redis:6379/0')

conn = redis.from_url(redis_url)

if __name__ == '__main__':
    queues = [Queue(name, connection=conn) for name in listen]
    # Aumentar timeout padrão do worker para 1 hora (3600s) para permitir transcrições longas
    # Habilitar o scheduler (with_scheduler=True) para que o worker possa gerenciar retentativas de jobs.
    # Nota: A partir do RQ 1.15.0, o worker pode atuar como agendador.
    worker = Worker(queues, connection=conn, worker_ttl=3600)
    print("Iniciando Worker com scheduler integrado para retentativas...")
    worker.work(with_scheduler=True)

