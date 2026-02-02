import Foundation

/// A type that can provide route definitions.
///
/// Types conforming to `Routeable` can be included in route hierarchies and
/// contribute route definitions to the schema. Both `Route` and `RouteGroup`
/// conform to this protocol.
public protocol Routeable: Sendable {
    /// Resolves this routeable into a list of concrete routes.
    ///
    /// - Parameter components: The parent path components
    /// - Returns: An array of resolved routes with full paths
    func routes(components: [String]) -> [ResolvedRoute]
}

/// A result builder for constructing route hierarchies.
///
/// `RouteableBuilder` enables the DSL syntax for defining routes:
///
/// ```swift
/// RouteGroup(root: "/api") {
///     Route("getUsers", path: "/users")
///     Route("createUser", path: "/users", method: .post)
/// }
/// ```
@resultBuilder
public struct RouteableBuilder {
    public static func buildBlock(_ components: any Routeable...) -> [any Routeable] {
        return components
    }
    public static func buildPartialBlock(first: [any Routeable]) -> [any Routeable] {
        return first
    }
}

/// A group of routes that share a common path prefix.
///
/// `RouteGroup` allows you to organize related routes under a common path.
/// Groups can be nested to create hierarchical route structures.
///
/// ## Example
/// ```swift
/// func userRoutes() -> RouteGroup {
///     return RouteGroup(root: "/users") {
///         Route("getUsers", path: "/")
///         Route("getUserById", path: "/:id")
///         Route("createUser", path: "/create", method: .post)
///     }
/// }
///
/// // Nest groups
/// RouteGroup(root: "/api/v1") {
///     userRoutes()
///     postRoutes()
/// }
/// ```
public final class RouteGroup: Routeable, Sendable {
    /// The root path for this group
    let root: String

    /// The child routes and groups
    let children: [any Routeable]

    /// Creates a new route group with a root path and child routes.
    ///
    /// The root path will be normalized by ensuring it starts with `/`
    /// and doesn't end with `/`.
    ///
    /// - Parameters:
    ///   - root: The common path prefix for all routes in this group
    ///   - children: A result builder closure that defines the child routes
    public init(root: String, @RouteableBuilder _ children: () -> [any Routeable]) {
        self.children = children()
        var root = root
        if !root.hasPrefix("/") {
            root.insert("/", at: root.startIndex)
        }
        if root.hasSuffix("/") {
            root.removeLast()
        }
        self.root = root
    }

    public func routes(components: [String]) -> [ResolvedRoute] {
        var childComponents = Array(components)
        childComponents.append(root)
        let allChildren = children.flatMap {
            $0.routes(components: childComponents)
        }
        return allChildren
    }
}

/// A fully resolved route with its complete URL path.
///
/// `ResolvedRoute` represents a route after all parent path components
/// have been combined to form the complete URL.
public final class ResolvedRoute: Sendable {
    /// The complete URL path for this route
    let url: String

    /// The underlying route definition
    let route: Route

    init(components: [String], route: Route) {
        self.url = "\(components.joined(separator: "/"))\(route.path)"
        self.route = route
    }
}

/// Represents an API endpoint with a name, path, and HTTP method.
///
/// Routes are the building blocks of your API definition. Each route
/// defines a single endpoint that will be generated consistently across
/// all target languages.
///
/// ## Example
/// ```swift
/// Route("getUsers", path: "/users", method: .get)
/// Route("createUser", path: "/users", method: .post)
/// Route("getUserById", path: "/users/:id", method: .get)
/// Route("updateUser", path: "/users/:id", method: .patch)
/// Route("deleteUser", path: "/users/:id", method: .delete)
/// ```
public final class Route: Routeable, Sendable {
    /// The name of this route, used for code generation
    let name: String

    /// The URL path for this route
    let path: String

    /// The HTTP method for this route
    let method: RouteMethod

    /// Creates a new route definition.
    ///
    /// - Parameters:
    ///   - name: A unique identifier for this route, used in generated code
    ///   - path: The URL path (can include parameters like `:id`)
    ///   - method: The HTTP method (defaults to `.get`)
    public init(
        _ name: String,
        path: String,
        method: RouteMethod = .get,
    ) {
        self.name = name
        self.method = method
        self.path = path
    }

    public func routes(components: [String]) -> [ResolvedRoute] {
        return [ResolvedRoute(components: components, route: self)]
    }
}

/// HTTP methods supported for routes.
///
/// Defines the standard HTTP methods that can be used with routes.
/// The raw value is the HTTP method name as used in requests.
public enum RouteMethod: String, Sendable {
    /// HTTP GET method
    case get = "GET"

    /// HTTP POST method
    case post = "POST"

    /// HTTP PATCH method
    case patch = "PATCH"

    /// HTTP DELETE method
    case delete = "DELETE"

    /// HTTP PUT method
    case put = "PUT"
}

