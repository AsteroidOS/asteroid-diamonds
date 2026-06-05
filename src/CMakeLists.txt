add_library(asteroid-diamonds main.cpp)
set_target_properties(asteroid-diamonds PROPERTIES PREFIX "")

asteroid_app_qml_module(asteroid-diamonds
	main.qml
	Game.qml
)

target_link_libraries(
	asteroid-diamonds
	PUBLIC
		Asteroid::AsteroidApp6
)

install(
	TARGETS asteroid-diamonds
	DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
