import { IInputs, IOutputs } from "./generated/ManifestTypes";

export class ImageGallery implements ComponentFramework.StandardControl<IInputs, IOutputs> {
    
    private _context: ComponentFramework.Context<IInputs>;
    private _container: HTMLDivElement;
    private _notifyOutputChanged: () => void;
    
    private _selectedItem: string;
    private _items: any[];
    private _galleryContainer: HTMLDivElement;
    
    constructor() {
    }
    
    public init(context: ComponentFramework.Context<IInputs>, notifyOutputChanged: () => void, state: ComponentFramework.Dictionary, container: HTMLDivElement): void {
        this._context = context;
        this._container = container;
        this._notifyOutputChanged = notifyOutputChanged;
        
        // Initialize the gallery container
        this._galleryContainer = document.createElement("div");
        this._galleryContainer.className = "image-gallery-container";
        
        this.renderGallery();
        this._container.appendChild(this._galleryContainer);
    }
    
    public updateView(context: ComponentFramework.Context<IInputs>): void {
        this._context = context;
        
        // Parse items from input parameter
        if (context.parameters.items.raw) {
            try {
                this._items = JSON.parse(context.parameters.items.raw);
                this.renderGallery();
            } catch (error) {
                console.error("ImageGallery: Error parsing items", error);
            }
        }
    }
    
    private renderGallery(): void {
        this._galleryContainer.innerHTML = `
            <div class="image-gallery">
                <div class="gallery-header">
                    <h3>Space Gallery</h3>
                </div>
                <div class="gallery-grid" id="galleryGrid">
                    ${this.renderItems()}
                </div>
            </div>
        `;
        
        // Add event listeners for image selection
        this.attachEventListeners();
    }
    
    private renderItems(): string {
        if (!this._items || this._items.length === 0) {
            return '<div class="no-images">No images available</div>';
        }
        
        return this._items.map((item, index) => `
            <div class="image-tile ${item.selected ? 'selected' : ''} ${item.muted ? 'muted' : ''}" 
                 data-id="${item.record?.Id || index}"
                 data-index="${index}">
                <div class="image-container">
                    <img src="${item.record?.ImageUrl || '/default-space.jpg'}" 
                         alt="${item.record?.Name || 'Space Image'}" 
                         loading="lazy" />
                    <div class="image-overlay">
                        <div class="image-info">
                            <h4>${item.record?.Name || 'Unnamed Space'}</h4>
                            <p>${item.record?.Description || ''}</p>
                        </div>
                    </div>
                </div>
                <div class="selection-indicator">
                    <i class="selection-icon">${item.selected ? '✓' : ''}</i>
                </div>
            </div>
        `).join('');
    }
    
    private attachEventListeners(): void {
        const galleryGrid = this._galleryContainer.querySelector("#galleryGrid");
        if (galleryGrid) {
            galleryGrid.addEventListener("click", (event) => {
                const tile = (event.target as HTMLElement).closest(".image-tile") as HTMLElement;
                if (tile) {
                    const itemId = tile.getAttribute("data-id");
                    const itemIndex = parseInt(tile.getAttribute("data-index") || "0");
                    
                    this.selectItem(itemId, itemIndex);
                }
            });
        }
    }
    
    private selectItem(itemId: string | null, itemIndex: number): void {
        if (!this._items) return;
        
        // Update selection state
        this._items = this._items.map((item, index) => {
            const isCurrentItem = (item.record?.Id === itemId) || (index === itemIndex);
            return {
                ...item,
                selected: isCurrentItem ? !item.selected : false // Single selection
            };
        });
        
        // Find selected item
        const selectedItem = this._items.find(item => item.selected);
        this._selectedItem = selectedItem ? (selectedItem.record?.Id || itemIndex.toString()) : "";
        
        // Re-render gallery
        this.renderGallery();
        
        // Notify of changes
        this._notifyOutputChanged();
        
        // Dispatch custom event
        const selectedEvent = new CustomEvent("imageselected", {
            detail: {
                selectedItem: selectedItem,
                selectedId: this._selectedItem
            }
        });
        this._container.dispatchEvent(selectedEvent);
    }
    
    public getOutputs(): IOutputs {
        return {
            selectedItem: this._selectedItem,
            selectedItems: JSON.stringify(this._items?.filter(item => item.selected) || [])
        };
    }
    
    public destroy(): void {
        // Clean up
    }
}