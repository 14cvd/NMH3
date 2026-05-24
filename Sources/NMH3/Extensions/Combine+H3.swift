import Combine

@available(iOS 15.0, *)
public extension Publisher where Output == H3Cell {
    public func h3Distinct() -> AnyPublisher<H3Cell, Failure> {
        removeDuplicates().eraseToAnyPublisher()
    }

    public func h3Debounce(resolution: H3Resolution) -> AnyPublisher<H3Cell, Failure> {
        self.eraseToAnyPublisher()
    }

    public func h3Throttle(k: Int) -> AnyPublisher<H3Cell, Failure> {
        self.eraseToAnyPublisher()
    }
}
