// =====================================================
// FX-RESTAURANT | BOSS MENU SCRIPT
// =====================================================

let currentRestaurant = null;
let currentRecipeId = null;
let ingredientsCount = 0;

// =====================================================
// WINDOW MESSAGE LISTENER
// =====================================================
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'openBossMenu') {
        currentRestaurant = data.restaurant;
        openBossMenu();
    }
});

// =====================================================
// ESC KEY TO CLOSE
// =====================================================
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeBossMenu();
    }
});

// =====================================================
// OPEN/CLOSE BOSS MENU
// =====================================================
function openBossMenu() {
    $('#bossMenu').fadeIn(300);
    loadManagementTab();
}

function closeBossMenu() {
    $('#bossMenu').fadeOut(300);
    $.post('https://fx-restaurant/closeBossMenu', JSON.stringify({}));
}

$('#closeBtn').click(() => closeBossMenu());

// =====================================================
// TAB SWITCHING
// =====================================================
$('.tab-btn').click(function() {
    const tab = $(this).data('tab');
    
    // Update buttons
    $('.tab-btn').removeClass('active');
    $(this).addClass('active');
    
    // Update content
    $('.tab-content').removeClass('active');
    $(`#${tab}-tab`).addClass('active');
    
    // Load tab data
    switch(tab) {
        case 'management':
            loadManagementTab();
            break;
        case 'recipes':
            loadRecipesTab();
            break;
        case 'menu':
            loadMenuTab();
            break;
        case 'shop':
            loadShopTab();
            break;
    }
});

// =====================================================
// MANAGEMENT TAB
// =====================================================
function loadManagementTab() {
    $.post('https://fx-restaurant/getManagementData', JSON.stringify({}), (data) => {
        if (!data) return;
        
        // Update statistics
        $('#stat-orders-today').text(data.stats.orders_today || 0);
        $('#stat-revenue-today').text('$' + (data.stats.revenue_today || 0).toLocaleString());
        $('#stat-total-orders').text(data.stats.total_orders || 0);
        $('#stat-deliveries').text(data.stats.total_deliveries || 0);
        
        // Update employees table
        const tbody = $('#employeesTableBody');
        tbody.empty();
        
        if (!data.employees || data.employees.length === 0) {
            tbody.append(`
                <tr class="empty-state">
                    <td colspan="4">Geen medewerkers gevonden</td>
                </tr>
            `);
            return;
        }
        
        data.employees.forEach(employee => {
            tbody.append(`
                <tr>
                    <td>${employee.name || 'Unknown'}</td>
                    <td>
                        <select class="grade-select" data-employee="${employee.id}">
                            ${generateGradeOptions(employee.grade)}
                        </select>
                    </td>
                    <td>${formatDate(employee.hired_at)}</td>
                    <td>
                        <button class="btn btn-danger btn-small fire-employee" data-id="${employee.id}">
                            <i class="fas fa-user-times"></i> Ontslaan
                        </button>
                    </td>
                </tr>
            `);
        });
        
        // Add event listeners
        $('.grade-select').change(function() {
            const employeeId = $(this).data('employee');
            const newGrade = parseInt($(this).val());
            setEmployeeGrade(employeeId, newGrade);
        });
        
        $('.fire-employee').click(function() {
            const employeeId = $(this).data('id');
            fireEmployee(employeeId);
        });
    });
}

function generateGradeOptions(currentGrade) {
    const grades = [
        { value: 0, label: 'Medewerker' },
        { value: 1, label: 'Ervaren Medewerker' },
        { value: 2, label: 'Supervisor' },
        { value: 3, label: 'Manager' },
        { value: 4, label: 'Eigenaar' }
    ];
    
    return grades.map(grade => 
        `<option value="${grade.value}" ${grade.value === currentGrade ? 'selected' : ''}>
            ${grade.label}
        </option>`
    ).join('');
}

// Hire employee
$('#hireEmployeeBtn').click(() => {
    $.post('https://fx-restaurant/hireEmployee', JSON.stringify({}), (response) => {
        if (response.success) {
            loadManagementTab();
        }
    });
});

function fireEmployee(employeeId) {
    $.post('https://fx-restaurant/fireEmployee', JSON.stringify({ employeeId }), (response) => {
        if (response.success) {
            loadManagementTab();
        }
    });
}

function setEmployeeGrade(employeeId, grade) {
    $.post('https://fx-restaurant/setEmployeeGrade', JSON.stringify({ employeeId, grade }), (response) => {
        if (response.success) {
            // Optional: Show success message
        }
    });
}

