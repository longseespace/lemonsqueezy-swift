import Foundation

extension LemonSqueezy {
    internal func call<T: Codable>(
        route: APIRoute,
        method: HTTPMethod = .GET,
        queryItems: [URLQueryItem] = [],
        pageNumber: Int? = nil,
        pageSize: Int = 10,
        body: Data? = nil
    ) async throws -> T {
        let url = getURL(for: route, queryItems: queryItems, pageNumber: pageNumber, pageSize: pageSize)
        var request = URLRequest(url: url)
        if let body {
            request.httpBody = body
        }
        
        signURLRequest(method: method, body: body, request: &request)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decodeOrThrow(decodingType: T.self, data: data)
    }
}

extension LemonSqueezy {
    internal func getURL(for route: APIRoute, queryItems: [URLQueryItem] = [], pageNumber: Int?, pageSize: Int) -> URL {
        var combinedQueryItems: [URLQueryItem] = []
        
        if (pageNumber != nil) {
            combinedQueryItems.append(URLQueryItem(name: "page[size]", value: String(pageSize)))
            combinedQueryItems.append(URLQueryItem(name: "page[number]", value: String(pageNumber!)))
        }
        
        combinedQueryItems.append(contentsOf: queryItems)
        
        if let routeQueryItems = route.resolvedPath.queryItems {
            combinedQueryItems.append(contentsOf: routeQueryItems)
        }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.lemonsqueezy.test"
        components.path = "\(route.resolvedPath.path)"
        components.queryItems = combinedQueryItems
        
        var allowedCharacters = CharacterSet.urlQueryAllowed
        allowedCharacters.remove(charactersIn: ":()")
        components.percentEncodedQuery = components.query?.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        
        return components.url!
    }
    
    internal func signURLRequest(method: HTTPMethod, body: Data? = nil, request: inout URLRequest) {
        request.addValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/vnd.api+json", forHTTPHeaderField: "Accept")
        request.httpMethod = method.rawValue
    }
}

internal enum HTTPMethod: String {
  case GET, POST, DELETE, PUT, PATCH
}

extension LemonSqueezy {
    internal enum APIRoute {
        case me
        
        case orders
        case order(_ orderId: Order.ID)
        
        case stores
        case store(_ storeId: Store.ID)
        
        case products
        case product(_ productId: Product.ID)
        
        case variants
        case variant(_ variantId: Variant.ID)
        
        case files
        case file(_ fileId: File.ID)
        
        case orderItems
        case orderItem(_ orderItemId: OrderItem.ID)
        
        case subscriptions
        case subscription(_ subscriptionId: Subscription.ID)
        
        var resolvedPath: (path: String, queryItems: [URLQueryItem]?) {
            switch self {
            case .me:
                return (path: "/v1/users/me", queryItems: nil)
            case .order(let id):
              return (path: "/v1/orders/\(id)", queryItems: nil)
            case .orders:
              return (path: "/v1/orders", queryItems: nil)
            case .stores:
              return (path: "/v1/stores", queryItems: nil)
            case .store(let id):
              return (path: "/v1/stores/\(id)", queryItems: nil)
            case .products:
                return (path: "/v1/products", queryItems: nil)
            case .product(let id):
                return (path: "/v1/products/\(id)", queryItems: nil)
            case .variants:
                return (path: "/v1/variants", queryItems: nil)
            case .variant(let id):
                return (path: "/v1/variants/\(id)", queryItems: nil)
            case .files:
                return (path: "/v1/files", queryItems: nil)
            case .file(let id):
                return (path: "/v1/files/\(id)", queryItems: nil)
            case .orderItems:
                return (path: "/v1/order-items", queryItems: nil)
            case .orderItem(let id):
                return (path: "/v1/order-items/\(id)", queryItems: nil)
            case .subscriptions:
                return (path: "/v1/subscriptions", queryItems: nil)
            case .subscription(let id):
                return (path: "/v1/subscriptions/\(id)", queryItems: nil)
            }
        }
    }
    
    internal func decodeOrThrow<T: Codable>(decodingType: T.Type, data: Data) throws -> T {
        guard let result = try? decoder.decode(decodingType.self, from: data) else {
            if let error = try? decoder.decode(LemonSqueezyAPIError.self, from: data) { throw error }
            
            throw LemonSqueezyError.UnknownError(String(data: data, encoding: .utf8))
        }
        
        return result
    }
}

public struct LemonSqueezyAPIDataAndIncluded<Resource: Codable, Included: Codable>: Codable {
    /// The requested object(s)
    public let data: Resource
    
    /// Related resources that can be included in the same response by using the `include` query parameter.
    public let included: Included?
    
    /// Any errors associated with the request
    public let errors: [LemonSqueezyAPIError]?
}

public struct LemonSqueezyAPIDataIncludedAndMeta<Resource: Codable, Included: Codable, Meta: Codable>: Codable {
    /// The requested object(s)
    public let data: Resource
    
    /// An object containing pagination information for paginated requests
    public let meta: Meta?
    
    /// Related resources that can be included in the same response by using the `include` query parameter.
    public let included: Included?
    
    /// Any errors associated with the request
    public let errors: [LemonSqueezyAPIError]?
}

/// An object containing pagination information for paginated requests
public struct Meta: Codable {
    public let page: Page
    
    public struct Page: Codable {
        public let currentPage: Int
        public let from: Int
        public let lastPage: Int
        public let perPage: Int
        public let to: Int
        public let total: Int
    }
}
