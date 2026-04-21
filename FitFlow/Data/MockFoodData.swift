//
//  MockFoodData.swift
//  FitFlow
//
//  Global mock foods for all users. Not scoped to any user; new users can
//  select from this library when logging meals.
//

import SwiftUI

enum MockFoodData {

    /// Global food library. Shown in Add Food as "Food library" for every user.
    /// Nutrition values are per 100g; default quantity is 100g.
    static let globalFoods: [AddFoodItem] = [
        // Breakfast & dairy
        AddFoodItem(name: "Greek Yogurt (Plain)", brand: "Generic", quantityGrams: 150, kcalPer100g: 67, proteinPer100g: 10, carbsPer100g: 4, fatPer100g: 0.27, imageSystemName: "cup.and.saucer.fill"),
        AddFoodItem(name: "Greek Yogurt with Honey", brand: "Generic", quantityGrams: 170, kcalPer100g: 105, proteinPer100g: 8, carbsPer100g: 14, fatPer100g: 2.5, imageSystemName: "cup.and.saucer.fill"),
        AddFoodItem(name: "Oatmeal with Berries", brand: "Generic", quantityGrams: 200, kcalPer100g: 95, proteinPer100g: 3.4, carbsPer100g: 17, fatPer100g: 1.5, imageSystemName: "cup.and.saucer.fill"),
        AddFoodItem(name: "Scrambled Eggs", brand: "Generic", quantityGrams: 150, kcalPer100g: 148, proteinPer100g: 10, carbsPer100g: 1.6, fatPer100g: 11, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Whole Milk", brand: "Generic", quantityGrams: 250, kcalPer100g: 61, proteinPer100g: 3.2, carbsPer100g: 4.8, fatPer100g: 3.3, imageSystemName: "cup.and.saucer.fill"),
        AddFoodItem(name: "Skim Milk", brand: "Generic", quantityGrams: 250, kcalPer100g: 34, proteinPer100g: 3.4, carbsPer100g: 5, fatPer100g: 0.1, imageSystemName: "cup.and.saucer.fill"),
        AddFoodItem(name: "Cottage Cheese", brand: "Generic", quantityGrams: 150, kcalPer100g: 98, proteinPer100g: 11, carbsPer100g: 3.4, fatPer100g: 4.3, imageSystemName: "cup.and.saucer.fill"),
        AddFoodItem(name: "Granola", brand: "Generic", quantityGrams: 50, kcalPer100g: 471, proteinPer100g: 10, carbsPer100g: 64, fatPer100g: 20, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Whole Grain Bread", brand: "Generic", quantityGrams: 60, kcalPer100g: 247, proteinPer100g: 10.7, carbsPer100g: 41.3, fatPer100g: 3.4, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Banana", brand: "Fresh", quantityGrams: 120, kcalPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 22.8, fatPer100g: 0.3, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Apple", brand: "Fresh", quantityGrams: 180, kcalPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 13.8, fatPer100g: 0.2, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Orange", brand: "Fresh", quantityGrams: 130, kcalPer100g: 47, proteinPer100g: 0.9, carbsPer100g: 11.8, fatPer100g: 0.1, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Strawberries", brand: "Fresh", quantityGrams: 150, kcalPer100g: 32, proteinPer100g: 0.7, carbsPer100g: 7.7, fatPer100g: 0.3, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Blueberries", brand: "Fresh", quantityGrams: 150, kcalPer100g: 57, proteinPer100g: 0.7, carbsPer100g: 14.5, fatPer100g: 0.3, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Avocado", brand: "Fresh", quantityGrams: 100, kcalPer100g: 160, proteinPer100g: 2, carbsPer100g: 8.5, fatPer100g: 15, imageSystemName: "leaf.fill"),
        // Protein
        AddFoodItem(name: "Chicken Breast (Grilled)", brand: "Generic", quantityGrams: 200, kcalPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Chicken Thigh (Grilled)", brand: "Generic", quantityGrams: 150, kcalPer100g: 209, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 10.9, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Salmon (Baked)", brand: "Generic", quantityGrams: 150, kcalPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Tuna (Canned in Water)", brand: "Generic", quantityGrams: 100, kcalPer100g: 116, proteinPer100g: 26, carbsPer100g: 0, fatPer100g: 0.8, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Ground Beef (85% Lean)", brand: "Generic", quantityGrams: 150, kcalPer100g: 215, proteinPer100g: 24, carbsPer100g: 0, fatPer100g: 13, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Turkey Breast", brand: "Generic", quantityGrams: 150, kcalPer100g: 135, proteinPer100g: 30, carbsPer100g: 0, fatPer100g: 0.7, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Eggs (Whole, Cooked)", brand: "Generic", quantityGrams: 100, kcalPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Tofu (Firm)", brand: "Generic", quantityGrams: 150, kcalPer100g: 76, proteinPer100g: 8, carbsPer100g: 1.9, fatPer100g: 4.8, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Black Beans (Cooked)", brand: "Generic", quantityGrams: 150, kcalPer100g: 132, proteinPer100g: 8.9, carbsPer100g: 23.7, fatPer100g: 0.5, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Lentils (Cooked)", brand: "Generic", quantityGrams: 150, kcalPer100g: 116, proteinPer100g: 9, carbsPer100g: 20, fatPer100g: 0.4, imageSystemName: "leaf.fill"),
        // Carbs & grains
        AddFoodItem(name: "Brown Rice (Cooked)", brand: "Generic", quantityGrams: 150, kcalPer100g: 112, proteinPer100g: 2.6, carbsPer100g: 23.5, fatPer100g: 0.9, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "White Rice (Cooked)", brand: "Generic", quantityGrams: 150, kcalPer100g: 130, proteinPer100g: 2.4, carbsPer100g: 28.2, fatPer100g: 0.3, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Quinoa (Cooked)", brand: "Generic", quantityGrams: 150, kcalPer100g: 120, proteinPer100g: 4.4, carbsPer100g: 21.3, fatPer100g: 1.9, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Sweet Potato (Baked)", brand: "Generic", quantityGrams: 200, kcalPer100g: 90, proteinPer100g: 2, carbsPer100g: 20.7, fatPer100g: 0.1, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Whole Wheat Pasta (Cooked)", brand: "Generic", quantityGrams: 150, kcalPer100g: 124, proteinPer100g: 5.3, carbsPer100g: 26.5, fatPer100g: 0.5, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Potato (Baked)", brand: "Generic", quantityGrams: 170, kcalPer100g: 93, proteinPer100g: 2.5, carbsPer100g: 21.1, fatPer100g: 0.1, imageSystemName: "leaf.fill"),
        // Vegetables
        AddFoodItem(name: "Broccoli (Steamed)", brand: "Generic", quantityGrams: 150, kcalPer100g: 35, proteinPer100g: 2.4, carbsPer100g: 7.2, fatPer100g: 0.4, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Spinach (Raw)", brand: "Generic", quantityGrams: 80, kcalPer100g: 23, proteinPer100g: 2.9, carbsPer100g: 3.6, fatPer100g: 0.4, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Mixed Salad Greens", brand: "Generic", quantityGrams: 80, kcalPer100g: 15, proteinPer100g: 1.4, carbsPer100g: 2.9, fatPer100g: 0.2, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Carrots (Raw)", brand: "Generic", quantityGrams: 100, kcalPer100g: 41, proteinPer100g: 0.9, carbsPer100g: 9.6, fatPer100g: 0.2, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Tomato", brand: "Fresh", quantityGrams: 120, kcalPer100g: 18, proteinPer100g: 0.9, carbsPer100g: 3.9, fatPer100g: 0.2, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Cucumber", brand: "Fresh", quantityGrams: 100, kcalPer100g: 15, proteinPer100g: 0.7, carbsPer100g: 3.6, fatPer100g: 0.1, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Bell Pepper", brand: "Fresh", quantityGrams: 120, kcalPer100g: 31, proteinPer100g: 1, carbsPer100g: 6, fatPer100g: 0.3, imageSystemName: "leaf.fill"),
        // Snacks & other
        AddFoodItem(name: "Almonds", brand: "Generic", quantityGrams: 30, kcalPer100g: 579, proteinPer100g: 21, carbsPer100g: 22, fatPer100g: 50, imageSystemName: "leaf.fill"),
        AddFoodItem(name: "Peanut Butter", brand: "Generic", quantityGrams: 32, kcalPer100g: 588, proteinPer100g: 25, carbsPer100g: 20, fatPer100g: 50, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Protein Bar", brand: "Generic", quantityGrams: 60, kcalPer100g: 400, proteinPer100g: 25, carbsPer100g: 45, fatPer100g: 10, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Hummus", brand: "Generic", quantityGrams: 50, kcalPer100g: 166, proteinPer100g: 7.9, carbsPer100g: 14.3, fatPer100g: 9.6, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Greek Yogurt Bowl with Granola", brand: "Generic", quantityGrams: 200, kcalPer100g: 120, proteinPer100g: 7, carbsPer100g: 18, fatPer100g: 3, imageSystemName: "cup.and.saucer.fill"),
        AddFoodItem(name: "Smoothie (Berry)", brand: "Generic", quantityGrams: 300, kcalPer100g: 50, proteinPer100g: 1.2, carbsPer100g: 11, fatPer100g: 0.2, imageSystemName: "cup.and.saucer.fill"),
        AddFoodItem(name: "Coffee with Milk", brand: "Generic", quantityGrams: 250, kcalPer100g: 20, proteinPer100g: 1.2, carbsPer100g: 1.8, fatPer100g: 1, imageSystemName: "cup.and.saucer.fill"),
        AddFoodItem(name: "Green Salad with Chicken", brand: "Generic", quantityGrams: 300, kcalPer100g: 75, proteinPer100g: 8, carbsPer100g: 4, fatPer100g: 3, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Turkey Sandwich", brand: "Generic", quantityGrams: 200, kcalPer100g: 180, proteinPer100g: 12, carbsPer100g: 22, fatPer100g: 5, imageSystemName: "fork.knife"),
        AddFoodItem(name: "Vegetable Stir Fry", brand: "Generic", quantityGrams: 250, kcalPer100g: 65, proteinPer100g: 3, carbsPer100g: 8, fatPer100g: 2.5, imageSystemName: "fork.knife"),
    ]
}
