-- =====================================================
-- FX-RESTAURANT | COMPLETE DATABASE SCHEMA
-- =====================================================
-- Volledige database structuur voor alle features
-- =====================================================

-- =====================================================
-- RECIPES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `restaurant_recipes` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restaurant` VARCHAR(50) NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `description` TEXT,
    `image` VARCHAR(255) DEFAULT 'default.png',
    `animation` VARCHAR(50) DEFAULT 'none',
    `station` VARCHAR(50) NOT NULL,
    `type` ENUM('food', 'drink') NOT NULL DEFAULT 'food',
    `price` INT NOT NULL CHECK (`price` > 0),
    `ingredients` JSON NOT NULL,
    `active` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_restaurant` (`restaurant`),
    INDEX `idx_active` (`active`),
    INDEX `idx_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- ORDERS TABLE (Dine-in, Takeaway, Delivery)
-- =====================================================
CREATE TABLE IF NOT EXISTS `restaurant_orders` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restaurant` VARCHAR(50) NOT NULL,
    `order_number` VARCHAR(20) UNIQUE NOT NULL,
    `customer_identifier` VARCHAR(60) NOT NULL,
    `customer_name` VARCHAR(100),
    `items` JSON NOT NULL,
    `total_price` INT NOT NULL,
    `status` ENUM('pending', 'preparing', 'ready', 'completed', 'cancelled') DEFAULT 'pending',
    `order_type` ENUM('dine_in', 'takeaway', 'delivery') DEFAULT 'dine_in',
    `delivery_location` VARCHAR(255),
    `notes` TEXT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL,
    
    INDEX `idx_restaurant` (`restaurant`),
    INDEX `idx_customer` (`customer_identifier`),
    INDEX `idx_status` (`status`),
    INDEX `idx_order_number` (`order_number`),
    INDEX `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- INVOICES TABLE (Voor serving trays)
-- =====================================================
CREATE TABLE IF NOT EXISTS `restaurant_invoices` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restaurant` VARCHAR(50) NOT NULL,
    `invoice_number` VARCHAR(20) UNIQUE NOT NULL,
    `issuer_identifier` VARCHAR(60) NOT NULL,
    `issuer_name` VARCHAR(100),
    `recipient_identifier` VARCHAR(60) NOT NULL,
    `recipient_name` VARCHAR(100),
    `items` JSON NOT NULL,
    `amount` INT NOT NULL,
    `status` ENUM('pending', 'paid', 'cancelled') DEFAULT 'pending',
    `payment_method` ENUM('cash', 'bank', 'card') DEFAULT 'cash',
    `tray_id` INT,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `paid_at` TIMESTAMP NULL,
    
    INDEX `idx_restaurant` (`restaurant`),
    INDEX `idx_invoice_number` (`invoice_number`),
    INDEX `idx_issuer` (`issuer_identifier`),
    INDEX `idx_recipient` (`recipient_identifier`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- OFFLINE SHOP INVENTORY
-- =====================================================
CREATE TABLE IF NOT EXISTS `restaurant_shop_inventory` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restaurant` VARCHAR(50) NOT NULL,
    `item` VARCHAR(50) NOT NULL,
    `label` VARCHAR(100) NOT NULL,
    `stock` INT NOT NULL DEFAULT 0,
    `price` INT NOT NULL,
    `active` TINYINT(1) DEFAULT 1,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    UNIQUE KEY `unique_restaurant_item` (`restaurant`, `item`),
    INDEX `idx_restaurant` (`restaurant`),
    INDEX `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- EMPLOYEES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `restaurant_employees` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restaurant` VARCHAR(50) NOT NULL,
    `identifier` VARCHAR(60) NOT NULL,
    `name` VARCHAR(100),
    `grade` INT DEFAULT 0,
    `hired_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE KEY `unique_restaurant_employee` (`restaurant`, `identifier`),
    INDEX `idx_restaurant` (`restaurant`),
    INDEX `idx_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- DELIVERY MISSIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `restaurant_deliveries` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restaurant` VARCHAR(50) NOT NULL,
    `delivery_number` VARCHAR(20) UNIQUE NOT NULL,
    `driver_identifier` VARCHAR(60) NOT NULL,
    `driver_name` VARCHAR(100),
    `items` JSON NOT NULL,
    `location` VARCHAR(255) NOT NULL,
    `coords` JSON NOT NULL,
    `payment` INT NOT NULL,
    `status` ENUM('assigned', 'preparing', 'in_transit', 'delivered', 'failed') DEFAULT 'assigned',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL,
    
    INDEX `idx_restaurant` (`restaurant`),
    INDEX `idx_driver` (`driver_identifier`),
    INDEX `idx_status` (`status`),
    INDEX `idx_delivery_number` (`delivery_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- MUSIC QUEUE TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `restaurant_music` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restaurant` VARCHAR(50) NOT NULL,
    `url` VARCHAR(500) NOT NULL,
    `title` VARCHAR(200),
    `volume` INT DEFAULT 50,
    `radius` INT DEFAULT 30,
    `played_by` VARCHAR(60),
    `playing` TINYINT(1) DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX `idx_restaurant` (`restaurant`),
    INDEX `idx_playing` (`playing`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- PROPS TABLE (Spawned props)
-- =====================================================
CREATE TABLE IF NOT EXISTS `restaurant_props` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restaurant` VARCHAR(50) NOT NULL,
    `model` VARCHAR(100) NOT NULL,
    `coords` JSON NOT NULL,
    `heading` FLOAT DEFAULT 0.0,
    `spawned_by` VARCHAR(60),
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX `idx_restaurant` (`restaurant`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- STATISTICS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `restaurant_stats` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restaurant` VARCHAR(50) NOT NULL,
    `stat_date` DATE NOT NULL,
    `total_orders` INT DEFAULT 0,
    `total_revenue` INT DEFAULT 0,
    `total_deliveries` INT DEFAULT 0,
    `popular_item` VARCHAR(50),
    `busiest_hour` INT,
    
    UNIQUE KEY `unique_restaurant_date` (`restaurant`, `stat_date`),
    INDEX `idx_restaurant` (`restaurant`),
    INDEX `idx_date` (`stat_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- MENU IMAGES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS `restaurant_menu_images` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `restaurant` VARCHAR(50) NOT NULL,
    `image_url` VARCHAR(500) NOT NULL,
    `title` VARCHAR(100),
    `active` TINYINT(1) DEFAULT 1,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX `idx_restaurant` (`restaurant`),
    INDEX `idx_active` (`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- EXAMPLE DATA
-- =====================================================

-- Default restaurant setup
INSERT INTO `restaurant_recipes` 
(`restaurant`, `name`, `description`, `image`, `animation`, `station`, `type`, `price`, `ingredients`, `active`) 
VALUES
('default', 'Klassieke Burger', 'Heerlijke burger met verse ingrediënten', 'https://i.ibb.co/burger.png', 'grill_flip', 'grill', 'food', 150, 
    JSON_ARRAY(
        JSON_OBJECT('item', 'cutted_meat', 'amount', 2),
        JSON_OBJECT('item', 'cutted_lettuce', 'amount', 1),
        JSON_OBJECT('item', 'cutted_tomato', 'amount', 1)
    ), 1),

('default', 'Frisse Salade', 'Gezonde groene salade', 'https://i.ibb.co/salad.png', 'none', 'preparation', 'food', 80,
    JSON_ARRAY(
        JSON_OBJECT('item', 'cutted_lettuce', 'amount', 2),
        JSON_OBJECT('item', 'cutted_cucumber', 'amount', 1),
        JSON_OBJECT('item', 'cutted_tomato', 'amount', 1)
    ), 1),

('default', 'Koffie', 'Sterke espresso', 'https://i.ibb.co/coffee.png', 'pour', 'drinks', 'drink', 35,
    JSON_ARRAY(
        JSON_OBJECT('item', 'coffee_beans', 'amount', 1)
    ), 1);

-- Default menu image
INSERT INTO `restaurant_menu_images` (`restaurant`, `image_url`, `title`, `active`)
VALUES ('default', 'https://i.ibb.co/menu.png', 'Default Restaurant Menu', 1);

-- Example offline shop items
INSERT INTO `restaurant_shop_inventory` (`restaurant`, `item`, `label`, `stock`, `price`, `active`)
VALUES 
('default', 'burger', 'Burger', 50, 150, 1),
('default', 'fries', 'Friet', 50, 50, 1),
('default', 'cola', 'Cola', 100, 25, 1);

-- =====================================================
-- TRIGGERS (Auto-increment order/delivery numbers)
-- =====================================================

DELIMITER $$

CREATE TRIGGER `before_insert_order` 
BEFORE INSERT ON `restaurant_orders`
FOR EACH ROW
BEGIN
    IF NEW.order_number IS NULL OR NEW.order_number = '' THEN
        SET NEW.order_number = CONCAT('ORD-', LPAD(FLOOR(RAND() * 999999), 6, '0'));
    END IF;
END$$

CREATE TRIGGER `before_insert_delivery` 
BEFORE INSERT ON `restaurant_deliveries`
FOR EACH ROW
BEGIN
    IF NEW.delivery_number IS NULL OR NEW.delivery_number = '' THEN
        SET NEW.delivery_number = CONCAT('DEL-', LPAD(FLOOR(RAND() * 999999), 6, '0'));
    END IF;
END$$

CREATE TRIGGER `before_insert_invoice` 
BEFORE INSERT ON `restaurant_invoices`
FOR EACH ROW
BEGIN
    IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
        SET NEW.invoice_number = CONCAT('INV-', LPAD(FLOOR(RAND() * 999999), 6, '0'));
    END IF;
END$$

DELIMITER ;

-- =====================================================
-- VIEWS (Voor statistieken)
-- =====================================================

CREATE OR REPLACE VIEW `v_restaurant_daily_stats` AS
SELECT 
    `restaurant`,
    DATE(`created_at`) as `date`,
    COUNT(*) as `total_orders`,
    SUM(`total_price`) as `revenue`,
    AVG(`total_price`) as `avg_order_value`
FROM `restaurant_orders`
WHERE `status` = 'completed'
GROUP BY `restaurant`, DATE(`created_at`);

CREATE OR REPLACE VIEW `v_popular_items` AS
SELECT 
    r.`restaurant`,
    JSON_UNQUOTE(JSON_EXTRACT(item.value, '$.item')) as `item_name`,
    COUNT(*) as `times_ordered`
FROM `restaurant_orders` r
CROSS JOIN JSON_TABLE(
    r.`items`,
    '$[*]' COLUMNS(value JSON PATH '$')
) as item
WHERE r.`status` = 'completed'
GROUP BY r.`restaurant`, `item_name`
ORDER BY `times_ordered` DESC;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

ALTER TABLE `restaurant_orders` ADD INDEX `idx_created_date` (DATE(`created_at`));
ALTER TABLE `restaurant_deliveries` ADD INDEX `idx_created_date` (DATE(`created_at`));

-- =====================================================
-- CLEANUP PROCEDURES (Voor development)
-- =====================================================

DELIMITER $$

CREATE PROCEDURE `sp_cleanup_old_orders`()
BEGIN
    DELETE FROM `restaurant_orders` 
    WHERE `completed_at` < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE PROCEDURE `sp_cleanup_old_deliveries`()
BEGIN
    DELETE FROM `restaurant_deliveries` 
    WHERE `completed_at` < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

CREATE PROCEDURE `sp_reset_restaurant`(IN restaurant_id VARCHAR(50))
BEGIN
    DELETE FROM `restaurant_orders` WHERE `restaurant` = restaurant_id;
    DELETE FROM `restaurant_deliveries` WHERE `restaurant` = restaurant_id;
    DELETE FROM `restaurant_invoices` WHERE `restaurant` = restaurant_id;
    DELETE FROM `restaurant_shop_inventory` WHERE `restaurant` = restaurant_id;
    UPDATE `restaurant_stats` SET 
        `total_orders` = 0, 
        `total_revenue` = 0,
        `total_deliveries` = 0
    WHERE `restaurant` = restaurant_id;
END$$

DELIMITER ;

-- =====================================================
-- DONE!
-- =====================================================
-- Run: SELECT 'Database setup complete!' as status;
