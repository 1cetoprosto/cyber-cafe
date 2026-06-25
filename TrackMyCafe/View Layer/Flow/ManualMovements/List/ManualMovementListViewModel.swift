import Foundation

protocol ManualMovementListViewModelType {
    func reload() async
    func numberOfSections() -> Int
    func titleForHeaderInSection(_ section: Int) -> String
    func numberOfRowsInSection(_ section: Int) -> Int
    func operation(at indexPath: IndexPath) -> ManualMovementOperation
    func delete(at indexPath: IndexPath) async throws
}

final class ManualMovementListViewModel: ManualMovementListViewModelType {
    private let service: ManualMovementServiceProtocol
    private var sections: [(date: Date, items: [ManualMovementOperation])] = []

    init(service: ManualMovementServiceProtocol) {
        self.service = service
    }

    func reload() async {
        let operations = await service.fetchOperations()
        let grouped = Dictionary(grouping: operations) { item in
            Calendar.current.startOfDay(for: item.date)
        }
        let dates = grouped.keys.sorted(by: >)
        sections = dates.map { date in
            let items = grouped[date]?.sorted(by: { $0.date > $1.date }) ?? []
            return (date: date, items: items)
        }
    }

    func numberOfSections() -> Int {
        sections.count
    }

    func titleForHeaderInSection(_ section: Int) -> String {
        let date = sections[section].date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        sections[section].items.count
    }

    func operation(at indexPath: IndexPath) -> ManualMovementOperation {
        sections[indexPath.section].items[indexPath.row]
    }

    func delete(at indexPath: IndexPath) async throws {
        let id = operation(at: indexPath).id
        try await service.deleteOperation(id: id)
        await reload()
    }
}

