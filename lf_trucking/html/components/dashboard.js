// ==================== DASHBOARD COMPONENT ====================
// Painel principal com informações do jogador

class DashboardComponent {
    constructor() {
        this.playerData = {};
        this.statsChart = null;
        this.revenueChart = null;
    }

    render() {
        const html = `
            <div class="dashboard-container">
                <!-- Header com informações principais -->
                <div class="dashboard-header">
                    <div class="player-card">
                        <div class="player-avatar">
                            <i class="icon-user"></i>
                        </div>
                        <div class="player-info">
                            <h2 id="playerName">Carregando...</h2>
                            <div class="player-level">
                                <span>Nível</span>
                                <strong id="playerLevel">1</strong>
                            </div>
                        </div>
                    </div>

                    <div class="quick-stats">
                        <div class="stat-box">
                            <label>Dinheiro Disponível</label>
                            <span id="playerMoney" class="money">R$ 0,00</span>
                        </div>
                        <div class="stat-box">
                            <label>Saldo Ganho Hoje</label>
                            <span id="todayEarnings" class="money">R$ 0,00</span>
                        </div>
                        <div class="stat-box">
                            <label>Entregas Concluídas</label>
                            <span id="completedDeliveries">0</span>
                        </div>
                        <div class="stat-box">
                            <label>Avaliação</label>
                            <span id="playerRating">⭐ 5.0</span>
                        </div>
                    </div>
                </div>

                <!-- Barra de progressão -->
                <div class="progression-bar">
                    <div class="progression-info">
                        <label>Experiência para próximo nível</label>
                        <span id="xpInfo">0 / 1000</span>
                    </div>
                    <div class="progression-track">
                        <div class="progression-fill" id="xpFill" style="width: 0%"></div>
                    </div>
                </div>

                <!-- Grid de cards de status -->
                <div class="dashboard-grid">
                    <!-- Status de entregas -->
                    <div class="dashboard-section">
                        <h3>Entregas em Andamento</h3>
                        <div class="status-list" id="activeDeliveries">
                            <p class="empty-state">Nenhuma entrega ativa</p>
                        </div>
                    </div>

                    <!-- Fretes disponíveis -->
                    <div class="dashboard-section">
                        <h3>Próximas Oportunidades</h3>
                        <div class="opportunity-list" id="upcomingContracts">
                            <p class="empty-state">Nenhum frete disponível</p>
                        </div>
                    </div>

                    <!-- Documentação pendente -->
                    <div class="dashboard-section">
                        <h3>Documentação Pendente</h3>
                        <div class="doc-list" id="pendingDocs">
                            <p class="empty-state">Tudo em dia</p>
                        </div>
                    </div>

                    <!-- Alertas -->
                    <div class="dashboard-section alert-section">
                        <h3>Avisos e Alertas</h3>
                        <div class="alerts-list" id="alertsList">
                            <p class="empty-state">Sem avisos</p>
                        </div>
                    </div>
                </div>

                <!-- Gráficos -->
                <div class="charts-section">
                    <div class="chart-container">
                        <h3>Faturamento</h3>
                        <canvas id="revenueChart"></canvas>
                    </div>
                    <div class="chart-container">
                        <h3>Desempenho</h3>
                        <canvas id="performanceChart"></canvas>
                    </div>
                </div>

                <!-- Ações rápidas -->
                <div class="quick-actions">
                    <button class="btn btn-primary" onclick="switchPage('marketplace')">
                        <i class="icon-shopping"></i> Ver Fretes
                    </button>
                    <button class="btn btn-secondary" onclick="switchPage('garage')">
                        <i class="icon-truck"></i> Garagem
                    </button>
                    <button class="btn btn-secondary" onclick="switchPage('deliveries')">
                        <i class="icon-box"></i> Entregas
                    </button>
                    <button class="btn btn-secondary" onclick="switchPage('company')">
                        <i class="icon-building"></i> Transportadora
                    </button>
                </div>
            </div>
        `;
        
        return html;
    }

    async init() {
        await this.loadPlayerData();
        this.updateDisplay();
        this.initCharts();
        this.setupAutoRefresh();
    }

    async loadPlayerData() {
        try {
            this.playerData = await postNUI('getDashboardData', {});
        } catch (error) {
            console.error('Erro ao carregar dados:', error);
        }
    }

    updateDisplay() {
        // Informações do jogador
        document.getElementById('playerName').textContent = this.playerData.name || 'Desconhecido';
        document.getElementById('playerLevel').textContent = this.playerData.level || 1;
        document.getElementById('playerMoney').textContent = this.formatMoney(this.playerData.money || 0);
        document.getElementById('todayEarnings').textContent = this.formatMoney(this.playerData.todayEarnings || 0);
        document.getElementById('completedDeliveries').textContent = this.playerData.completedDeliveries || 0;
        document.getElementById('playerRating').textContent = `⭐ ${(this.playerData.rating || 5.0).toFixed(1)}`;

        // Progressão
        const nextLevelXP = this.playerData.level * 1000;
        const currentXP = this.playerData.experience % 1000;
        document.getElementById('xpInfo').textContent = `${currentXP} / 1000`;
        document.getElementById('xpFill').style.width = `${(currentXP / 1000) * 100}%`;

        // Entregas ativas
        this.updateActiveDeliveries();

        // Contratos próximos
        this.updateUpcomingContracts();

        // Documentação pendente
        this.updatePendingDocs();

        // Alertas
        this.updateAlerts();
    }