// =====================================================
// RECIPES TAB
// =====================================================
function loadRecipesTab() {
    $.post('https://fx-restaurant/getRecipes', JSON.stringify({}), (data) => {
        const grid = $('#recipesGrid');
        grid.empty();
        
        if (!data.recipes || Object.keys(data.recipes).length === 0) {
            grid.append(`
                <div class="empty-state">
                    <i class="fas fa-utensils"></i>
                    <p>Geen recepten gevonden</p>
                </div>
            `);
            return;
        }
        
        Object.values(data.recipes).forEach(recipe => {
            grid.append(createRecipeCard(recipe));
        });
        
        // Add event listeners
        $('.edit-recipe').click(function() {
            const recipeId = $(this).data('id');
            openRecipeModal(recipeId);
        });
        
        $('.delete-recipe').click(function() {
            const recipeId = $(this).data('id');
            deleteRecipe(recipeId);
        });
    });
}

function createRecipeCard(recipe) {
    return `
        <div class="recipe-card">
            <img src="${recipe.image || 'https://via.placeholder.com/300x180?text=No+Image'}" 
                 class="recipe-image" 
                 onerror="this.src='https://via.placeholder.com/300x180?text=No+Image'">
            <div class="recipe-body">
                <div class="recipe-header">
                    <div>
                        <div class="recipe-title">${recipe.name}</div>
                        <span class="recipe-type">${recipe.type === 'food' ? 'Eten' : 'Drinken'}</span>
                    </div>
                    <span class="badge ${recipe.active ? 'badge-success' : 'badge-danger'}">
                        ${recipe.active ? 'Actief' : 'Inactief'}
                    </span>
                </div>
                <p class="recipe-description">${recipe.description || 'Geen beschrijving'}</p>
                <div class="recipe-footer">
                    <span class="recipe-price">$${recipe.price}</span>
                    <div class="recipe-actions">
                        <button class="btn btn-primary btn-small edit-recipe" data-id="${recipe.id}">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-danger btn-small delete-recipe" data-id="${recipe.id}">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;
}

// Create recipe button
$('#createRecipeBtn').click(() => {
    openRecipeModal(null);
});

function openRecipeModal(recipeId) {
    currentRecipeId = recipeId;
    
    if (recipeId) {
        // Edit mode - load recipe data
        $('#recipeModalTitle').text('Recept Bewerken');
        // TODO: Load recipe data and populate form
    } else {
        // Create mode
        $('#recipeModalTitle').text('Nieuw Recept');
        $('#recipeForm')[0].reset();
        $('#ingredientsList').empty();
        ingredientsCount = 0;
    }
    
    $('#recipeModal').addClass('active');
}

function closeRecipeModal() {
    $('#recipeModal').removeClass('active');
    currentRecipeId = null;
}

function saveRecipe() {
    const formData = {
        restaurant: currentRestaurant,
        id: currentRecipeId,
        name: $('#recipeName').val(),
        description: $('#recipeDescription').val(),
        type: $('#recipeType').val(),
        station: $('#recipeStation').val(),
        price: parseInt($('#recipePrice').val()),
        animation: $('#recipeAnimation').val() || 'none',
        image: $('#recipeImage').val() || 'default.png',
        active: $('#recipeActive').is(':checked'),
        ingredients: getIngredients()
    };
    
    const action = currentRecipeId ? 'updateRecipe' : 'createRecipe';
    
    $.post(`https://fx-restaurant/${action}`, JSON.stringify(formData), (response) => {
        if (response.success) {
            closeRecipeModal();
            loadRecipesTab();
        }
    });
}

function deleteRecipe(recipeId) {
    $.post('https://fx-restaurant/deleteRecipe', JSON.stringify({ recipeId }), (response) => {
        if (response.success) {
            loadRecipesTab();
        }
    });
}

// Ingredients management
function addIngredient() {
    ingredientsCount++;
    const html = `
        <div class="ingredient-item" data-index="${ingredientsCount}">
            <input type="text" placeholder="Item naam (bijv. meat)" class="ingredient-item-input" style="flex: 2">
            <input type="number" placeholder="Aantal" min="1" class="ingredient-amount-input" style="flex: 1">
            <button type="button" class="btn btn-danger btn-small" onclick="removeIngredient(${ingredientsCount})">
                <i class="fas fa-trash"></i>
            </button>
        </div>
    `;
    $('#ingredientsList').append(html);
}

