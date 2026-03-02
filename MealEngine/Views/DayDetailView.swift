//  ContentView.swift
//  NutriPlanner -- Meals optimized for your goals
//  Features: knapsack algorithm, Nutrionix API
//  Required: 3 data types (string, double, bool. Food), 3 screens, 3 colors, 3 GUI objects (8-9 core UI elements)
//  ...and persistent data storage
//  ==================
//  Group Members: 
//  ------------------
//  1.	Stephen Anaba as Code Keeper
//  2.	Liam Knight as Presenter
//  3.  Jane Lin as API Lead
//  4.  Curtis Quan-Tran as Data Lead
//  5.  Angel Orduna as GUI Lead 
//  ====================

import SwiftUI

struct DayDetailView: View {
    @ObservedObject var vm: MealPlannerViewModel
    let date: Date
    let progress: Double

    private var trackedDay: TrackedDay? {
        vm.getTrackedDay(for: date)
    }
    
    private var meals: [Meal] {
        vm.getMeals(for: date)
    }

    private var calories: Double {
        trackedDay?.calories ?? 0
    }
    
    private var protein: Double {
        trackedDay?.protein ?? 0
    }
    
    private var carbs: Double {
        trackedDay?.carbs ?? 0
    }
    
    private var fat: Double {
        trackedDay?.fat ?? 0
    }
    
    private var goalCalories: Double {
        vm.goals.calories
    }

    private var proteinKcal: Double { protein * 4 }
    private var carbsKcal: Double { carbs * 4 }
    private var fatKcal: Double { fat * 9 }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Capsule().fill(Theme.textSecondary.opacity(0.25))
                    .frame(width: 44, height: 5)
                    .padding(.top, 8)

                Text(date, format: .dateTime.weekday(.wide).month().day())
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)

                // Calories vs goal
                Text("\(Int(calories)) / \(Int(goalCalories)) kcal  •  \(Int(round(progress*100)))%")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)

                // Macro donut
                MacroDonut(proteinKcal: proteinKcal, carbsKcal: carbsKcal, fatKcal: fatKcal)
                    .frame(height: 150)

                HStack(spacing: 16) {
                    pill("Protein", "\(Int(protein)) g", color: Theme.success)
                    pill("Carbs", "\(Int(carbs)) g", color: Theme.primary)
                    pill("Fat", "\(Int(fat)) g", color: Theme.warning)
                }

                // Meals breakdown
                if !meals.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("Meals")
                            .font(.headline)
                            .foregroundColor(Theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                            mealCard(meal: meal, index: index + 1)
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .background(Theme.surface.ignoresSafeArea())
    }

    private func pill(_ title: String, _ value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title).foregroundColor(Theme.textPrimary)
            Spacer(minLength: 4)
            Text(value).foregroundColor(Theme.textSecondary)
        }
        .font(.caption)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.surface, in: Capsule())
        .overlay(Capsule().stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1))
    }

    private func mealCard(meal: Meal, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(Theme.primary)
                
                Text("Meal \(index)")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Text(meal.date, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Divider()
            
            // Meal totals
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("\(Int(meal.totalCalories))")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Theme.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protein")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("\(Int(meal.totalProtein))g")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Theme.success)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Carbs")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("\(Int(meal.totalCarbs))g")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Theme.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fat")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                    Text("\(Int(meal.totalFat))g")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Theme.warning)
                }
                
                Spacer()
            }
            
            // Food items
            if !meal.items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(meal.items.prefix(3)) { item in
                        Text("• \(item.food.name)")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                    if meal.items.count > 3 {
                        Text("+ \(meal.items.count - 3) more")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary.opacity(0.7))
                            .italic()
                    }
                }
            }
        }
        .padding()
        .background(Theme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.textSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    DayDetailView(
        vm: MealPlannerViewModel(),
        date: .now,
        progress: 0.75
    )
    .preferredColorScheme(.light)
}
