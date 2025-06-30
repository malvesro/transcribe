document.addEventListener('DOMContentLoaded', () => {
    const uploadForm = document.getElementById('uploadForm');
    const videoFileIn = document.getElementById('videoFile');
    const modelSizeIn = document.getElementById('modelSize');
    const submitButton = document.getElementById('submitButton');
    const jobsList = document.getElementById('jobsList');
    const uploadProgressContainer = document.getElementById('uploadProgress');
    const uploadPercentageText = document.getElementById('uploadPercentage');
    const progressBar = document.getElementById('progressBar');

    // Guarda os IDs dos jobs que estão sendo monitorados para evitar duplicatas de polling
    const monitoredJobs = new Set();
    // Guarda os intervalos de polling por job_id para poder limpá-los
    const pollingIntervals = {};

    uploadForm.addEventListener('submit', async (event) => {
        event.preventDefault();
        submitButton.disabled = true;
        submitButton.textContent = 'Enviando...';
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
                uploadProgressContainer.style.display = 'none';
                submitButton.disabled = false;
                submitButton.textContent = 'Transcrever';

                if (xhr.status === 202) { // Accepted
                    const response = JSON.parse(xhr.responseText);
                    addJobToList(response.job_id, response.filename, response.model_size, "Iniciado");
                    monitorJobStatus(response.job_id);
                } else {
                    const errorResponse = JSON.parse(xhr.responseText);
                    alert(`Erro ao iniciar transcrição: ${errorResponse.error || xhr.statusText}`);
                    console.error('Erro no upload:', errorResponse);
                }
            };

            xhr.onerror = () => {
                uploadProgressContainer.style.display = 'none';
                submitButton.disabled = false;
                submitButton.textContent = 'Transcrever';
                alert('Erro de rede ou servidor não respondeu durante o upload.');
                console.error('Erro XHR:', xhr.statusText);
            };

            xhr.send(formData);

        } catch (error) {
            console.error('Erro ao enviar o formulário:', error);
            alert(`Ocorreu um erro: ${error.message}`);
            submitButton.disabled = false;
            submitButton.textContent = 'Transcrever';
            uploadProgressContainer.style.display = 'none';
        }
    });

    function addJobToList(jobId, filename, modelSize, initialStatus) {
        const listItem = document.createElement('li');
        listItem.setAttribute('id', `job-${jobId}`);
        listItem.innerHTML = `
            <strong>Arquivo:</strong> ${filename} <br>
            <strong>Modelo:</strong> ${modelSize} <br>
            <strong>Job ID:</strong> ${jobId} <br>
            <strong>Status:</strong> <span class="status">${initialStatus}</span>
            <div class="result-links"></div>
        `;
        // Adiciona no início da lista
        jobsList.prepend(listItem);
    }

    function updateJobStatus(jobId, status, files = []) {
        const jobElement = document.getElementById(`job-${jobId}`);
        if (jobElement) {
            const statusElement = jobElement.querySelector('.status');
            statusElement.textContent = status;

            if (status === "Concluído" && files.length > 0) {
                const resultLinksDiv = jobElement.querySelector('.result-links');
                resultLinksDiv.innerHTML = '<strong>Downloads:</strong> ';
                files.forEach(file => {
                    const link = document.createElement('a');
                    link.href = file.url;
                    link.textContent = `${file.type.toUpperCase()} (${file.filename})`;
                    link.setAttribute('download', file.filename); // Sugere o nome do arquivo para download
                    link.classList.add('download-link');
                    resultLinksDiv.appendChild(link);
                    resultLinksDiv.appendChild(document.createTextNode(' '));
                });
                // Parar o polling para este job
                if (pollingIntervals[jobId]) {
                    clearInterval(pollingIntervals[jobId]);
                    delete pollingIntervals[jobId];
                }
                monitoredJobs.delete(jobId);
            } else if (status !== "Processando" && status !== "Iniciado") {
                 // Se o status for algo como erro ou não encontrado, também paramos o polling.
                if (pollingIntervals[jobId]) {
                    clearInterval(pollingIntervals[jobId]);
                    delete pollingIntervals[jobId];
                }
                monitoredJobs.delete(jobId);
            }
        }
    }

    async function fetchJobStatus(jobId) {
        try {
            const response = await fetch(`/status/${jobId}`);
            if (response.ok) {
                const data = await response.json();
                updateJobStatus(jobId, data.status, data.files);
            } else if (response.status === 404) {
                updateJobStatus(jobId, "Job não encontrado");
                // Parar polling se o job não for encontrado
                if (pollingIntervals[jobId]) {
                    clearInterval(pollingIntervals[jobId]);
                    delete pollingIntervals[jobId];
                }
                monitoredJobs.delete(jobId);
            } else {
                console.error(`Erro ao buscar status para job ${jobId}: ${response.statusText}`);
                // Opcional: não parar o polling em erros de servidor genéricos, pode ser temporário
            }
        } catch (error) {
            console.error(`Erro de rede ao buscar status para job ${jobId}:`, error);
            // Opcional: não parar o polling em erros de rede, pode ser temporário
        }
    }

    function monitorJobStatus(jobId) {
        if (monitoredJobs.has(jobId)) {
            return; // Já está monitorando
        }
        monitoredJobs.add(jobId);

        // Polling inicial imediato
        fetchJobStatus(jobId);

        // Configura polling a cada 5 segundos
        pollingIntervals[jobId] = setInterval(() => {
            fetchJobStatus(jobId);
        }, 5000); // 5 segundos
    }

    // Se houver jobs no localStorage (ex: de uma sessão anterior), poderia tentar recarregá-los.
    // Para este MVP, manteremos simples e os jobs só aparecem quando criados na sessão atual.
});
