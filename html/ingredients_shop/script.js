// =====================================================
// FX-RESTAURANT | INGREDIENT SHOP SCRIPT
// =====================================================

let shopData = null;
let cart = [];
let currentCategory = null;

// Discount tiers (from config)
const discountTiers = [
    { min: 10, max: 24, discount: 5 },
    { min: 25, max: 49, discount: 10 },
    { min: 50, max: 99, discount: 15 },
    { min: 100, discount: 20 }
];

// =====================================================
// WINDOW MESSAGE LISTENER
// =====================================================
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'openIngredientShop') {
        shopData = data.categories;
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
    $('#ingredientShop').fadeIn(300);
    renderCategories();
    updateCart();
}

function closeShop() {
    $('#ingredientShop').fadeOut(300);
    cart = [];
    currentCategory = null;
    $.post('https://fx-restaurant/closeIngredientShop', JSON.stringify({}));
}

$('#closeBtn').click(() => closeShop());

// =====================================================
// RENDER CATEGORIES
// =====================================================
function renderCategories() {
    const container = $('#categories');
    container.empty();
    
    if (!shopData || shopData.length === 0) return;
    
    shopData.forEach((category, index) => {
        const btn = $(`
            <button class="category-btn ${index === 0 ? 'active' : ''}" data-index="${index}">
                <i class="${category.icon}"></i>
                ${category.label}
            </button>
        `);
        
        btn.click(function() {
            $('.category-btn').removeClass('active');
            $(this).addClass('active');
            currentCategory = index;
            renderItems(category.items);
        });
        
        container.append(btn);
    });
    
    // Show first category by default
    if (shopData[0]) {
        currentCategory = 0;
        renderItems(shopData[0].items);
    }
}

// =====================================================
// RENDER ITEMS
// =====================================================
function renderItems(items) {
    const container = $('#itemsGrid');
    container.empty();
    
    if (!items || items.length === 0) {
        container.append(`
            <div class="empty-state">
                <i class="fas fa-box-open"></i>
                <p>Geen items in deze categorie</p>
            </div>
        `);
        return;
    }
    
    items.forEach(item => {
        const card = $(`
            <div class="item-card">
                <div class="item-icon">
                    <i class="fas fa-leaf"></i>
                </div>
                <div class="item-name">${item.label}</div>
                <div class="item-price">$${item.price}</div>
                <div class="item-actions">
                    <input type="number" class="quantity-input" value="1" min="1" max="999">
                    <button class="btn-add">
                        <i class="fas fa-plus"></i>
                    </button>
                </div>
            </div>
        `);
        
        card.find('.btn-add').click(function() {
            const amount = parseInt(card.find('.quantity-input').val()) || 1;
            addToCart(item, amount);
        });
        
        container.append(card);
    });
}

// =====================================================
// CART MANAGEMENT
// =====================================================
function addToCart(item, amount) {
    // Check if item already in cart
    const existing = cart.find(c => c.item === item.item);
    
    if (existing) {
        existing.amount += amount;
    } else {
        cart.push({
            item: item.item,
            label: item.label,
            price: item.price,
            amount: amount
        });
    }
    
    updateCart();
    
    // Feedback
    playSound();
}

function removeFromCart(item) {
    cart = cart.filter(c => c.item !== item);
    updateCart();
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
        $('#subtotal').text('$0');
        $('#discount').text('-$0');
        $('#total').text('$0');
        $('#discountRow').hide();
        $('#purchaseBtn').prop('disabled', true);
        return;
    }
    
    // Render cart items
    cart.forEach(cartItem => {
        const itemDiv = $(`
            <div class="cart-item">
                <div class="cart-item-info">
                    <div class="cart-item-name">${cartItem.label}</div>
                    <div class="cart-item-details">
                        ${cartItem.amount}x $${cartItem.price} = $${cartItem.amount * cartItem.price}
                    </div>
                </div>
                <button class="cart-item-remove">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        `);
        
        itemDiv.find('.cart-item-remove').click(() => {
            removeFromCart(cartItem.item);
        });
        
        container.append(itemDiv);
    });
    
    // Calculate totals
    const totalItems = cart.reduce((sum, item) => sum + item.amount, 0);
    const subtotal = cart.reduce((sum, item) => sum + (item.price * item.amount), 0);
    
    // Calculate discount
    let discountPercent = 0;
    for (const tier of discountTiers) {
        if (totalItems >= tier.min) {
            if (!tier.max || totalItems <= tier.max) {
                discountPercent = tier.discount;
            }
        }
    }
    
    const discountAmount = Math.floor(subtotal * (discountPercent / 100));
    const total = subtotal - discountAmount;
    
    // Update UI
    $('#cartCount').text(totalItems);
    $('#subtotal').text('$' + subtotal.toLocaleString());
    
    if (discountPercent > 0) {
        $('#discountLabel').text(`Korting (${discountPercent}%):`);
        $('#discount').text('-$' + discountAmount.toLocaleString());
        $('#discountRow').show();
    } else {
        $('#discountRow').hide();
    }
    
    $('#total').text('$' + total.toLocaleString());
    $('#purchaseBtn').prop('disabled', false);
}

// =====================================================
// PURCHASE
// =====================================================
$('#purchaseBtn').click(function() {
    if (cart.length === 0) return;
    
    const subtotal = cart.reduce((sum, item) => sum + (item.price * item.amount), 0);
    const totalItems = cart.reduce((sum, item) => sum + item.amount, 0);
    
    let discountPercent = 0;
    for (const tier of discountTiers) {
        if (totalItems >= tier.min) {
            if (!tier.max || totalItems <= tier.max) {
                discountPercent = tier.discount;
            }
        }
    }
    
    const discountAmount = Math.floor(subtotal * (discountPercent / 100));
    const total = subtotal - discountAmount;
    
    // Disable button
    $(this).prop('disabled', true).text('Verwerken...');
    
    $.post('https://fx-restaurant/purchaseItems', JSON.stringify({ total }), (response) => {
        if (response.success) {
            cart = [];
            updateCart();
        }
        
        // Re-enable button
        $('#purchaseBtn').prop('disabled', false).html('<i class="fas fa-check"></i> Afrekenen');
    });
});

// =====================================================
// UTILITY
// =====================================================
function playSound() {
    // Could trigger sound via NUI callback
}
