import Combine

protocol ViewModel<State, Events>: ObservableObject {
    associatedtype State
    associatedtype Events

    var state: State { get }
    func send(_ event: Events) async
}
