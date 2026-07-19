public enum ViewState<T: Equatable>: Equatable {
    case idle, loading, loaded(T), error(String)
}
