//
//  AddFoodView.swift
//  FitFlow
//
//  Add Food: search, filter tabs, search results, selected food detail, Save to meal.
//  Now persists food to Core Data via MealViewModel.
//

import SwiftUI
import CoreData

enum AddFoodMealType: String, CaseIterable, Hashable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
}

enum AddFoodFilter: String, CaseIterable {
    case recent = "Recent"
    case myFoodsAndRecipes = "My Foods & Recipes"
    case foodLibrary = "Food library"
}

struct AddFoodItem: Identifiable {
    let id: UUID
    let name: String
    let brand: String
    let quantityGrams: Int
    let kcalPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let imageSystemName: String
    let coreDataID: NSManagedObjectID?
    var kcalForQuantity: Int { Int(round(Double(quantityGrams) / 100 * kcalPer100g)) }

    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        quantityGrams: Int,
        kcalPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        imageSystemName: String = "fork.knife",
        coreDataID: NSManagedObjectID? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.quantityGrams = quantityGrams
        self.kcalPer100g = kcalPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.imageSystemName = imageSystemName
        self.coreDataID = coreDataID
    }

    static func from(_ item: CDFoodItem) -> AddFoodItem {
        AddFoodItem(
            id: item.id ?? UUID(),
            name: item.name ?? "Unknown",
            brand: item.brand ?? "Generic",
            quantityGrams: Int(item.quantityGrams),
            kcalPer100g: item.caloriesPer100g,
            proteinPer100g: item.proteinPer100g,
            carbsPer100g: item.carbsPer100g,
            fatPer100g: item.fatPer100g,
            imageSystemName: "fork.knife",
            coreDataID: item.objectID
        )
    }
}

struct AddFoodView: View {
    let mealType: AddFoodMealType
    let targetDate: Date
    var mealVM: MealViewModel?
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var selectedFilter: AddFoodFilter = .recent
    @State private var selectedFood: AddFoodItem?
    @State private var quantityGrams: Double = 150
    @State private var showCreateNewFood = false
    @State private var createFoodName = ""
    @State private var createFoodBrand = ""
    @State private var createFoodKcalPer100 = ""
    @State private var createFoodProteinPer100 = ""
    @State private var createFoodCarbsPer100 = ""
    @State private var createFoodFatPer100 = ""
    @State private var useGrams = true
    @State private var savedFoodToDeleteID: NSManagedObjectID?
    @State private var showDeleteSavedFoodAlert = false
    @FocusState private var quantityFocused: Bool

    init(mealType: AddFoodMealType, targetDate: Date = Date(), mealVM: MealViewModel? = nil, onSave: (() -> Void)? = nil) {
        self.mealType = mealType
        self.targetDate = targetDate
        self.mealVM = mealVM
        self.onSave = onSave
    }

    private let maxQuantityGrams: Double = 500
    private let minQuantityGrams: Double = 1

