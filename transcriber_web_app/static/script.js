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
                <div class="transcription-progress-container" style="display: none; margin-top: 0.75rem;">
                    <span class="progress-status-text" style="font-size: 0.8em; color: var(--color-text-secondary);">Aguardando progresso...</span>
                    <div class="progress-bar-background" style="height: 8px;">
                        <div class="transcription-progress-bar" style="width: 0%;"></div>
                    </div>
                </div>
            </div>
            <div class="result-links" style="display: none;">
                <strong>Downloads:</strong>
                <!-- Links serão adicionados aqui -->
            </div>
        `;
        jobsList.prepend(listItem); // Adiciona no início da lista
        // Passar um objeto 'data' placeholder com progresso inicial.
        // O status inicial é "Iniciado", então o progresso pode ser 0 ou um valor pequeno.
        updateJobStatusDisplay(jobId, initialStatus, [], {
            progress: {
                percentage: 0,
                status_text: initialStatus
            }
        });
    }

    function updateJobStatusDisplay(jobId, statusText, files = [], data = {}) { // data = {} é o default
        const jobElement = document.getElementById(`job-${jobId}`);
        if (!jobElement) return;

        // Garante que data e data.progress existam antes de tentar acessá-los profundamente
        const currentProgress = (data && data.progress) ? data.progress : { percentage: 0, status_text: statusText };

        const statusBadgeElement = jobElement.querySelector('.status-badge');
        const spinnerElement = jobElement.querySelector('.spinner');
        const resultLinksDiv = jobElement.querySelector('.result-links');
        // Elementos da barra de progresso da transcrição
        const transcriptionProgressContainer = jobElement.querySelector('.transcription-progress-container');
        const transcriptionProgressBar = jobElement.querySelector('.transcription-progress-bar');
        const transcriptionProgressText = jobElement.querySelector('.progress-status-text');

        // Limpar classes de status antigas
        statusBadgeElement.classList.remove('status-initiated', 'status-processing', 'status-completed', 'status-error', 'status-not-found');
        statusBadgeElement.textContent = statusText;

        // Atualizar barra de progresso da transcrição
        if ((statusText.toLowerCase() === "processando" || statusText.toLowerCase() === "iniciado")) {
            transcriptionProgressContainer.style.display = 'block';
            transcriptionProgressBar.style.width = `${currentProgress.percentage}%`;
            transcriptionProgressText.textContent = currentProgress.status_text || statusText; // Usa statusText principal se progress.status_text não existir
        } else if (statusText.toLowerCase() === "concluído") {
            transcriptionProgressContainer.style.display = 'block';
            transcriptionProgressBar.style.width = '100%';
            transcriptionProgressText.textContent = "Concluído!";
        } else {
            transcriptionProgressContainer.style.display = 'none';
        }

        if (statusText.toLowerCase() === "processando" || statusText.toLowerCase() === "iniciado") {
            statusBadgeElement.classList.add(statusText.toLowerCase() === "processando" ? 'status-processing' : 'status-initiated');
            spinnerElement.style.display = 'inline-block';
            resultLinksDiv.style.display = 'none';
            resultLinksDiv.innerHTML = '<strong>Downloads:</strong>';

        } else if (statusText.toLowerCase() === "concluído") {
            statusBadgeElement.classList.add('status-completed');
            spinnerElement.style.display = 'none';
            // A lógica da barra de progresso para "Concluído" já está acima

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
            spinnerElement.style.display = 'none'; // Esconder spinner
            transcriptionProgressContainer.style.display = 'none'; // Esconder barra de progresso
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
                // Passar o objeto data completo para updateJobStatusDisplay
                updateJobStatusDisplay(jobId, data.status, data.files, data);
            } else if (response.status === 404) {
                updateJobStatusDisplay(jobId, "Não encontrado", [], { progress: { percentage: 0, status_text: "Job não encontrado." } });
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
        console.log("monitorJobStatus chamado para job_id:", jobId); // DEBUG
        console.log("monitoredJobs antes de adicionar:", Array.from(monitoredJobs)); // DEBUG
        console.log("pollingIntervals[jobId] antes de setar:", pollingIntervals[jobId]); // DEBUG

        if (monitoredJobs.has(jobId) && pollingIntervals[jobId]) {
            console.log("Polling para job_id:", jobId, "já ativo. Retornando."); // DEBUG
            return;
        }
        monitoredJobs.add(jobId);

        fetchJobStatus(jobId); // Chamada inicial

        console.log("Configurando setInterval para job_id:", jobId); // DEBUG
        pollingIntervals[jobId] = setInterval(() => {
            fetchJobStatus(jobId);
        }, 5000);
    }
});
