import whisper
import argparse
import os
import torch
import json
import sys
from whisper.utils import get_writer

def update_progress(output_dir, percentage, status_text):
    progress_file = os.path.join(output_dir, "_progress.json")
    progress_data = {
        "percentage": percentage,
        "status_text": status_text
    }
    try:
        with open(progress_file, 'w', encoding='utf-8') as f:
            json.dump(progress_data, f)
        print(f"Progresso atualizado: {percentage}% - {status_text}")
    except Exception as e:
        print(f"Erro ao atualizar progresso: {e}", file=sys.stderr)

def save_transcription(result, output_dir, base_name):
    update_progress(output_dir, 80, "Salvando arquivos...")
    try:
        txt_writer = get_writer("txt", output_dir)
        txt_writer(result, base_name)
        srt_writer = get_writer("srt", output_dir)
        srt_writer(result, base_name)
        vtt_writer = get_writer("vtt", output_dir)
        vtt_writer(result, base_name)
        update_progress(output_dir, 100, "Concluído")
    except Exception as e:
        print(f"Erro ao salvar arquivos: {e}", file=sys.stderr)
        update_progress(output_dir, 0, f"Erro ao salvar: {str(e)}")
        raise

def main():
    parser = argparse.ArgumentParser(description="Transcreve arquivos de vídeo para texto em português")
    parser.add_argument("--video", required=True, type=str, help="Caminho completo do arquivo de vídeo")
    parser.add_argument("--model", type=str, default="small", choices=["tiny", "base", "small", "medium", "large", "large-v2", "large-v3"], help="Modelo do Whisper a ser utilizado")
    parser.add_argument("--output_dir", required=True, type=str, help="Diretório onde salvar os resultados")
    args = parser.parse_args()

    try:
        os.makedirs(args.output_dir, exist_ok=True)
        update_progress(args.output_dir, 5, "Iniciando...")

        if not torch.cuda.is_available():
            print("❌ Alerta: CUDA não está disponível. A transcrição será lenta.")
        else:
            print(f"✅ CUDA disponível! GPU: {torch.cuda.get_device_name(0)}")

        if not os.path.exists(args.video):
            error_msg = f"Arquivo '{args.video}' não encontrado"
            print(f"❌ Erro: {error_msg}", file=sys.stderr)
            update_progress(args.output_dir, 0, f"Erro: {error_msg}")
            sys.exit(1)

        update_progress(args.output_dir, 10, "Carregando modelo...")
        model = whisper.load_model(args.model)

        update_progress(args.output_dir, 40, "Processando com IA...")
        result = model.transcribe(args.video, language="pt", fp16=torch.cuda.is_available(), verbose=True)

        base_name = os.path.splitext(os.path.basename(args.video))[0]
        save_transcription(result, args.output_dir, base_name)
        print(f"✅ Transcrição concluída para '{args.video}'")
        sys.exit(0)
        
    except Exception as e:
        error_msg = f"Erro durante transcrição: {str(e)}"
        print(f"❌ {error_msg}", file=sys.stderr)
        if 'args' in locals() and args.output_dir:
            update_progress(args.output_dir, 0, error_msg)
        sys.exit(1)

if __name__ == "__main__":
    main()
