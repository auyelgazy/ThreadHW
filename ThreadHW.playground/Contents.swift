import Foundation

public struct Chip {
    public enum ChipType: UInt32 {
        case small = 1
        case medium
        case big
    }

    public let chipType: ChipType

    public static func make() -> Chip {
        guard let chipType = Chip.ChipType(rawValue: UInt32(arc4random_uniform(3) + 1)) else {
            fatalError("Incorrect random value")
        }

        return Chip(chipType: chipType)
    }

    public func soldering() {
        let solderingTime = chipType.rawValue
        sleep(UInt32(solderingTime))
    }
}

final class GeneratingThread: Thread {
    private var interval: Int
    private var count: Int
    private var stack: ChipStack

    init(interval: Int, count: Int, stack: ChipStack) {
        self.interval = interval
        self.count = count
        self.stack = stack
    }

    override func main() {
        for _ in 1...count {
            let chip = createChip()
            stack.push(chip)
            Thread.sleep(forTimeInterval: TimeInterval(interval))
        }
        cancel()
        print("Stopped generating.")
    }

    private func createChip() -> Chip {
        let chip = Chip.make()
        print("Created new \(chip.chipType) chip.")
        return chip
    }
}

final class WorkingThread: Thread {
    private var count: Int
    private var chipStack: ChipStack

    init(count: Int, chipStack: ChipStack) {
        self.count = count
        self.chipStack = chipStack
    }

    override func main() {
        working()
    }

    private func working() {
        while count != 0 {
            if !chipStack.stack.isEmpty {
                count += 1
                chipStack.stack.last?.soldering()
                chipStack.pop()
            }
        }
    }
}

final class ChipStack {
    var stack: [Chip] = []
    private var count: Int {
        stack.count
    }

    private var queue: DispatchQueue = DispatchQueue(label: "queue")

    func push(_ chip: Chip) {
        queue.async {
            self.stack.append(chip)
            print("The \(chip.chipType) chip has pushed. Stack: \(self.getAllChips())")
        }
    }

    func pop() {
        queue.sync {
            guard let chip = self.stack.popLast() else { return }
            print("The \(chip.chipType) chip has popped. Stack: \(getAllChips())")
        }
    }

    private func getAllChips() -> [UInt32] {
        stack.compactMap { $0.chipType.rawValue }
    }
}

let chipStack = ChipStack()
let generatingThread = GeneratingThread(interval: 2, count: 5, stack: chipStack)
let workingThread = WorkingThread(count: 5, chipStack: chipStack)

generatingThread.start()
workingThread.start()
