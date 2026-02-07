# Configuração de GPU NVIDIA no WSL2

Como você reinstalou o Ubuntu no WSL2 do zero, ele não possui as ferramentas necessárias para comunicar com o driver da NVIDIA que já está instalado no seu Windows 11.

## O Conceito

No WSL2, **você NÃO deve instalar drivers da NVIDIA dentro do Linux**. O WSL2 é capaz de usar o driver instalado no Windows (host).

No entanto, para que o **Docker** consiga enxergar e usar essa GPU, você precisa instalar uma "ponte" chamada **NVIDIA Container Toolkit**.

## Passo a Passo Automatizado

Criei um script chamado `setup_gpu_wsl.sh` na raiz do projeto que faz todo o processo automaticamente:

1. Adiciona os repositórios oficiais da NVIDIA.
2. Instala o `nvidia-container-toolkit`.
3. Configura o Docker para usar o runtime da NVIDIA.
4. Reinicia o Docker.
5. Executa um teste (`nvidia-smi`) dentro de um container.

## Execução Manual (Se preferir)

Se quiser fazer manualmente, os comandos são:

```bash
# 1. Configurar repositório
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# 2. Atualizar e Instalar
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# 3. Configurar Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo service docker restart

# 4. Testar
docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi
```
