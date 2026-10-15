// ==================== MARKETPLACE COMPONENT ====================
// Interface de mercado de fretes

class MarketplaceComponent {
    constructor() {
        this.contracts = [];
        this.selectedContract = null;
        this.filters = {
            cargoType: '',
            minReward: 0,
            maxDistance: 10000,
            difficulty: '',
        };
        this.currentPage = 1;
        this.contractsPerPage = 10;
    }

    render() {
        const html = `
            <div class="marketplace-container">
                <!-- Header -->
                <div class="marketplace-header">
                    <h2>Mercado de Fretes</h2>
                    <div class="refresh-info">
                        <span>Próxima atualização em <strong id="refreshTimer">30</strong>s</span>
                        <button class="btn btn-secondary btn-sm" onclick="refreshContracts()">
                            <i class="icon-refresh"></i> Atualizar
                        </button>
                    </div>
                </div>

                <!-- Filtros -->
                <div class="marketplace-filters">
                    <div class="filter-group">
                        <label>Tipo de Carga</label>
                        <select id="filterCargo" onchange="applyFilters()">
                            <option value="">Todos</option>
                            <option value="alimentos">Alimentos</option>
                            <option value="construcao">Construção</option>
                            <option value="industrial">Industrial</option>
                            <option value="eletronicos">Eletrônicos</option>
                            <option value="quimicos">Químicos</option>
                            <option value="veiculos">Veículos</option>
                            <option value="fragil">Frágil</option>
                            <option value="refrigerado">Refrigerado</option>
                            <option value="especial">Especial</option>
                            <option value="alto_valor">Alto Valor</option>
                        </select>
                    </div>

                    <div class="filter-group">
                        <label>Recompensa Mínima</label>
                        <input type="range" id="filterReward" min="0" max="100000" step="5000" 
                               value="0" onchange="applyFilters()" />
                        <span id="filterRewardValue">R$ 0</span>
                    </div>

                    <div class="filter-group">
                        <label>Distância Máxima</label>
                        <input type="range" id="filterDistance" min="100" max="10000" step="500" 
                               value="10000" onchange="applyFilters()" />
                        <span id="filterDistanceValue">10000 m</span>
                    </div>

                    <div class="filter-group">
                        <label>Dificuldade</label>
                        <select id="filterDifficulty" onchange="applyFilters()">
                            <option value="">Todas</option>
                            <option value="easy">Fácil</option>
                            <option value="normal">Normal</option>
                            <option value="hard">Difícil</option>
                            <option value="extreme">Extrema</option>
                        </select>
                    </div>

                    <button class="btn btn-secondary" onclick="clearFilters()">Limpar Filtros</button>
                </div>

                <!-- Lista de contratos -->
                <div class="contracts-section">
                    <div class="contracts-list" id="contractsList">
                        <div class="loading">Carregando fretes...</div>
                    </div>

                    <!-- Paginação -->
                    <div class="pagination" id="paginationContainer">
                        <!-- Preenchido via JS -->
                    </div>
                </div>

                <!-- Detalhes do contrato selecionado -->
                <div class="contract-detail" id="contractDetail" style="display: none;">
                    <div class="detail-header">
                        <button class="btn-close" onclick="closeContractDetail()">✕</button>
                        <h3 id="detailContractNumber"></h3>
                    </div>

                    <div class="detail-content">
                        <div class="detail-section">
                            <label>Rota</label>
                            <p id="detailRoute"></p>
                        </div>

                        <div class="detail-grid">
                            <div class="detail-box">
                                <label>Distância</label>
                                <span id="detailDistance"></span>
                            </div>
                            <div class="detail-box">
                                <label>Tempo Estimado</label>
                                <span id="detailTime"></span>
                            </div>
                            <div class="detail-box">
                                <label>Recompensa</label>
                                <span id="detailReward" class="money"></span>
                            </div>
                            <div class="detail-box">
                                <label>Dificuldade</label>
                                <span id="detailDifficulty"></span>
                            </div>
                        </div>

                        <div class="detail-section">
                            <label>Informações da Carga</label>
                            <p id="detailCargo"></p>
                            <p id="detailCargoWeight"></p>
                            <p id="detailCargoValue"></p>
                        </div>

                        <div class="detail-section">
                            <label>Requisitos</label>
                            <ul id="detailRequirements"></ul>
                        </div>

                        <div class="detail-section">
                            <label>Observações</label>
                            <p id="detailNotes"></p>
                        </div>

                        <div class="detail-actions">
                            <button class="btn btn-primary btn-large" onclick="acceptSelectedContract()">
                                Aceitar Contrato
                            </button>
                            <button class="btn btn-secondary btn-large" onclick="closeContractDetail()">
                                Cancelar
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        return html;
    }

    async init() {
        await this.loadContracts();
        this.setupAutoRefresh();
        this.setupFilterListeners();
    }

    async loadContracts() {
        try {
            this.contracts = await postNUI('getContracts', {});
            this.renderContracts();
        } catch (error) {
            console.error('Erro ao carregar contratos:', error);
            document.getElementById('contractsList').innerHTML = 
                '<div class="error">Erro ao carregar fretes. Tente novamente.</div>';
        }
    }

    renderContracts() {
        const filtered = this.applyFilters();
        const start = (this.currentPage - 1) * this.contractsPerPage;
        const end = start + this.contractsPerPage;
        const paged = filtered.slice(start, end);

        const container = document.getElementById('contractsList');

        if (paged.length === 0) {
            container.innerHTML = '<div class="empty-state">Nenhum frete disponível com os filtros selecionados.</div>';
            return;
        }

        container.innerHTML = paged.map(contract => `
            <div class="contract-card" onclick="selectContract(${contract.id})">
                <div class="card-header">
                    <span class="contract-id">#${contract.contractNumber}</span>
                    <span class="contract-reward money">${this.formatMoney(contract.baseReward)}</span>
                </div>

                <div class="card-route">
                    <span class="origin">${contract.originName}</span>
                    <i class="icon-arrow-right"></i>
                    <span class="destination">${contract.destinationName}</span>
                </div>

                <div class="card-info">
                    <span title="Distância">
                        <i class="icon-map"></i> ${this.formatDistance(contract.estimatedDistance)}
                    </span>
                    <span title="Tempo">
                        <i class="icon-clock"></i> ~${contract.estimatedTimeHours}h
                    </span>
                    <span title="Carga">
                        <i class="icon-box"></i> ${contract.cargoType}
                    </span>
                    <span title="Dificuldade" class="difficulty-${contract.difficulty}">
                        <i class="icon-gauge"></i> ${contract.difficultyLabel}
                    </span>
                </div>

                <div class="card-footer">
                    <span class="shipper">${contract.shipperName}</span>
                    <span class="expiration">${this.getTimeUntilExpiration(contract.expiresAt)}</span>
                </div>
            </div>
        `).join('');

        this.renderPagination(filtered.length);
    }

    applyFilters() {
        return this.contracts.filter(c => {
            const cargo = !this.filters.cargoType || c.cargoType === this.filters.cargoType;
            const reward = c.baseReward >= this.filters.minReward;
            const distance = c.estimatedDistance <= this.filters.maxDistance;
            const difficulty = !this.filters.difficulty || c.difficulty === this.filters.difficulty;

            return cargo && reward && distance && difficulty;
        });
    }

    renderPagination(total) {
        const pages = Math.ceil(total / this.contractsPerPage);
        if (pages <= 1) {
            document.getElementById('paginationContainer').innerHTML = '';
            return;
        }

        let html = '<div class="pagination-buttons">';
        if (this.currentPage > 1) {
            html += `<button class="btn btn-secondary btn-sm" onclick="changePage(${this.currentPage - 1})">← Anterior</button>`;
        }
        html += `<span class="page-info">Página ${this.currentPage} de ${pages}</span>`;
        if (this.currentPage < pages) {
            html += `<button class="btn btn-secondary btn-sm" onclick="changePage(${this.currentPage + 1})">Próxima →</button>`;
        }
        html += '</div>';

        document.getElementById('paginationContainer').innerHTML = html;
    }

    selectContract(contractId) {
        this.selectedContract = this.contracts.find(c => c.id === contractId);
        if (!this.selectedContract) return;

        document.getElementById('detailContractNumber').textContent = `Contrato #${this.selectedContract.contractNumber}`;
        document.getElementById('detailRoute').textContent = 
            `${this.selectedContract.originName} → ${this.selectedContract.destinationName}`;
        document.getElementById('detailDistance').textContent = this.formatDistance(this.selectedContract.estimatedDistance);
        document.getElementById('detailTime').textContent = `${this.selectedContract.estimatedTimeHours}h`;
        document.getElementById('detailReward').textContent = this.formatMoney(this.selectedContract.baseReward);
        document.getElementById('detailDifficulty').textContent = this.selectedContract.difficultyLabel;
        document.getElementById('detailCargo').textContent = `${this.selectedContract.cargoType}: ${this.selectedContract.cargoDescription}`;
        document.getElementById('detailCargoWeight').textContent = `Peso: ${this.selectedContract.cargoWeight} kg`;
        document.getElementById('detailCargoValue').textContent = `Valor Declarado: ${this.formatMoney(this.selectedContract.cargoValue)}`;

        const requirements = [];
        if (this.selectedContract.requiresCertification) {
            requirements.push(`Certificação: ${this.selectedContract.requiresCertification}`);
        }
        if (this.selectedContract.vehicleTypeRequired) {
            requirements.push(`Tipo de Caminhão: ${this.selectedContract.vehicleTypeRequired}`);
        }
        if (this.selectedContract.minLevel) {
            requirements.push(`Nível Mínimo: ${this.selectedContract.minLevel}`);
        }

        document.getElementById('detailRequirements').innerHTML = requirements
            .map(r => `<li>${r}</li>`).join('');

        document.getElementById('detailNotes').textContent = this.selectedContract.notes || 'Sem observações adicionais.';
        document.getElementById('contractDetail').style.display = 'block';
    }

