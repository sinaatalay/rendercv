import rendercv.user_communicator as uc

import pydantic
import ruamel.yaml
import pytest


def test_welcome():
    uc.welcome()


def test_warning():
    uc.warning("This is a warning message.")


def test_error():
    uc.error("This is an error message.")


def test_information():
    uc.information("This is an information message.")


def test_get_error_message_and_location_and_value_from_a_custom_error():
    error_string = "('error message', 'location', 'value')"
    result = uc.get_error_message_and_location_and_value_from_a_custom_error(
        error_string
    )
    assert result == ("error message", "location", "value")

    error_string = "error message"
    result = uc.get_error_message_and_location_and_value_from_a_custom_error(
        error_string
    )
    assert result is None


def test_handle_validation_error(invalid_entries):
    for entry_type, entries in invalid_entries.items():
        for entry in entries:
            try:
                entry_type(**entry)
            except pydantic.ValidationError as e:
                uc.handle_validation_error(e)


@pytest.mark.parametrize(
    "exception",
    [ruamel.yaml.YAMLError, RuntimeError],
)
def test_handle_exceptions(exception):
    @uc.handle_exceptions
    def function_that_raises_exception():
        raise exception("This is an exception!")

    function_that_raises_exception()


def test_live_progress_reporter_class():
    with uc.LiveProgressReporter(number_of_steps=3) as progress:
        progress.start_a_step("Test step 1")
        progress.finish_the_current_step()

        progress.start_a_step("Test step 2")
        progress.finish_the_current_step()

        progress.start_a_step("Test step 3")
        progress.finish_the_current_step()
