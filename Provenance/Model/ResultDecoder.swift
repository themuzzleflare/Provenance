import Foundation

struct ResultDecoder<T> {
    private let transform: (Data) throws -> T

    init (_ transform: @escaping (Data) throws -> T) {
        self.transform = transform
    }

    func decode(_ result: DataResult) -> Result<T, NetworkError> {
        result.flatMap { (data) -> Result<T, NetworkError> in
            Result { try transform(data) }
            .mapError { NetworkError.decodingError($0) }
        }
    }
}