    formatMoney(value) {
        return 'R$ ' + (value || 0).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }

    formatDistance(meters) {
        if (meters >= 1000) return (meters / 1000).toFixed(1) + ' km';
        return meters + ' m';
    }

    getTimeUntilExpiration(expiresAt) {
        const now = new Date().getTime() / 1000;
        const delta = Math.floor(expiresAt - now);
        if (delta < 0) return 'EXPIRADO';
        if (delta < 3600) return `${Math.floor(delta / 60)}m`;
        if (delta < 86400) return `${Math.floor(delta / 3600)}h`;
        return `${Math.floor(delta / 86400)}d`;
    }

    setupAutoRefresh() {
        setInterval(() => this.loadContracts(), 60000); // A cada 60 segundos
    }

    setupFilterListeners() {
        document.getElementById('filterReward').addEventListener('change', (e) => {
            document.getElementById('filterRewardValue').textContent = 
                'R$ ' + parseInt(e.target.value).toLocaleString('pt-BR');
            this.filters.minReward = parseInt(e.target.value);
            this.currentPage = 1;
            this.renderContracts();
        });

        document.getElementById('filterDistance').addEventListener('change', (e) => {
            const meters = parseInt(e.target.value);
            document.getElementById('filterDistanceValue').textContent = 
                meters >= 1000 ? (meters / 1000).toFixed(1) + ' km' : meters + ' m';
            this.filters.maxDistance = meters;
            this.currentPage = 1;
            this.renderContracts();
        });
    }
}

const marketplace = new MarketplaceComponent();