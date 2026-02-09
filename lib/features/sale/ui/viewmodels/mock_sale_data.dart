import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';

/// Mock data for testing the sale UI
class MockSaleData {
  static final List<MenuCategory> categories = [
    const MenuCategory(id: 'coffee', name: 'Coffee'),
    const MenuCategory(id: 'milk_tea', name: 'Milk Tea'),
    const MenuCategory(id: 'matcha', name: 'Matcha'),
    const MenuCategory(id: 'refreshing', name: 'Refreshing Drink'),
  ];

  static final List<MenuItem> menuItems = [
    const MenuItem(
      id: 'matcha_latte_1',
      name: 'Matcha Latte',
      categoryId: 'matcha',
      price: 3.5,
      description: 'A refreshing drink made of fresh lemon',
      modifierGroupIds: ['cup_size', 'sugar_level', 'toppings'],
    ),
    const MenuItem(
      id: 'lemon_tea_1',
      name: 'Lemon Tea',
      categoryId: 'refreshing',
      price: 7.0,
      description: 'Fresh lemon tea',
      modifierGroupIds: ['cup_size', 'sugar_level', 'toppings'],
    ),
    const MenuItem(
      id: 'coffee_latte_1',
      name: 'Coffee Latte',
      categoryId: 'coffee',
      price: 4.0,
      description: 'Classic coffee latte',
      modifierGroupIds: ['cup_size', 'sugar_level'],
    ),
    const MenuItem(
      id: 'milk_tea_1',
      name: 'Classic Milk Tea',
      categoryId: 'milk_tea',
      price: 4.5,
      description: 'Traditional milk tea',
      modifierGroupIds: ['cup_size', 'sugar_level', 'toppings'],
    ),
    const MenuItem(
      id: 'matcha_latte_2',
      name: 'Iced Matcha',
      categoryId: 'matcha',
      price: 4.0,
      description: 'Cold matcha drink',
      modifierGroupIds: ['cup_size', 'sugar_level'],
    ),
    const MenuItem(
      id: 'coffee_americano',
      name: 'Americano',
      categoryId: 'coffee',
      price: 3.0,
      description: 'Classic americano',
      modifierGroupIds: ['cup_size', 'sugar_level'],
    ),
    const MenuItem(
      id: 'thai_milk_tea',
      name: 'Thai Milk Tea',
      categoryId: 'milk_tea',
      price: 5.0,
      description: 'Sweet Thai milk tea',
      modifierGroupIds: ['cup_size', 'sugar_level', 'toppings'],
    ),
    const MenuItem(
      id: 'green_tea',
      name: 'Green Tea',
      categoryId: 'refreshing',
      price: 3.0,
      description: 'Fresh green tea',
      modifierGroupIds: ['cup_size', 'sugar_level'],
    ),
  ];

  static final Map<String, ModifierGroup> modifierGroups = {
    'cup_size': const ModifierGroup(
      id: 'cup_size',
      name: 'Cup Size',
      selectionType: 'single',
      pricingBehavior: 'addon',
      isRequired: true,
      options: [
        ModifierOption(id: 'small', name: 'Small', price: 0),
        ModifierOption(id: 'medium', name: 'Medium', price: 2.0),
        ModifierOption(id: 'large', name: 'Large', price: 4.75),
      ],
    ),
    'sugar_level': const ModifierGroup(
      id: 'sugar_level',
      name: 'Sugar Level',
      selectionType: 'single',
      pricingBehavior: 'none',
      isRequired: true,
      options: [
        ModifierOption(id: '0', name: '0%', price: 0),
        ModifierOption(id: '50', name: '50%', price: 0),
        ModifierOption(id: '75', name: '75%', price: 0),
        ModifierOption(id: '100', name: '100%', price: 0),
      ],
    ),
    'toppings': const ModifierGroup(
      id: 'toppings',
      name: 'Toppings',
      selectionType: 'multiple',
      pricingBehavior: 'addon',
      isRequired: false,
      options: [
        ModifierOption(id: 'boba', name: 'Boba', price: 0.5),
        ModifierOption(id: 'jelly', name: 'Jelly', price: 0.5),
        ModifierOption(id: 'pudding', name: 'Pudding', price: 0.75),
        ModifierOption(id: 'extra_ice', name: 'Extra Ice', price: 0),
      ],
    ),
  };
}
