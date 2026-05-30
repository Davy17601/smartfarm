
// ViewModels/FinanceCoordinator.swift
import SwiftUI

// FinanceCoordinator centralises all navigation state for the Finance tab.
// Because it is an ObservableObject, any view that holds a reference
// can trigger programmatic navigation — including deep links from MainTabView.
//
// Pattern:
//   1. MainTabView creates it as @StateObject and injects it via .environmentObject(...)
//   2. FinanceTabView reads it with @EnvironmentObject
//   3. FilteredTransactionList binds to coordinator.selectedTransactionID
//      via NavigationLink(tag:selection:) — setting the ID activates the link
//
// iOS 13+ compatible: uses ObservableObject + @Published (no @Observable macro)

class FinanceCoordinator: ObservableObject {

    // The UUID of the transaction currently shown in the detail screen.
    // • nil  → no detail view is pushed (list is visible)
    // • UUID → NavigationLink whose tag matches this ID becomes active
    @Published var selectedTransactionID: UUID? = nil

    // Navigate to a specific transaction (can be called from anywhere)
    func navigate(to transaction: Transaction) {
        selectedTransactionID = transaction.id
    }

    // Pop back to the list
    func reset() {
        selectedTransactionID = nil
    }
}
