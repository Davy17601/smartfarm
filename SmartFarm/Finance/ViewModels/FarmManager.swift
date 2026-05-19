import Foundation

class FarmManager {
    static func createViewModel() -> FarmViewModel {
        let vm = FarmViewModel()
        seedSampleData(into: vm)
        return vm
    }

    private static func seedSampleData(into vm: FarmViewModel) {
        let now = Date()
        vm.transactions = [
            Transaction(title: "លក់ស្រូវ", amount: 1_500_000, type: .income, date: now),
            Transaction(title: "ទិញជី", amount: 200_000, type: .expense, date: now),
        ]
        vm.activities = [
            FarmActivity(title: "ស្រោចទឹក",
                         date: Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now),
            FarmActivity(title: "បូកជី",
                         date: Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now),
        ]
    }
}
