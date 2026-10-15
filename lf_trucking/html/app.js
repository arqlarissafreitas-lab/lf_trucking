// ==================== MAIN APP ====================

class LFTruckingApp {
    constructor() {
        this.currentPage = 'dashboard';
        this.playerData = {};
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.setupNUIMessageListener();
        this.loadDashboard();
        
        // Notificar servidor que NUI está pronta
        fetch(`https://${GetParentResourceName()}/nuiReady`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        });
    }
    
    setupEventListeners() {
        // Menu de navegação
        document.querySelectorAll('.nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const page = link.getAttribute('data-page');
                this.switchPage(page);
            });
        });
        
        // Botão de fechar
        document.getElementById('closeBtn').addEventListener('click', () => {
            this.close();
        });
        
        // ESC para fechar
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.close();
            }
        });
    }
    
    setupNUIMessageListener() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            
            if (data.action === 'setVisible') {
                const app = document.getElementById('app');
                app.style.display = data.data.visible ? 'flex' : 'none';
            } else if (data.action === 'loadDashboard') {
                this.updateDashboard(data.data);
            } else if (data.action === 'loadContracts') {
                this.loadContracts(data.data);
            }
        });
    }
    
    switchPage(pageName) {
        // Remover ativo de todas as páginas
        document.querySelectorAll('.page').forEach(page => {
            page.classList.remove('active');
        });
        
        // Remover ativo de todos os links
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
        });
        
        // Ativar página selecionada
        const page = document.getElementById(pageName);
        if (page) {
            page.classList.add('active');
        }
        
        // Ativar link selecionado
        const link = document.querySelector(`[data-page="${pageName}"]`);
        if (link) {
            link.classList.add('active');
        }
        
        this.currentPage = pageName;
        
        // Carregar conteúdo
        this.loadPageContent(pageName);
    }
    
    loadPageContent(pageName) {
        switch(pageName) {
            case 'dashboard':
                this.loadDashboard();
                break;
            case 'marketplace':
                this.loadMarketplace();
                break;
            case 'deliveries':
                this.loadDeliveries();
                break;
            case 'garage':
                this.loadGarage();
                break;
            case 'dealership':
                this.loadDealership();
                break;
            case 'progression':
                this.loadProgression();
                break;
            case 'certifications':
                this.loadCertifications();
                break;
        }
    }
    
    loadDashboard() {
        this.callServer('lf_trucking:getProfile', (profile) => {
            this.playerData = profile;
            this.updateDashboard(profile);
        });
    }
    
    updateDashboard(profile) {
        if (!profile) return;
        
        document.getElementById('playerLevel').textContent = profile.level;
        document.getElementById('playerXP').textContent = `${profile.experience} / ${profile.level * 1000}`;
        document.getElementById('playerMoney').textContent = this.formatMoney(profile.total_money);
        document.getElementById('completedDeliveries').textContent = profile.completed_deliveries;
        document.getElementById('totalDistance').textContent = Math.floor(profile.total_distance) + ' km';
        document.getElementById('moneyEarned').textContent = this.formatMoney(profile.money_earned);
        document.getElementById('rating').textContent = '⭐ ' + profile.average_rating.toFixed(1);
        
        // Atualizar barra de XP
        const xpPercent = ((profile.experience % 1000) / 1000) * 100;
        document.getElementById('xpBar').style.width = xpPercent + '%';
    }
    
    loadMarketplace() {
        this.callServer('lf_trucking:getAvailableContracts', (contracts) => {
            this.displayContracts(contracts);
        });
    }
    
    displayContracts(contracts) {
        const container = document.getElementById('contractsList');
        
        if (!contracts || contracts.length === 0) {
            container.innerHTML = '<div class="empty-state">Nenhum contrato disponível</div>';
            return;
        }
        
        container.innerHTML = contracts.map(contract => `
            <div class="contract-card">
                <div class="card-title">${contract.shipper_name}</div>
                <div class="card-details">
                    <div class="detail-row">
                        <span>Origem:</span>
                        <span class="detail-value">${contract.origin_name}</span>
                    </div>
                    <div class="detail-row">
                        <span>Destino:</span>
                        <span class="detail-value">${contract.destination_name}</span>
                    </div>
                    <div class="detail-row">
                        <span>Distância:</span>
                        <span class="detail-value">${Math.floor(contract.estimated_distance)} km</span>
                    </div>
                    <div class="detail-row">
                        <span>Carga:</span>
                        <span class="detail-value">${contract.cargo_type}</span>
                    </div>
                    <div class="detail-row">
                        <span>Peso:</span>
                        <span class="detail-value">${contract.cargo_weight} kg</span>
                    </div>
                    <div class="detail-row">
                        <span>Recompensa:</span>
                        <span class="detail-value">${this.formatMoney(contract.base_reward)}</span>
                    </div>
                </div>
                <div class="card-actions">
                    <button class="btn btn-primary" onclick="app.acceptContract(${contract.id})">
                        Aceitar
                    </button>
                </div>
            </div>
        `).join('');
    }
    
    acceptContract(contractId) {
        this.callServer('lf_trucking:acceptContract', (success, result) => {
            if (success) {
                this.showNotification('Contrato aceito!', 'success');
                this.switchPage('deliveries');
            } else {
                this.showNotification('Erro: ' + (result || 'Desconhecido'), 'error');
            }
        }, contractId);
    }
    
    loadDeliveries() {
        // TODO: Implementar carregamento de entregas ativas
        const container = document.getElementById('deliveriesList');
        container.innerHTML = '<div class="empty-state">Nenhuma entrega ativa</div>';
    }
    
    loadGarage() {
        // TODO: Implementar carregamento de garagem
        const container = document.getElementById('vehiclesList');
        container.innerHTML = '<div class="empty-state">Garagem vazia</div>';
    }
    
    loadDealership() {
        this.callServer('lf_trucking:getDealershipCatalog', (catalog) => {
            this.displayDealership(catalog);
        });
    }
    
    displayDealership(vehicles) {
        const container = document.getElementById('dealershipList');
        
        if (!vehicles || vehicles.length === 0) {
            container.innerHTML = '<div class="empty-state">Nenhum veículo disponível</div>';
            return;
        }
        
        container.innerHTML = vehicles.map(vehicle => `
            <div class="dealership-card">
                <div class="card-title">${vehicle.name}</div>
                <div class="card-details">
                    <div class="detail-row">
                        <span>Modelo:</span>
                        <span class="detail-value">${vehicle.model}</span>
                    </div>
                    <div class="detail-row">
                        <span>Capacidade:</span>
                        <span class="detail-value">${vehicle.capacity} unidades</span>
                    </div>
                    <div class="detail-row">
                        <span>Consumo:</span>
                        <span class="detail-value">${vehicle.fuel_consumption} L/km</span>
                    </div>
                    <div class="detail-row">
                        <span>Nível Mín:</span>
                        <span class="detail-value">${vehicle.required_level}</span>
                    </div>
                    <div class="detail-row">
                        <span>Preço:</span>
                        <span class="detail-value">${this.formatMoney(vehicle.price)}</span>
                    </div>
                </div>
                <div class="card-actions">
                    <button class="btn btn-primary" onclick="app.buyVehicle('${vehicle.model}')">
                        Comprar
                    </button>
                    <button class="btn btn-secondary" onclick="app.financeVehicle('${vehicle.model}')">
                        Financiar
                    </button>
                </div>
            </div>
        `).join('');
    }
    
    buyVehicle(vehicleModel) {
        this.callServer('lf_trucking:buyVehicle', (success, result) => {
            if (success) {
                this.showNotification('Veículo comprado! Placa: ' + result.plate, 'success');
                this.loadDealership();
            } else {
                this.showNotification('Erro: ' + (result || 'Desconhecido'), 'error');
            }
        }, vehicleModel);
    }
    
    financeVehicle(vehicleModel) {
        // TODO: Implementar financiamento
        this.showNotification('Financiamento em desenvolvimento', 'info');
    }
    
    loadProgression() {
        this.callServer('lf_trucking:getSkillTree', (skills) => {
            this.displaySkills(skills);
        });
    }
    
    displaySkills(skills) {
        const container = document.getElementById('skillsTree');
        
        if (!skills || skills.length === 0) {
            container.innerHTML = '<div class="empty-state">Nenhuma habilidade disponível</div>';
            return;
        }
        
        container.innerHTML = skills.map(skill => `
            <div class="skill-card">
                <h4>${skill.name}</h4>
                <p>${skill.description}</p>
                <p>Nível Mín: ${skill.level_requirement} | Custo: ${this.formatMoney(skill.cost)}</p>
                <button class="btn btn-primary" ${!skill.can_unlock ? 'disabled' : ''} 
                    onclick="app.unlockSkill('${skill.id}')">
                    ${skill.unlocked ? 'Desbloquedo' : 'Desbloquear'}
                </button>
            </div>
        `).join('');
    }
    
    unlockSkill(skillId) {
        this.callServer('lf_trucking:unlockSkill', (success, error) => {
            if (success) {
                this.showNotification('Habilidade desbloqueada!', 'success');
                this.loadProgression();
            } else {
                this.showNotification('Erro: ' + (error || 'Desconhecido'), 'error');
            }
        }, skillId);
    }
    
    loadCertifications() {
        this.callServer('lf_trucking:getCertifications', (certs) => {
            this.displayCertifications(certs);
        });
    }
    
    displayCertifications(certs) {
        const container = document.getElementById('certificationsList');
        
        if (!certs || certs.length === 0) {
            container.innerHTML = '<div class="empty-state">Nenhuma certificação</div>';
            return;
        }
        
        container.innerHTML = certs.map(cert => `
            <div class="cert-card">
                <h4>${cert.certification_name}</h4>
                <p>Status: <strong>${cert.status}</strong></p>
                <p>Concedida em: ${new Date(cert.granted_at * 1000).toLocaleDateString('pt-BR')}</p>
            </div>
        `).join('');
    }
    
    // Utilitários
    
    callServer(event, callback, ...args) {
        fetch(`https://${GetParentResourceName()}/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(args)
        }).then(res => res.json()).then(data => {
            callback(data);
        }).catch(err => {
            console.error('Erro ao chamar servidor:', err);
        });
    }
    
    formatMoney(value) {
        return 'R$ ' + value.toLocaleString('pt-BR', { minimumFractionDigits: 2 });
    }
    
    showNotification(message, type = 'info') {
        // Implementar toast notification
        console.log(`[${type.toUpperCase()}] ${message}`);
    }
    
    close() {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST'
        });
    }
}

// Inicializar app quando DOM estiver pronto
let app;
document.addEventListener('DOMContentLoaded', () => {
    app = new LFTruckingApp();
});