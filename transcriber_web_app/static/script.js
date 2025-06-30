document.addEventListener('DOMContentLoaded', () => {
    const uploadForm = document.getElementById('uploadForm');
    const videoFileIn = document.getElementById('videoFile');
    const fileNameDisplay = document.getElementById('fileNameDisplay'); // Para exibir o nome do arquivo
    const modelSizeIn = document.getElementById('modelSize');
    const submitButton = document.getElementById('submitButton');
    const jobsList = document.getElementById('jobsList');

    const uploadProgressContainer = document.getElementById('uploadProgressContainer');
    const uploadProgressText = document.getElementById('uploadProgressText'); // Referência para o <p>
    const uploadPercentageText = document.getElementById('uploadPercentage'); // Span dentro do <p>
    const progressBar = document.getElementById('progressBar');

    const monitoredJobs = new Set();
    const pollingIntervals = {};

    // Exibir nome do arquivo selecionado
    videoFileIn.addEventListener('change', () => {
        if (videoFileIn.files.length > 0) {
            fileNameDisplay.textContent = videoFileIn.files[0].name;
        } else {
            fileNameDisplay.textContent = 'Nenhum arquivo selecionado';
        }
    });

    uploadForm.addEventListener('submit', async (event) => {
        event.preventDefault();
        if (!videoFileIn.files || videoFileIn.files.length === 0) {
            // Usar uma notificação toast no futuro aqui
            alert('Por favor, selecione um arquivo para transcrever.');
            return;
        }

        submitButton.disabled = true;
        submitButton.innerHTML = 'Enviando... <span class="spinner" style="display: inline-block; border-width: 2px; width: 0.8em; height: 0.8em;"></span>'; // Adiciona spinner ao botão

        uploadProgressText.style.display = 'block'; // Mostrar o texto de progresso
        uploadProgressContainer.style.display = 'block';
        uploadPercentageText.textContent = '0%';
        progressBar.style.width = '0%';

        const formData = new FormData();
        formData.append('videoFile', videoFileIn.files[0]);
        formData.append('modelSize', modelSizeIn.value);

        try {
            const xhr = new XMLHttpRequest();
            xhr.open('POST', '/upload_and_transcribe', true);

            xhr.upload.onprogress = (e) => {
                if (e.lengthComputable) {
                    const percentage = Math.round((e.loaded / e.total) * 100);
                    uploadPercentageText.textContent = `${percentage}%`;
                    progressBar.style.width = `${percentage}%`;
                }
            };

            xhr.onload = async () => {
                // Esconder progresso de upload um pouco depois para o usuário ver 100%
                setTimeout(() => {
                    uploadProgressContainer.style.display = 'none';
                    uploadProgressText.style.display = 'none';
                }, 500);

                submitButton.disabled = false;
                submitButton.innerHTML = 'Transcrever Áudio/Vídeo'; // Restaura texto original

                if (xhr.status === 202) { // Accepted
                    const response = JSON.parse(xhr.responseText);
                    addJobToList(response.job_id, response.filename, response.model_size, "Iniciado");
                    monitorJobStatus(response.job_id);
                } else {
                    const errorResponse = JSON.parse(xhr.responseText);
                    // Usar toast no futuro
                    alert(`Erro ao iniciar transcrição: ${errorResponse.error || xhr.statusText}`);
                    console.error('Erro no upload:', errorResponse);
                }
            };

            xhr.onerror = () => {
                uploadProgressContainer.style.display = 'none';
                uploadProgressText.style.display = 'none';
                submitButton.disabled = false;
                submitButton.innerHTML = 'Transcrever Áudio/Vídeo';
                alert('Erro de rede ou servidor não respondeu durante o upload.');
                console.error('Erro XHR:', xhr.statusText);
            };

            xhr.send(formData);

        } catch (error) {
            console.error('Erro ao enviar o formulário:', error);
            alert(`Ocorreu um erro: ${error.message}`);
            submitButton.disabled = false;
            submitButton.innerHTML = 'Transcrever Áudio/Vídeo';
            uploadProgressContainer.style.display = 'none';
            uploadProgressText.style.display = 'none';
        }
    });

    function addJobToList(jobId, filename, modelSize, initialStatus) {
        const listItem = document.createElement('li');
        listItem.setAttribute('id', `job-${jobId}`);

        listItem.innerHTML = `
            <div class="job-info">
                <span><strong>Arquivo:</strong> ${filename}</span>
                <span><strong>Modelo:</strong> ${modelSize}</span>
                <span><strong>Job ID:</strong> ${jobId}</span>
                <span class="status-text-container">
                    <strong>Status:</strong>
                    <span class="status-badge status-initiated">${initialStatus}</span>
                    <span class="spinner" style="display: none;"></span>
                </span>
            </div>
            <div class="result-links" style="display: none;">
                <strong>Downloads:</strong>
                <!-- Links serão adicionados aqui -->
            </div>
        `;
        jobsList.prepend(listItem); // Adiciona no início da lista
        updateJobStatusDisplay(jobId, initialStatus); // Para garantir que o spinner apareça se for "Processando"
    }

    function updateJobStatusDisplay(jobId, statusText, files = []) {
        const jobElement = document.getElementById(`job-${jobId}`);
        if (!jobElement) return;

        const statusBadgeElement = jobElement.querySelector('.status-badge');
        const spinnerElement = jobElement.querySelector('.spinner');
        const resultLinksDiv = jobElement.querySelector('.result-links');

        // Limpar classes de status antigas
        statusBadgeElement.classList.remove('status-initiated', 'status-processing', 'status-completed', 'status-error', 'status-not-found');
        statusBadgeElement.textContent = statusText;

        if (statusText.toLowerCase() === "processando" || statusText.toLowerCase() === "iniciado") {
            statusBadgeElement.classList.add(statusText.toLowerCase() === "processando" ? 'status-processing' : 'status-initiated');
            spinnerElement.style.display = 'inline-block';
            resultLinksDiv.style.display = 'none';
            resultLinksDiv.innerHTML = '<strong>Downloads:</strong>'; // Limpa links antigos
        } else if (statusText.toLowerCase() === "concluído") {
            statusBadgeElement.classList.add('status-completed');
            spinnerElement.style.display = 'none';
            if (files.length > 0) {
                resultLinksDiv.innerHTML = '<strong>Downloads:</strong> '; // Limpa e recria
                files.forEach(file => {
                    const link = document.createElement('a');
                    link.href = file.url;
                    link.textContent = file.filename; // Ou file.type.toUpperCase()
                    link.classList.add('download-link');
                    // link.innerHTML = `<i class="fas fa-download"></i> ${file.type.toUpperCase()}`; // Exemplo com ícone
                    resultLinksDiv.appendChild(link);
                    resultLinksDiv.appendChild(document.createTextNode(' '));
                });
                resultLinksDiv.style.display = 'block';
            } else {
                resultLinksDiv.style.display = 'none'; // Caso concluído mas sem arquivos (improvável)
            }
            // Parar polling para este job
            clearJobPolling(jobId);
        } else { // Erro, Não encontrado, etc.
            statusBadgeElement.classList.add(statusText.toLowerCase() === "não encontrado" ? 'status-not-found' : 'status-error');
            spinnerElement.style.display = 'none';
            resultLinksDiv.style.display = 'none';
            // Parar polling para este job
            clearJobPolling(jobId);
        }
    }

    function clearJobPolling(jobId) {
        if (pollingIntervals[jobId]) {
            clearInterval(pollingIntervals[jobId]);
            delete pollingIntervals[jobId];
        }
        monitoredJobs.delete(jobId);
    }


    async function fetchJobStatus(jobId) {
        try {
            const response = await fetch(`/status/${jobId}`);
            if (response.ok) {
                const data = await response.json();
                updateJobStatusDisplay(jobId, data.status, data.files);
            } else if (response.status === 404) {
                updateJobStatusDisplay(jobId, "Não encontrado");
            } else {
                console.error(`Erro HTTP ${response.status} ao buscar status para job ${jobId}: ${response.statusText}`);
                // Opcional: não parar polling em erros genéricos de servidor, pode ser temporário
                // updateJobStatusDisplay(jobId, "Erro no servidor"); // Poderia mostrar um status de erro temporário
            }
        } catch (error) {
            console.error(`Erro de rede ao buscar status para job ${jobId}:`, error);
            // Opcional: não parar polling em erros de rede
            // updateJobStatusDisplay(jobId, "Erro de rede");
        }
    }

    function monitorJobStatus(jobId) {
        if (monitoredJobs.has(jobId) && pollingIntervals[jobId]) { // Checa se já existe um intervalo ativo
            return;
        }
        monitoredJobs.add(jobId);

        fetchJobStatus(jobId); // Chamada inicial

        pollingIntervals[jobId] = setInterval(() => {
            fetchJobStatus(jobId);
        }, 5000); // 5 segundos
    }
});
