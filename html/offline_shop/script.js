// =====================================================
// FX-RESTAURANT | OFFLINE SHOP SCRIPT
// =====================================================

let shopData = null;
let cart = [];
let selectedPaymentMethod = 'cash';

// =====================================================
// WINDOW MESSAGE LISTENER
// =====================================================
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'openOfflineShop') {
        shopData = data;
        openShop();
    }
});

// =====================================================
// ESC KEY TO CLOSE
// =====================================================
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeShop();
    }
});

// =====================================================
// OPEN/CLOSE SHOP
// =====================================================
function openShop() {
    $('#shopTitle').text(shopData.restaurant + ' Shop');
    $('#offlineShop').fadeIn(300);
    renderItems();
    updateCart();
}

function closeShop() {
    $('#offlineShop').fadeOut(300);
    cart = [];
    $.post('https://fx-restaurant/closeOfflineShop', JSON.stringify({}));
}

$('#closeBtn').click(() => closeShop());

// =====================================================
// RENDER ITEMS
// =====================================================
function renderItems() {
    const container = $('#itemsGrid');
    container.empty();
    
    if (!shopData.items || shopData.items.length === 0) {
        container.append(`
            <div class="empty-state">
                <i class="fas fa-box-open"></i>
                <p>Geen items beschikbaar</p>
            </div>
        `);
        return;
    }
    
    shopData.items.forEach(item => {
        const card = $(`
            <div class="item-card" data-item="${item.item}">
                <div class="item-image">
                    <i class="fas fa-utensils"></i>
                </div>
                <div class="item-name">${item.label}</div>
                <div class="item-stock">Voorraad: ${item.stock}</div>
                <div class="item-price">$${item.price}</div>
                <div class="item-actions">
                    <button class="btn-add" data-item="${item.item}" 
                            data-label="${item.label}" 
                            data-price="${item.price}"
                            data-stock="${item.stock}">
                        <i class="fas fa-plus"></i> Toevoegen
                    </button>
                </div>
            </div>
        `);
        
        card.find('.btn-add').click(function() {
            const itemData = {
                item: $(this).data('item'),
                label: $(this).data('label'),
                price: $(this).data('price'),
                stock: $(this).data('stock')
            };
            addToCart(itemData);
        });
        
        container.append(card);
    });
}

// =====================================================
// CART MANAGEMENT
// =====================================================
function addToCart(item) {
    // Check if already in cart
    const existing = cart.find(c => c.item === item.item);
    
    if (existing) {
        if (existing.amount >= item.stock) {
            showNotification('Maximale voorraad bereikt', 'warning');
            return;
        }
        existing.amount++;
    } else {
        cart.push({
            item: item.item,
            label: item.label,
            price: item.price,
            amount: 1,
            maxStock: item.stock
        });
    }
    
    updateCart();
    playSound();
}

function removeFromCart(item) {
    cart = cart.filter(c => c.item !== item);
    updateCart();
}

function updateCartAmount(item, amount) {
    const cartItem = cart.find(c => c.item === item);
    if (cartItem) {
        cartItem.amount = Math.max(1, Math.min(amount, cartItem.maxStock));
        updateCart();
    }
}

function updateCart() {
    const container = $('#cartItems');
    container.empty();
    
    if (cart.length === 0) {
        container.append(`
            <div class="empty-cart">
                <i class="fas fa-cart-plus"></i>
                <p>Winkelwagen is leeg</p>
            </div>
        `);
        
        $('#cartCount').text('0');
        $('#total').text('$0');
        $('#purchaseBtn').prop('disabled', true);
        return;
    }
    
    // Render cart items
    cart.forEach(cartItem => {
        const itemDiv = $(`
            <div class="cart-item">
                <div class="cart-item-info">
                    <div class="cart-item-name">${cartItem.label}</div>
                    <div class="cart-item-price">$${cartItem.price} × 
                        <input type="number" class="amount-input" 
                               value="${cartItem.amount}" 
                               min="1" 
                               max="${cartItem.maxStock}"
                               data-item="${cartItem.item}">
                    </div>
                    <div class="cart-item-subtotal">= $${cartItem.price * cartItem.amount}</div>
                </div>
                <button class="cart-item-remove" data-item="${cartItem.item}">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        `);
        
        itemDiv.find('.amount-input').on('change', function() {
            updateCartAmount($(this).data('item'), parseInt($(this).val()));
        });
        
        itemDiv.find('.cart-item-remove').click(function() {
            removeFromCart($(this).data('item'));
        });
        
        container.append(itemDiv);
    });
    
    // Calculate totals
    const totalItems = cart.reduce((sum, item) => sum + item.amount, 0);
    const total = cart.reduce((sum, item) => sum + (item.price * item.amount), 0);
    
    $('#cartCount').text(totalItems);
    $('#total').text('$' + total.toLocaleString());
    $('#purchaseBtn').prop('disabled', false);
}

// =====================================================
// PAYMENT METHOD SELECTION
// =====================================================
$('.payment-method').click(function() {
    selectedPaymentMethod = $(this).data('method');
    $('.payment-method').removeClass('active');
    $(this).addClass('active');
});

// =====================================================
// PURCHASE
// =====================================================
$('#purchaseBtn').click(function() {
    if (cart.length === 0) return;
    
    const total = cart.reduce((sum, item) => sum + (item.price * item.amount), 0);
    
    // Disable button
    $(this).prop('disabled', true).text('Verwerken...');
    
    $.post('https://fx-restaurant/purchaseOfflineShop', JSON.stringify({
        paymentMethod: selectedPaymentMethod
    }), (response) => {
        if (response.success) {
            cart = [];
            updateCart();
            showNotification('Aankoop voltooid!', 'success');
        } else {
            showNotification(getErrorMessage(response.error), 'error');
        }
        
        $('#purchaseBtn').prop('disabled', false).html('<i class="fas fa-check"></i> Afrekenen');
    });
});

// =====================================================
// UTILITY
// =====================================================
function playSound() {
    // Could trigger sound via NUI callback
}

function showNotification(message, type) {
    console.log(`[${type}] ${message}`);
}

function getErrorMessage(error) {
    const messages = {
        empty_cart: 'Winkelwagen is leeg',
        out_of_stock: 'Item niet meer op voorraad',
        insufficient_funds: 'Niet genoeg geld',
        payment_failed: 'Betaling mislukt',
        inventory_full: 'Inventory vol',
        invalid_payment: 'Ongeldige betaalmethode'
    };
    return messages[error] || 'Er is een fout opgetreden';
}