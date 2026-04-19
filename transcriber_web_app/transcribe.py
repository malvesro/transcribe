import sys
import os
import argparse
import torch
import time
import threading
from rq import get_current_job

import whisper
from whisper.utils import get_writer

def get_audio_duration(file_path):
    """Estima a duração do áudio em segundos usando ffmpeg/ffprobe"""
    try:
        import subprocess
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-show_entries', 'format=duration', 
             '-of', 'default=noprint_wrappers=1:nokey=1', file_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            return float(result.stdout.strip())
    except Exception as e:
        print(f"AVISO: Não foi possível determinar duração do áudio: {e}")
    
    # Fallback: assumir 60 segundos se não conseguir determinar
    return 60.0

def progress_updater_thread(job, duration_seconds, stop_event):
    """Thread que atualiza o progresso estimado baseado no tempo decorrido"""
    start_time = time.time()
    # Whisper geralmente processa em 0.1x-0.5x tempo real com GPU
    # Vamos assumir 0.3x (um áudio de 100s leva ~30s)
    estimated_processing_time = duration_seconds * 0.3
    
    last_logged = -1
    while not stop_event.is_set():
        elapsed = time.time() - start_time
        # Calcular progresso estimado (nunca passa de 95% para evitar confusão)
        estimated_progress = min(int((elapsed / estimated_processing_time) * 95), 95)
        
        if job:
            job.meta['progress'] = {
                'percentage': estimated_progress,
                'status_text': f"Transcrevendo: ~{estimated_progress}%"
            }
            job.save_meta()
            
            # Log a cada 10%
            if estimated_progress // 10 > last_logged:
                last_logged = estimated_progress // 10
                print(f"DEBUG: Progresso estimado: {estimated_progress}%")
        
        # Atualizar a cada 2 segundos
        time.sleep(2)

def save_transcription(result, video_path, output_dir=None):
    """Salva a transcrição em diferentes formatos"""
    if output_dir is None:
        output_dir = os.path.dirname(video_path)
    
    os.makedirs(output_dir, exist_ok=True)
    base_name = os.path.splitext(os.path.basename(video_path))[0]

    # Salvar como TXT
    txt_writer = get_writer("txt", output_dir)
    txt_writer(result, base_name)
    print(f"Arquivo TXT salvo em: {os.path.join(output_dir, base_name)}.txt")

    # Salvar como SRT
    srt_writer = get_writer("srt", output_dir)
    srt_writer(result, base_name)
    print(f"Arquivo SRT salvo em: {os.path.join(output_dir, base_name)}.srt")

    # Salvar como VTT
    vtt_writer = get_writer("vtt", output_dir)
    vtt_writer(result, base_name)
    print(f"Arquivo VTT salvo em: {os.path.join(output_dir, base_name)}.vtt")

def transcribe_video(video_path, model_name="small", output_dir=None):
    """Função principal chamada pelo Worker"""
    raise Exception("Erro simulado de transcrição!") # <-- Adicionar esta linha
    print(f"Iniciando transcrição de '{video_path}' com modelo '{model_name}'...")
    
    # Verificação da GPU
    if not torch.cuda.is_available():
        print("❌ Alerta: CUDA não está disponível. A transcrição será lenta.")
    else:
        print(f"✅ CUDA disponível! GPU: {torch.cuda.get_device_name(0)}")

    if not os.path.exists(video_path):
        raise FileNotFoundError(f"Arquivo '{video_path}' não encontrado")

    print(f"Carregando modelo '{model_name}'...")
    model = whisper.load_model(model_name)

    # Obter job RQ atual para reportar progresso
    job = get_current_job()
    
    # Estimar duração do áudio
    audio_duration = get_audio_duration(video_path)
    print(f"Duração estimada do áudio: {audio_duration:.1f}s")
    
    # Iniciar thread de atualização de progresso
    stop_event = threading.Event()
    progress_thread = None
    
    if job:
        progress_thread = threading.Thread(
            target=progress_updater_thread,
            args=(job, audio_duration, stop_event),
            daemon=True
        )
        progress_thread.start()
    
    try:
        print(f"Transcrevendo '{video_path}'...")
        result = model.transcribe(
            video_path,
            language="pt",
            fp16=torch.cuda.is_available(),
            verbose=False
        )
    finally:
        # Parar thread de progresso
        stop_event.set()
        if progress_thread:
            progress_thread.join(timeout=1)
        
        # Definir progresso como 100% ao finalizar
        if job:
            job.meta['progress'] = {
                'percentage': 100,
                'status_text': "Finalizando..."
            }
            job.save_meta()

    print("\n--- Transcrição Finalizada ---")
    print("-----------------------------\n")

    save_transcription(result, video_path, output_dir)
    print(f"✅ Transcrição concluída para '{video_path}'")
    
    return {
        "status": "completed",
        "video_path": video_path,
        "output_dir": output_dir
    }

def main():
    """Script para transcrever arquivos de vídeo usando Whisper com CUDA (CLI)"""
    parser = argparse.ArgumentParser(
        description="Transcreve arquivos de vídeo para texto em português"
    )
    parser.add_argument(
        "--video",
        required=True,
        type=str,
        help="Nome do arquivo de vídeo (ex: 'meu_video.mp4')"
    )
    parser.add_argument(
        "--model",
        type=str,
        default="small",
        choices=["tiny", "base", "small", "medium", "large", "large-v2", "large-v3"],
        help="Modelo do Whisper a ser utilizado"
    )
    parser.add_argument(
        "--output_dir",
        type=str,
        default=None,
        help="Diretório de saída (opcional)"
    )

    args = parser.parse_args()
    
    # Ajustar path se rodando via CLI antigo
    video_path = args.video
    if not os.path.isabs(video_path) and not video_path.startswith("/data"):
         video_path = os.path.join("/data", args.video)

    transcribe_video(video_path, args.model, args.output_dir)

if __name__ == "__main__":
    main()