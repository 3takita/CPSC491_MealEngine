//
//  AppState 2.swift
//  MealEngine
//
//  Created by Guest User on 4/17/26.
//


import SwiftUI

final class AppState: ObservableObject {

    let plannerVM: MealPlannerViewModel
    let goalsVM: GoalsViewModel
    let historyVM: HistoryViewModel

    init() {
        self.plannerVM = MealPlannerViewModel()
        self.goalsVM = GoalsViewModel()
        self.historyVM = HistoryViewModel()
    }
}