function removeIngredient(index) {
    $(`.ingredient-item[data-index="${index}"]`).remove();
}

function getIngredients() {
    const ingredients = [];
    $('.ingredient-item').each(function() {
        const item = $(this).find('.ingredient-item-input').val();
        const amount = parseInt($(this).find('.ingredient-amount-input').val());
        
        if (item && amount) {
            ingredients.push({ item, amount });
        }
    });
    return ingredients;
}

// =====================================================
// MENU IMAGES TAB
// =====================================================
function loadMenuTab() {
    $.post('https://fx-restaurant/getMenuImages', JSON.stringify({}), (data) => {
        const preview = $('#menuPreview');
        preview.empty();
        
        if (!data.images || data.images.length === 0) {
            preview.append(`
                <div class="empty-state">
                    <i class="fas fa-image"></i>
                    <p>Geen menu afbeelding ingesteld</p>
                    <small>Gebruik https://ibb.co/ of imgur.com</small>
                </div>
            `);
            return;
        }
        
        const image = data.images[0];
        preview.append(`<img src="${image.image_url}" alt="${image.title}">`);
    });
}

$('#updateMenuImageBtn').click(() => {
    $.post('https://fx-restaurant/updateMenuImage', JSON.stringify({}), (response) => {
        if (response.success) {
            loadMenuTab();
        }
    });
});

// =====================================================
// OFFLINE SHOP TAB
// =====================================================
function loadShopTab() {
    $.post('https://fx-restaurant/getShopInventory', JSON.stringify({}), (data) => {
        const tbody = $('#shopTableBody');
        tbody.empty();
        
        if (!data.inventory || data.inventory.length === 0) {
            tbody.append(`
                <tr class="empty-state">
                    <td colspan="5">Geen items in de shop</td>
                </tr>
            `);
            return;
        }
        
        data.inventory.forEach(item => {
            tbody.append(`
                <tr>
                    <td>${item.label}</td>
                    <td>$${item.price}</td>
                    <td>${item.stock}</td>
                    <td>
                        <label class="toggle-switch">
                            <input type="checkbox" ${item.active ? 'checked' : ''} 
                                   onchange="toggleShopItem(${item.id}, this.checked)">
                            <span class="toggle-slider"></span>
                        </label>
                    </td>
                    <td>
                        <button class="btn btn-primary btn-small edit-shop-item" 
                                data-id="${item.id}" 
                                data-price="${item.price}" 
                                data-stock="${item.stock}">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-danger btn-small remove-shop-item" data-id="${item.id}">
                            <i class="fas fa-trash"></i>
                        </button>
                    </td>
                </tr>
            `);
        });
        
        // Add event listeners
        $('.edit-shop-item').click(function() {
            const itemId = $(this).data('id');
            const price = $(this).data('price');
            const stock = $(this).data('stock');
            editShopItem(itemId, price, stock);
        });
        
        $('.remove-shop-item').click(function() {
            const itemId = $(this).data('id');
            removeShopItem(itemId);
        });
    });
}

$('#addShopItemBtn').click(() => {
    $.post('https://fx-restaurant/addShopItem', JSON.stringify({}), (response) => {
        if (response.success) {
            loadShopTab();
        }
    });
});

function editShopItem(itemId, currentPrice, currentStock) {
    // This would open an input dialog via NUI callback
    // For now, just trigger the callback
    $.post('https://fx-restaurant/updateShopItem', JSON.stringify({ 
        itemId, 
        price: currentPrice, 
        stock: currentStock 
    }), (response) => {
        if (response.success) {
            loadShopTab();
        }
    });
}

function removeShopItem(itemId) {
    $.post('https://fx-restaurant/removeShopItem', JSON.stringify({ itemId }), (response) => {
        if (response.success) {
            loadShopTab();
        }
    });
}

function toggleShopItem(itemId, active) {
    $.post('https://fx-restaurant/toggleShopItem', JSON.stringify({ itemId, active }), (response) => {
        // Optional: Show feedback
    });
}

// =====================================================
// UTILITY FUNCTIONS
// =====================================================
function formatDate(dateString) {
    if (!dateString) return 'Onbekend';
    const date = new Date(dateString);
    return date.toLocaleDateString('nl-NL');
}

// Prevent default form submission
$('#recipeForm').submit((e) => {
    e.preventDefault();
    saveRecipe();
});
