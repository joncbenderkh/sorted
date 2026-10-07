extends GutTest


func test_version_is_semver() -> void:
	var pattern := RegEx.create_from_string("^\\d+\\.\\d+\\.\\d+$")
	assert_not_null(pattern.search(Version.CURRENT))


func test_version_matches_project_setting() -> void:
	assert_eq(Version.CURRENT, ProjectSettings.get_setting("application/config/version"))