    updateActiveDeliveries() {
        const container = document.getElementById('activeDeliveries');
        const deliveries = this.playerData.activeDeliveries || [];

        if (deliveries.length === 0) {
            container.innerHTML = '<p class="empty-state">Nenhuma entrega ativa</p>';
            return;
        }

        container.innerHTML = deliveries.map(delivery => `
            <div class="delivery-item">
                <div class="delivery-header">
                    <span class="delivery-id">#${delivery.id}</span>
                    <span class="delivery-status ${delivery.status}">${delivery.statusLabel}</span>
                </div>
                <p class="delivery-route">${delivery.origin} → ${delivery.destination}</p>
                <div class="delivery-progress">
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${delivery.progress || 0}%"></div>
                    </div>
                    <span class="progress-text">${delivery.progress || 0}%</span>
                </div>
                <div class="delivery-details">
                    <span>Distância: ${this.formatDistance(delivery.distance)}</span>
                    <span>Prazo: ${delivery.deadline}</span>
                </div>
            </div>
        `).join('');
    }

    updateUpcomingContracts() {
        const container = document.getElementById('upcomingContracts');
        const contracts = this.playerData.upcomingContracts || [];

        if (contracts.length === 0) {
            container.innerHTML = '<p class="empty-state">Nenhum frete disponível</p>';
            return;
        }

        container.innerHTML = contracts.slice(0, 3).map(contract => `
            <div class="contract-item">
                <div class="contract-header">
                    <span class="contract-id">#${contract.id}</span>
                    <span class="contract-reward">${this.formatMoney(contract.reward)}</span>
                </div>
                <p class="contract-route">${contract.origin} → ${contract.destination}</p>
                <p class="contract-cargo">Carga: ${contract.cargoType}</p>
                <button class="btn btn-small" onclick="acceptJob(${contract.id})">Aceitar</button>
            </div>
        `).join('');
    }

    updatePendingDocs() {
        const container = document.getElementById('pendingDocs');
        const docs = this.playerData.pendingDocuments || [];

        if (docs.length === 0) {
            container.innerHTML = '<p class="empty-state">Tudo em dia</p>';
            return;
        }

        container.innerHTML = docs.map(doc => `
            <div class="doc-item warning">
                <i class="icon-warning"></i>
                <span>${doc.description}</span>
            </div>
        `).join('');
    }

    updateAlerts() {
        const container = document.getElementById('alertsList');
        const alerts = this.playerData.alerts || [];

        if (alerts.length === 0) {
            container.innerHTML = '<p class="empty-state">Sem avisos</p>';
            return;
        }

        container.innerHTML = alerts.map(alert => `
            <div class="alert-item alert-${alert.type}">
                <i class="icon-${alert.type}"></i>
                <div>
                    <p class="alert-title">${alert.title}</p>
                    <p class="alert-message">${alert.message}</p>
                </div>
            </div>
        `).join('');
    }

    initCharts() {
        // Implementar gráficos com Chart.js
        // Gráfico de faturamento
        const revenueCtx = document.getElementById('revenueChart');
        if (revenueCtx) {
            this.revenueChart = new Chart(revenueCtx, {
                type: 'line',
                data: {
                    labels: this.getLastDays(7),
                    datasets: [{
                        label: 'Faturamento',
                        data: this.playerData.revenueTrend || [],
                        borderColor: '#FF9900',
                        backgroundColor: 'rgba(255, 153, 0, 0.1)',
                        tension: 0.4,
                        fill: true,
                    }],
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { display: false },
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: { callback: v => 'R$ ' + (v / 1000).toFixed(0) + 'k' },
                        },
                    },
                },
            });
        }

        // Gráfico de desempenho
        const performanceCtx = document.getElementById('performanceChart');
        if (performanceCtx) {
            this.performanceChart = new Chart(performanceCtx, {
                type: 'doughnut',
                data: {
                    labels: ['Concluídas', 'Canceladas', 'Falhadas'],
                    datasets: [{
                        data: [
                            this.playerData.completedDeliveries || 0,
                            this.playerData.cancelledDeliveries || 0,
                            this.playerData.failedDeliveries || 0,
                        ],
                        backgroundColor: ['#4CAF50', '#FF9800', '#F44336'],
                    }],
                },
                options: {
                    responsive: true,
                    plugins: { legend: { position: 'bottom' } },
                },
            });
        }
    }

    setupAutoRefresh() {
        setInterval(() => this.loadPlayerData(), 30000); // A cada 30 segundos
    }

    getLastDays(days) {
        const labels = [];
        for (let i = days - 1; i >= 0; i--) {
            const date = new Date();
            date.setDate(date.getDate() - i);
            labels.push(date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' }));
        }
        return labels;
    }

    formatMoney(value) {
        return 'R$ ' + (value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    formatDistance(meters) {
        if (meters >= 1000) {
            return (meters / 1000).toFixed(1) + ' km';
        }
        return meters + ' m';
    }
}

// Instanciar componente
const dashboard = new DashboardComponent();