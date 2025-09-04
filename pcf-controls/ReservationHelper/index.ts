import { IInputs, IOutputs } from "./generated/ManifestTypes";

export class ReservationHelper implements ComponentFramework.StandardControl<IInputs, IOutputs> {
    
    private _context: ComponentFramework.Context<IInputs>;
    private _container: HTMLDivElement;
    private _notifyOutputChanged: () => void;
    
    private _reservationId: string;
    private _customerId: string;
    private _spaceId: string;
    private _flowStatus: string;
    
    private _mainContainer: HTMLDivElement;
    private _customerSelectHandler: any;
    
    constructor() {
    }
    
    public init(context: ComponentFramework.Context<IInputs>, notifyOutputChanged: () => void, state: ComponentFramework.Dictionary, container: HTMLDivElement): void {
        this._context = context;
        this._container = container;
        this._notifyOutputChanged = notifyOutputChanged;
        
        // Initialize properties
        this._reservationId = context.parameters.reservationId.raw || "";
        this._customerId = context.parameters.customerId.raw || "";
        this._spaceId = context.parameters.spaceId.raw || "";
        
        // Create main container
        this._mainContainer = document.createElement("div");
        this._mainContainer.className = "reservation-helper-container";
        
        this.renderComponent();
        this._container.appendChild(this._mainContainer);
        
        // Set up event listeners for message passing (simulating LMS)
        this.setupEventListeners();
    }
    
    private renderComponent(): void {
        this._mainContainer.innerHTML = `
            <div class="reservation-helper">
                <div class="reservation-header">
                    <h2>Reservation Helper</h2>
                    <span class="flow-status">${this._flowStatus || 'Ready'}</span>
                </div>
                <div class="reservation-content">
                    <div class="customer-section">
                        <h3>Customer Information</h3>
                        <div id="customerInfo" class="info-panel">
                            ${this._customerId ? this.renderCustomerInfo() : '<p>No customer selected</p>'}
                        </div>
                    </div>
                    <div class="space-section">
                        <h3>Space Information</h3>
                        <div id="spaceInfo" class="info-panel">
                            ${this._spaceId ? this.renderSpaceInfo() : '<p>No space selected</p>'}
                        </div>
                    </div>
                    <div class="actions-section">
                        <button class="btn-primary" id="startFlowBtn">Start Reservation Flow</button>
                        <button class="btn-secondary" id="refreshBtn">Refresh</button>
                    </div>
                </div>
            </div>
        `;
        
        // Attach event handlers
        const startFlowBtn = this._mainContainer.querySelector("#startFlowBtn") as HTMLButtonElement;
        const refreshBtn = this._mainContainer.querySelector("#refreshBtn") as HTMLButtonElement;
        
        if (startFlowBtn) {
            startFlowBtn.addEventListener("click", this.handleStartFlow.bind(this));
        }
        
        if (refreshBtn) {
            refreshBtn.addEventListener("click", this.handleRefresh.bind(this));
        }
    }
    
    private renderCustomerInfo(): string {
        // In real implementation, fetch customer details from Dataverse
        return `
            <div class="customer-details">
                <p><strong>Customer ID:</strong> ${this._customerId}</p>
                <p><strong>Status:</strong> Active</p>
            </div>
        `;
    }
    
    private renderSpaceInfo(): string {
        // In real implementation, fetch space details from Dataverse
        return `
            <div class="space-details">
                <p><strong>Space ID:</strong> ${this._spaceId}</p>
                <p><strong>Availability:</strong> Available</p>
            </div>
        `;
    }
    
    private setupEventListeners(): void {
        // Listen for customer selection events (simulating LMS)
        this._customerSelectHandler = (event: CustomEvent) => {
            if (event.detail && event.detail.customerId) {
                this.handleCustomerSelect(event.detail.customerId);
            }
        };
        
        window.addEventListener("customerSelected", this._customerSelectHandler);
    }
    
