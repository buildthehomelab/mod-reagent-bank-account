-- Extra items the reagent bank accepts on top of Trade Goods, Gems and profession reagents.
-- item_subclass picks the bank category (Trade Goods subclass id, 11 = Other Trade Goods).
CREATE TABLE IF NOT EXISTS `mod_reagent_bank_account_deposit_inclusions_zz_custom` (
    `item_entry` INT UNSIGNED NOT NULL,
    `item_subclass` INT UNSIGNED NOT NULL DEFAULT 11,
    `comment` VARCHAR(255) NULL DEFAULT NULL,
    PRIMARY KEY (`item_entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `mod_reagent_bank_account_deposit_inclusions_zz_custom` (`item_entry`, `item_subclass`, `comment`) VALUES
(18945, 11, 'Dark Iron Residue (Quest class, Thorium Brotherhood turn-in)'),
(15420, 11, 'Ironfeather (Trade Goods with no subtype, owlbeast drop)'),
(9504010, 11, 'Archaeology keystone: Dwarf Rune Stone'),
(9504011, 11, 'Archaeology keystone: Highborne Scroll'),
(9504012, 11, 'Archaeology keystone: Troll Tablet'),
(9504014, 11, 'Archaeology keystone: Draenei Tome'),
(9504015, 11, 'Archaeology keystone: Orc Blood Text'),
(9504016, 11, 'Archaeology keystone: Nerubian Obelisk'),
(9504017, 11, 'Archaeology keystone: Vrykul Rune Stick');
