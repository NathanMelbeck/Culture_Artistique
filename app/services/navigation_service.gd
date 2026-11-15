class_name NavigationService
extends RefCounted

signal route_changed(route: String)
const ROUTES := ["home", "courses", "revision", "games", "credits"]
var current_route := "home"

func navigate(route: String) -> void:
	if route not in ROUTES or route == current_route:
		return
	current_route = route
	route_changed.emit(route)

func go_home() -> void:
	navigate("home")
