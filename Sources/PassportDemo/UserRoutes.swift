import Passport


func userRoutes() -> RouteGroup {
    return RouteGroup(root: "/users") {
        Route("getUsers", path: "/")
        Route("createUser", path: "/create", method: .post)
    }
}