    private var filteredFoods: [AddFoodItem] {
        let baseList: [AddFoodItem]
        switch selectedFilter {
        case .recent:
            let vm = mealVM ?? MealViewModel(context: viewContext)
            baseList = vm.recentFoodItems(limit: 30).map(AddFoodItem.from)
        case .myFoodsAndRecipes:
            let vm = mealVM ?? MealViewModel(context: viewContext)
            baseList = vm.frequentFoodItems(limit: 30).map(AddFoodItem.from)
        case .foodLibrary:
            baseList = MockFoodData.globalFoods
        }
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return baseList }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return baseList.filter {
            $0.name.localizedCaseInsensitiveContains(query) || $0.brand.localizedCaseInsensitiveContains(query)
        }
    }

    private var resultsSectionTitle: String {
        switch selectedFilter {
        case .recent: return "RECENT"
        case .myFoodsAndRecipes: return "MY FOODS & RECIPES"
        case .foodLibrary: return "FOOD LIBRARY"
        }
    }

    /// Base quantity always stored in grams internally to avoid conversion drift
    private var scaledQuantity: Double { quantityGrams }

    private var quantityUnitLabel: String { useGrams ? "g" : "oz" }

    private var quantityInDisplayUnit: Double {
        useGrams ? quantityGrams : quantityGrams / 28.35
    }

    private var displayUnitMin: Double { useGrams ? minQuantityGrams : minQuantityGrams / 28.35 }
    private var displayUnitMax: Double { useGrams ? maxQuantityGrams : maxQuantityGrams / 28.35 }

    private var currentKcal: Int {
        guard let f = selectedFood else { return 0 }
        return Int(round(f.kcalPer100g * (quantityGrams / 100)))
    }

    private var currentProtein: Double { selectedFood.map { $0.proteinPer100g * (quantityGrams / 100) } ?? 0 }
    private var currentCarbs: Double { selectedFood.map { $0.carbsPer100g * (quantityGrams / 100) } ?? 0 }
    private var currentFat: Double { selectedFood.map { $0.fatPer100g * (quantityGrams / 100) } ?? 0 }

    var body: some View {
        ZStack {
            AppColors.darkBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    searchBar
                    filterTabs
                    sectionHeader(resultsSectionTitle)
                    searchResultsList
                    if selectedFood != nil { selectedFoodSection }
                    Spacer(minLength: 100)
                }
            }
            VStack { Spacer(); saveButton }
        }
        .navigationTitle("Add Food")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(AppColors.darkBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreateNewFood = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(AppColors.darkText)
                }
                .accessibilityLabel("Create new food")
            }
        }
        .sheet(isPresented: $showCreateNewFood) {
            createNewFoodSheet
        }
        .alert("Delete saved food?", isPresented: $showDeleteSavedFoodAlert) {
            Button("Delete", role: .destructive) {
                if let id = savedFoodToDeleteID {
                    let vm = mealVM ?? MealViewModel(context: viewContext)
                    vm.deleteSavedFoodItem(with: id)
                }
                savedFoodToDeleteID = nil
            }
            Button("Cancel", role: .cancel) {
                savedFoodToDeleteID = nil
            }
        } message: {
            Text("This will remove this food from your saved foods.")
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var createNewFoodSheet: some View {
        NavigationStack {
            ZStack {
                AppColors.darkBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(AppTypography.caption()).foregroundStyle(AppColors.darkTextSecondary)
                            TextField("e.g. Chicken Breast", text: $createFoodName)
                                .font(AppTypography.body()).foregroundStyle(AppColors.darkText)
                                .padding(AppLayout.cardPadding)
                                .background(AppColors.darkSurface)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Brand (optional)")
                                .font(AppTypography.caption()).foregroundStyle(AppColors.darkTextSecondary)
                            TextField("e.g. Generic", text: $createFoodBrand)
                                .font(AppTypography.body()).foregroundStyle(AppColors.darkText)
                                .padding(AppLayout.cardPadding)
                                .background(AppColors.darkSurface)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                        }
                        Text("Nutrition per 100g")
                            .font(AppTypography.caption()).foregroundStyle(AppColors.darkTextSecondary)
                            .padding(.top, 8)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calories (kcal)")
                                .font(AppTypography.caption2()).foregroundStyle(AppColors.darkTextSecondary)
                            TextField("0", text: $createFoodKcalPer100)
                                .font(AppTypography.body()).foregroundStyle(AppColors.darkText)
                                .keyboardType(.decimalPad)
                                .padding(AppLayout.cardPadding)
                                .background(AppColors.darkSurface)
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                        }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Protein (g)")
                                    .font(AppTypography.caption2()).foregroundStyle(AppColors.darkTextSecondary)
                                TextField("0", text: $createFoodProteinPer100)
                                    .font(AppTypography.body()).foregroundStyle(AppColors.darkText)
                                    .keyboardType(.decimalPad)
                                    .padding(AppLayout.cardPadding)
                                    .background(AppColors.darkSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Carbs (g)")
                                    .font(AppTypography.caption2()).foregroundStyle(AppColors.darkTextSecondary)
                                TextField("0", text: $createFoodCarbsPer100)
                                    .font(AppTypography.body()).foregroundStyle(AppColors.darkText)
                                    .keyboardType(.decimalPad)
                                    .padding(AppLayout.cardPadding)
                                    .background(AppColors.darkSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Fat (g)")
                                    .font(AppTypography.caption2()).foregroundStyle(AppColors.darkTextSecondary)
                                TextField("0", text: $createFoodFatPer100)
                                    .font(AppTypography.body()).foregroundStyle(AppColors.darkText)
                                    .keyboardType(.decimalPad)
                                    .padding(AppLayout.cardPadding)
                                    .background(AppColors.darkSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                            }
                        }
                        Button {
                            saveNewFoodAndDismiss()
                        } label: {
                            Text("Create & Add to \(mealType.rawValue)")
                                .font(AppTypography.headline()).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).frame(height: AppLayout.buttonHeight)
                                .background(canCreateNewFood ? AppColors.primaryGreen : AppColors.primaryGreen.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canCreateNewFood)
                        .padding(.top, 16)
                    }
                    .padding(AppLayout.screenPadding)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppColors.darkBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { resetCreateForm(); showCreateNewFood = false }
                        .foregroundStyle(AppColors.primaryGreen)
                }
            }
        }
        .onAppear { resetCreateForm() }
    }

    private var canCreateNewFood: Bool {
        let nameOk = !createFoodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let kcal = Double(createFoodKcalPer100)
        let protein = Double(createFoodProteinPer100)
        let carbs = Double(createFoodCarbsPer100)
        let fat = Double(createFoodFatPer100)
        return nameOk && kcal != nil && (kcal ?? 0) >= 0
            && protein != nil && (protein ?? 0) >= 0
            && carbs != nil && (carbs ?? 0) >= 0
            && fat != nil && (fat ?? 0) >= 0
    }

    private func resetCreateForm() {
        createFoodName = ""
        createFoodBrand = ""
        createFoodKcalPer100 = ""
        createFoodProteinPer100 = ""
        createFoodCarbsPer100 = ""
        createFoodFatPer100 = ""
    }

    private func saveNewFoodAndDismiss() {
        let name = createFoodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty,
              let kcal = Double(createFoodKcalPer100), kcal >= 0,
              let protein = Double(createFoodProteinPer100), protein >= 0,
              let carbs = Double(createFoodCarbsPer100), carbs >= 0,
              let fat = Double(createFoodFatPer100), fat >= 0 else { return }

        let vm = mealVM ?? MealViewModel(context: viewContext)
        guard vm.createFoodItem(
            name: name,
            brand: createFoodBrand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Generic" : createFoodBrand.trimmingCharacters(in: .whitespacesAndNewlines),
            caloriesPer100g: kcal,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat
        ) != nil else { return }
        guard vm.logMeal(
            mealType: mealType.rawValue,
            date: targetDate,
            foodItems: [(
                name: name,
                brand: createFoodBrand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Generic" : createFoodBrand.trimmingCharacters(in: .whitespacesAndNewlines),
                caloriesPer100g: kcal,
                proteinPer100g: protein,
                carbsPer100g: carbs,
                fatPer100g: fat,
                quantityGrams: 100
            )]
        ) else { return }
        resetCreateForm()
        showCreateNewFood = false
        onSave?()
        dismiss()
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppColors.darkTextSecondary)
            TextField("Search food, brand, or restaurant...", text: $searchText)
                .font(AppTypography.body()).foregroundStyle(AppColors.darkText)
        }
        .padding(.horizontal, AppLayout.cardPadding).padding(.vertical, 12)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.top, 8).padding(.bottom, 12)
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AddFoodFilter.allCases, id: \.self) { filter in
                    Button { selectedFilter = filter } label: {
                        Text(filter.rawValue)
                            .font(AppTypography.callout())
                            .foregroundStyle(selectedFilter == filter ? .white : AppColors.darkTextSecondary)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(selectedFilter == filter ? AppColors.primaryGreen : AppColors.darkSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppLayout.screenPadding)
        }
        .padding(.bottom, 12)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.caption2())
            .foregroundStyle(AppColors.darkTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppLayout.screenPadding).padding(.bottom, 8)
    }

    private var searchResultsList: some View {
        VStack(spacing: 0) {
            ForEach(filteredFoods) { food in searchResultRow(food) }
        }
        .padding(.horizontal, AppLayout.screenPadding).padding(.bottom, 16)
    }

    private func searchResultRow(_ food: AddFoodItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle().fill(AppColors.darkSurface).frame(width: 48, height: 48)
                Image(systemName: food.imageSystemName).font(.title2).foregroundStyle(AppColors.primaryGreen)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name).font(AppTypography.title3()).foregroundStyle(AppColors.darkText)
                Text("\(food.brand) • \(food.quantityGrams)g • \(food.kcalForQuantity) kcal")
                    .font(AppTypography.caption2()).foregroundStyle(AppColors.darkTextSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                selectedFood = food
                quantityGrams = Double(food.quantityGrams)
            } label: {
                Image(systemName: "plus").font(.body.weight(.semibold)).foregroundStyle(.white)
                    .frame(width: 36, height: 36).background(AppColors.primaryGreen).clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let id = food.coreDataID, selectedFilter != .foodLibrary {
                Button(role: .destructive) {
                    savedFoodToDeleteID = id
                    showDeleteSavedFoodAlert = true
                } label: {
                    Text("Delete")
                }
            }
        }
    }

    private var selectedFoodSection: some View {
        Group {
            if let food = selectedFood {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(food.name).font(AppTypography.title3()).foregroundStyle(AppColors.darkText)
                        Text("\(currentKcal) kcal total").font(AppTypography.callout()).foregroundStyle(AppColors.primaryGreen)
                    }
                    .padding(.horizontal, AppLayout.screenPadding)
                    unitSelector
                    quantitySection
                    macroCards
                }
                .padding(.bottom, 24)
            }
        }
    }

    private var unitSelector: some View {
        HStack(spacing: 10) {
            ForEach([true, false], id: \.self) { grams in
                Button {
                    if grams != useGrams {
                        useGrams = grams
                    }
                } label: {
                    Text(grams ? "Grams" : "Oz")
                        .font(AppTypography.callout())
                        .foregroundStyle(useGrams == grams ? .white : AppColors.darkTextSecondary)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(useGrams == grams ? AppColors.primaryGreen : AppColors.darkSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quantity").font(AppTypography.callout()).foregroundStyle(AppColors.darkText)
                .padding(.horizontal, AppLayout.screenPadding)
            HStack(spacing: 12) {
                Button {
                    let step = useGrams ? 10.0 : 28.35
        quantityGrams = max(minQuantityGrams, quantityGrams - step)
                } label: {
                    Image(systemName: "minus").font(.body.weight(.semibold)).foregroundStyle(.white)
                        .frame(width: 44, height: 44).background(AppColors.primaryGreen).clipShape(Circle())
                }
                .buttonStyle(.plain)
                TextField("150", value: Binding(
                    get: { quantityInDisplayUnit },
                    set: { newVal in
                        let grams = useGrams ? newVal : newVal * 28.35
                        quantityGrams = min(maxQuantityGrams, max(minQuantityGrams, grams))
                    }
                ), format: .number)
                    .font(AppTypography.title3()).foregroundStyle(AppColors.darkText)
                    .multilineTextAlignment(.center).keyboardType(.decimalPad).focused($quantityFocused)
                    .frame(maxWidth: .infinity)
                Button {
                    let step = useGrams ? 10.0 : 28.35
        quantityGrams = min(maxQuantityGrams, quantityGrams + step)
                } label: {
                    Image(systemName: "plus").font(.body.weight(.semibold)).foregroundStyle(.white)
                        .frame(width: 44, height: 44).background(AppColors.primaryGreen).clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppLayout.screenPadding)
            VStack(alignment: .leading, spacing: 6) {
                Slider(
                    value: Binding(
                        get: { quantityInDisplayUnit },
                        set: { newVal in
                            let grams = useGrams ? newVal : newVal * 28.35
                            quantityGrams = min(maxQuantityGrams, max(minQuantityGrams, grams))
                        }
                    ),
                    in: displayUnitMin...displayUnitMax,
                    step: useGrams ? 5 : 0.5
                )
                    .tint(AppColors.primaryGreen)
                HStack {
                    Text(String(format: useGrams ? "%.0f" : "%.1f", displayUnitMin) + quantityUnitLabel).font(AppTypography.caption2()).foregroundStyle(AppColors.darkTextSecondary)
                    Spacer()
                    Text(String(format: useGrams ? "%.0f" : "%.1f", displayUnitMax) + quantityUnitLabel).font(AppTypography.caption2()).foregroundStyle(AppColors.darkTextSecondary)
                }
            }
            .padding(.horizontal, AppLayout.screenPadding)
        }
    }

    private var macroCards: some View {
        HStack(spacing: 12) {
            macroCard(label: "PROTEIN", value: String(format: "%.0fg", currentProtein))
            macroCard(label: "CARBS", value: String(format: "%.0fg", currentCarbs))
            macroCard(label: "FAT", value: String(format: "%.1fg", currentFat))
        }
        .padding(.horizontal, AppLayout.screenPadding)
    }

    private func macroCard(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(AppTypography.caption2()).foregroundStyle(AppColors.darkTextSecondary)
            Text(value).font(AppTypography.title3()).foregroundStyle(AppColors.darkText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppLayout.cardPadding)
        .background(AppColors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
    }

    private var saveButton: some View {
        Button {
            saveFood()
        } label: {
            Text("Save to \(mealType.rawValue)")
                .font(AppTypography.headline()).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: AppLayout.buttonHeight)
                .background(selectedFood != nil ? AppColors.primaryGreen : AppColors.primaryGreen.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall))
        }
        .buttonStyle(.plain)
        .disabled(selectedFood == nil)
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.top, 16).padding(.bottom, 32)
        .background(AppColors.darkBackground)
    }

    private func saveFood() {
        guard let food = selectedFood, quantityGrams > 0 else { return }

        let vm = mealVM ?? MealViewModel(context: viewContext)
        guard vm.logMeal(
            mealType: mealType.rawValue,
            date: targetDate,
            foodItems: [(
                name: food.name,
                brand: food.brand,
                caloriesPer100g: food.kcalPer100g,
                proteinPer100g: food.proteinPer100g,
                carbsPer100g: food.carbsPer100g,
                fatPer100g: food.fatPer100g,
                quantityGrams: scaledQuantity
            )]
        ) else { return }

        onSave?()
        dismiss()
    }
}

#Preview {
    NavigationStack { AddFoodView(mealType: .breakfast) }
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