    private handleCustomerSelect(customerId: string): void {
        this._customerId = customerId;
        
        if (this._flowStatus === "started") {
            // Show toast notification
            this.showNotification("Please finish the current operation first", "warning");
        } else {
            // Update customer info
            this.updateCustomerInfo();
        }
    }
    
    private handleStartFlow(): void {
        if (!this._customerId) {
            this.showNotification("Please select a customer first", "error");
            return;
        }
        
        this._flowStatus = "started";
        this._notifyOutputChanged();
        
        // Trigger Power Automate flow
        this.triggerReservationFlow();
    }
    
    private handleRefresh(): void {
        // Refresh data from Dataverse
        this.refreshData();
    }
    
    private async triggerReservationFlow(): Promise<void> {
        try {
            // Call Power Automate flow through Web API
            const flowUrl = "/api/data/v9.2/workflows(00000000-0000-0000-0000-000000000000)/Microsoft.Dynamics.CRM.ExecuteWorkflow";
            
            const flowInput = {
                EntityId: this._reservationId || "",
                CustomerId: this._customerId,
                SpaceId: this._spaceId
            };
            
            // In real implementation, make actual API call
            this.showNotification("Reservation flow started", "success");
            
            // Update status
            this._flowStatus = "in_progress";
            this._notifyOutputChanged();
            
        } catch (error) {
            this.showNotification("Failed to start reservation flow", "error");
            this._flowStatus = "error";
            this._notifyOutputChanged();
        }
    }
    
    private updateCustomerInfo(): void {
        const customerInfoDiv = this._mainContainer.querySelector("#customerInfo");
        if (customerInfoDiv) {
            customerInfoDiv.innerHTML = this.renderCustomerInfo();
        }
    }
    
    private async refreshData(): Promise<void> {
        try {
            // Fetch latest data from Dataverse
            if (this._reservationId) {
                const reservation = await this.getReservation(this._reservationId);
                // Update component with fresh data
                this.renderComponent();
            }
            
            this.showNotification("Data refreshed", "info");
        } catch (error) {
            this.showNotification("Failed to refresh data", "error");
        }
    }
    
    private async getReservation(reservationId: string): Promise<any> {
        // Use Web API to fetch reservation
        try {
            const result = await this._context.webAPI.retrieveRecord("es_reservation", reservationId, "?$select=es_name,es_status,es_startdate,es_enddate");
            return result;
        } catch (error) {
            console.error("Error fetching reservation:", error);
            throw error;
        }
    }
    
    private showNotification(message: string, type: "success" | "error" | "warning" | "info"): void {
        // In real implementation, use Xrm.Navigation.openAlertDialog or custom notification
        console.log(`[${type.toUpperCase()}] ${message}`);
        
        // Create temporary notification element
        const notification = document.createElement("div");
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        
        this._mainContainer.appendChild(notification);
        
        // Remove after 3 seconds
        setTimeout(() => {
            notification.remove();
        }, 3000);
    }
    
    public updateView(context: ComponentFramework.Context<IInputs>): void {
        this._context = context;
        
        // Update properties if changed
        const newReservationId = context.parameters.reservationId.raw || "";
        const newCustomerId = context.parameters.customerId.raw || "";
        const newSpaceId = context.parameters.spaceId.raw || "";
        
        if (newReservationId !== this._reservationId || 
            newCustomerId !== this._customerId || 
            newSpaceId !== this._spaceId) {
            
            this._reservationId = newReservationId;
            this._customerId = newCustomerId;
            this._spaceId = newSpaceId;
            
            this.renderComponent();
        }
    }
    
    public getOutputs(): IOutputs {
        return {
            flowStatus: this._flowStatus
        };
    }
    
    public destroy(): void {
        // Remove event listeners
        if (this._customerSelectHandler) {
            window.removeEventListener("customerSelected", this._customerSelectHandler);
        }
    }
}