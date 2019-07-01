//
//  Client.swift
//  MastodonKit
//
//  Created by Ornithologist Coder on 4/22/17.
//  Copyright © 2017 MastodonKit. All rights reserved.
//

import Foundation

public struct Client: ClientType {
    public let baseURL: String
    public var accessToken: String?

    let session: URLSession

    public init(baseURL: String, accessToken: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.accessToken = accessToken
    }

    @discardableResult
    public func run<Model>(_ request: Request<Model>,
                           resumeImmediatelly: Bool,
                           completion: @escaping (Result<Model>) -> Void) -> URLSessionDataTask? where Model: Codable {
        guard
            let components = URLComponents(baseURL: baseURL, request: request),
            let url = components.url
        else {
            completion(.failure(ClientError.malformedURL))
            return nil
        }

        let urlRequest = URLRequest(url: url, request: request, accessToken: accessToken)

        let task = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(.genericError(error as NSError)))
                return
            }

            guard let data = data else {
                completion(.failure(ClientError.malformedJSON))
                return
            }

            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                let mastodonError = try? MastodonError.decode(data: data)
                let error: ClientError = mastodonError.map { .mastodonError($0.description) }
                                        ?? .badStatus(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
                completion(.failure(error))
                return
            }

            do {
                completion(.success(try Model.decode(data: data), httpResponse.pagination))
            } catch let parseError {
                #if DEBUG
                NSLog("Parse error: \(parseError)")
                #endif
                completion(.failure(ClientError.invalidModel))
            }
        }

        if resumeImmediatelly {
            task.resume()
        }

        return task
    }

    public func runAndAggregateAllPages<Model: Codable>(requestProvider: @escaping (Pagination) -> Request<[Model]>,
                                                        completion: @escaping (Result<[Model]>) -> Void) {

        let aggregationQueue = DispatchQueue(label: "Aggregation", qos: .utility)
        var aggregateResults: [Model] = []

        func fetchPage(pagination: Pagination) {
            run(requestProvider(pagination)) { result in

                switch result {
                case .success(let partialResult, let newPagination):
                    aggregationQueue.async {
                        aggregateResults.append(contentsOf: partialResult)

                        if !partialResult.isEmpty, let pagination = newPagination, pagination.next != nil {
                            fetchPage(pagination: pagination)
                        } else {
                            completion(.success(aggregateResults, nil))
                        }
                    }

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }

        fetchPage(pagination: Pagination(next: nil, previous: nil))
    }
}
