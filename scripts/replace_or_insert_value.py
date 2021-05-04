import re
import sys

DOT_ENV_LOCATION = ".env"


def replace_or_insert_value(value_to_write: str, variable_to_replace: str):
    variable_in_file_regex = f"{variable_to_replace}=.*"
    line_to_write = f"{variable_to_replace}=\"{value_to_write}\""
    with open(DOT_ENV_LOCATION, "r") as env_file:
        file_content = env_file.read()

    if re.findall(variable_in_file_regex, file_content, re.MULTILINE):
        with open(DOT_ENV_LOCATION, "r+") as env_file:
            file_content = re.sub(variable_in_file_regex, line_to_write, file_content)
            env_file.seek(0)
            env_file.write(file_content)
            env_file.truncate()
            print(
                (
                    f"Found {variable_to_replace} set in `.env`, "
                    f"replaced with: {variable_to_replace}=\"{value_to_write}\""
                )
            )
    else:
        with open(DOT_ENV_LOCATION, "a") as env_file:
            env_file.write("\n")
            env_file.write(line_to_write)
            print(
                (
                    f"Didn't find {variable_to_replace} set in `.env`, "
                    f"set to: {variable_to_replace}=\"{value_to_write}\""
                )
            )


if __name__ == "__main__":
    replace_or_insert_value(sys.argv[1], sys.argv[2])
