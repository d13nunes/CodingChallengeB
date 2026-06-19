import Combine

protocol ViewModel<State, Events> {
    associatedtype State
    associatedtype Events

    var state: State { get }
    func send(_ event: Events) async
}
