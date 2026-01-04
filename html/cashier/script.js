// =====================================================
// FX-RESTAURANT | CASHIER SCRIPT
// =====================================================

let selectedPlayer = null;
let selectedPaymentMethod = 'cash';
let currentRestaurant = null;

// =====================================================
// WINDOW MESSAGE LISTENER
// =====================================================
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'openCashier') {
        currentRestaurant = data.restaurant;
        openCashier();
    }
});

// =====================================================
// ESC KEY TO CLOSE
// =====================================================
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeCashier();
    }
});

// =====================================================
// OPEN/CLOSE CASHIER
// =====================================================
function openCashier() {
    $('#cashier').fadeIn(300);
    loadNearbyPlayers();
    resetForm();
}

function closeCashier() {
    $('#cashier').fadeOut(300);
    resetForm();
    $.post('https://fx-restaurant/closeCashier', JSON.stringify({}));
}

$('#closeBtn').click(() => closeCashier());

// =====================================================
// LOAD NEARBY PLAYERS
// =====================================================
function loadNearbyPlayers() {
    $.post('https://fx-restaurant/getNearbyPlayers', JSON.stringify({}), (response) => {
        renderPlayers(response.players || []);
    });
}

$('#refreshBtn').click(() => loadNearbyPlayers());

// =====================================================
// RENDER PLAYERS
// =====================================================
function renderPlayers(players) {
    const container = $('#playersList');
    container.empty();
    
    if (players.length === 0) {
        container.append(`
            <div class="empty-state">
                <i class="fas fa-user-slash"></i>
                <p>Geen klanten in de buurt</p>
                <small>Loop dichter bij een klant</small>
            </div>
        `);
        return;
    }
    
    players.forEach(player => {
        const card = $(`
            <div class="player-card" data-id="${player.id}" data-name="${player.name}">
                <div class="player-info">
                    <div class="player-avatar">
                        <i class="fas fa-user"></i>
                    </div>
                    <div class="player-details">
                        <h3>${player.name}</h3>
                        <span>${player.distance}m away</span>
                    </div>
                </div>
                <span class="player-id">ID: ${player.id}</span>
            </div>
        `);
        
        card.click(function() {
            selectPlayer(player.id, player.name);
        });
        
        container.append(card);
    });
}

// =====================================================
// SELECT PLAYER
// =====================================================
function selectPlayer(id, name) {
    selectedPlayer = { id, name };
    
    // Update UI
    $('.player-card').removeClass('selected');
    $(`.player-card[data-id="${id}"]`).addClass('selected');
    
    $('#selectedCustomer')
        .addClass('active')
        .html(`<i class="fas fa-user-check"></i><span>${name}</span>`);
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
// AMOUNT INPUT (UPDATE TOTAL)
// =====================================================
$('#amount').on('input', function() {
    const amount = parseInt($(this).val()) || 0;
    $('#totalAmount').text('$' + amount.toLocaleString());
});

// =====================================================
// FORM SUBMISSION
// =====================================================
$('#paymentForm').submit(function(e) {
    e.preventDefault();
    
    if (!selectedPlayer) {
        showNotification('Selecteer eerst een klant', 'error');
        return;
    }
    
    const amount = parseInt($('#amount').val());
    
    if (!amount || amount <= 0) {
        showNotification('Voer een geldig bedrag in', 'error');
        return;
    }
    
    const notes = $('#notes').val();
    
    // Parse notes to items (simple parsing)
    const items = parseNotes(notes);
    
    // Disable button
    $('#confirmBtn').prop('disabled', true).text('Versturen...');
    
    $.post('https://fx-restaurant/createInvoice', JSON.stringify({
        targetId: selectedPlayer.id,
        targetName: selectedPlayer.name,
        amount: amount,
        paymentMethod: selectedPaymentMethod,
        items: items
    }), (response) => {
        $('#confirmBtn').prop('disabled', false).html('<i class="fas fa-check"></i> Factuur Sturen');
        
        if (response.success) {
            showNotification('Factuur verzonden!', 'success');
            resetForm();
            
            // Refresh players list
            setTimeout(() => loadNearbyPlayers(), 1000);
        } else {
            showNotification('Fout bij verzenden factuur', 'error');
        }
    });
});

// =====================================================
// CANCEL BUTTON
// =====================================================
$('#cancelBtn').click(() => {
    resetForm();
});

// =====================================================
// RESET FORM
// =====================================================
function resetForm() {
    selectedPlayer = null;
    selectedPaymentMethod = 'cash';
    
    $('#amount').val('');
    $('#notes').val('');
    $('#totalAmount').text('$0');
    
    $('.player-card').removeClass('selected');
    $('.payment-method').removeClass('active');
    $('.payment-method[data-method="cash"]').addClass('active');
    
    $('#selectedCustomer')
        .removeClass('active')
        .html('<i class="fas fa-user-circle"></i><span>Selecteer een klant</span>');
}

// =====================================================
// PARSE NOTES TO ITEMS
// =====================================================
function parseNotes(notes) {
    if (!notes) return [];
    
    const items = [];
    const lines = notes.split(/[,\n]/);
    
    lines.forEach(line => {
        const match = line.match(/(\d+)x?\s*(.+)/i);
        if (match) {
            items.push({
                amount: parseInt(match[1]),
                name: match[2].trim()
            });
        } else if (line.trim()) {
            items.push({
                amount: 1,
                name: line.trim()
            });
        }
    });
    
    return items;
}

// =====================================================
// NOTIFICATION (SIMPLE)
// =====================================================
function showNotification(message, type) {
    // This would be handled by the game's notification system
    console.log(`[${type.toUpperCase()}] ${message}`);
}
