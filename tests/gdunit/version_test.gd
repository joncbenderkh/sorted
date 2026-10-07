class_name VersionTest
extends GdUnitTestSuite


func test_version_is_semver() -> void:
	var pattern := RegEx.create_from_string("^\\d+\\.\\d+\\.\\d+$")
	assert_object(pattern.search(Version.CURRENT)).is_not_null()


func test_version_matches_project_setting() -> void:
	assert_str(Version.CURRENT).is_equal(ProjectSettings.get_setting("application/config/version"))
