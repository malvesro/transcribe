import whisper
import argparse
import os
import torch
from whisper.utils import get_writer

def save_transcription(result, video_path):
    """Salva a transcrição em diferentes formatos no mesmo diretório do vídeo"""
    output_dir = os.path.dirname(video_path)
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

def main():
    """Script para transcrever arquivos de vídeo usando Whisper com CUDA"""
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

    args = parser.parse_args()

    # Verificação da GPU
    if not torch.cuda.is_available():
        print("❌ Alerta: CUDA não está disponível. A transcrição será lenta.")
    else:
        print(f"✅ CUDA disponível! GPU: {torch.cuda.get_device_name(0)}")

    video_path = os.path.join("/data", args.video)

    if not os.path.exists(video_path):
        print(f"❌ Erro: Arquivo '{video_path}' não encontrado")
        return

    print(f"Carregando modelo '{args.model}'...")
    model = whisper.load_model(args.model)

    print(f"Transcrevendo '{args.video}'...")
    result = model.transcribe(
        video_path,
        language="pt",
        fp16=torch.cuda.is_available(),
        verbose=True
    )

    print("\n--- Transcrição Finalizada ---")
    print(result["text"])
    print("-----------------------------\n")

    save_transcription(result, video_path)
    print(f"✅ Transcrição concluída para '{args.video}'")

if __name__ == "__main__":
    main()