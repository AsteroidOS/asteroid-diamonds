add_library(asteroid-diamonds main.cpp resources.qrc)
set_target_properties(asteroid-diamonds PROPERTIES PREFIX "")

target_link_libraries(asteroid-diamonds PUBLIC
	AsteroidApp)

install(TARGETS asteroid-diamonds
	DESTINATION ${CMAKE_INSTALL_LIBDIRDIR})
