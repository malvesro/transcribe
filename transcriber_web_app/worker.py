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
    # Habilitar o scheduler para que o worker possa gerenciar retentativas de jobs.
    worker = Worker(queues, connection=conn, worker_ttl=3600)
    worker.work()

