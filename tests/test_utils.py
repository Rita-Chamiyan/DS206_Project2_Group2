import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from unittest.mock import MagicMock, mock_open, patch

import pytest

import utils


def test_get_sql_config_success(tmp_path):
    config_file = tmp_path / "sql_server_config.cfg"
    config_file.write_text(
        """
[sql_server]
server = localhost
port = 1434
database = ORDER_DDS
username = sa
password = test_password
driver = ODBC Driver 18 for SQL Server
trust_server_certificate = yes
""",
        encoding="utf-8",
    )

    result = utils.get_sql_config(str(config_file))

    assert result["server"] == "localhost"
    assert result["port"] == "1434"
    assert result["database"] == "ORDER_DDS"
    assert result["username"] == "sa"
    assert result["password"] == "test_password"
    assert result["driver"] == "ODBC Driver 18 for SQL Server"


def test_get_sql_config_missing_file_raises_error():
    with pytest.raises(FileNotFoundError):
        utils.get_sql_config("missing_config.cfg")


def test_get_sql_config_missing_section_raises_error(tmp_path):
    config_file = tmp_path / "bad_config.cfg"
    config_file.write_text(
        """
[wrong_section]
server = localhost
database = ORDER_DDS
driver = ODBC Driver 18 for SQL Server
""",
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="Config section"):
        utils.get_sql_config(str(config_file))


def test_get_sql_config_missing_required_keys_raises_error(tmp_path):
    config_file = tmp_path / "bad_config.cfg"
    config_file.write_text(
        """
[sql_server]
server = localhost
""",
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="Missing required config keys"):
        utils.get_sql_config(str(config_file))


def test_create_connection_string_sql_auth_success():
    sql_config = {
        "server": "localhost",
        "port": "1434",
        "database": "ORDER_DDS",
        "username": "sa",
        "password": "test_password",
        "driver": "ODBC Driver 18 for SQL Server",
        "encrypt": "no",
        "trust_server_certificate": "yes",
        "trusted_connection": "no",
    }

    result = utils.create_connection_string(sql_config)

    assert "DRIVER={ODBC Driver 18 for SQL Server}" in result
    assert "SERVER=localhost,1434" in result
    assert "DATABASE=ORDER_DDS" in result
    assert "UID=sa" in result
    assert "PWD=test_password" in result


def test_create_connection_string_missing_password_raises_error():
    sql_config = {
        "server": "localhost",
        "database": "ORDER_DDS",
        "driver": "ODBC Driver 18 for SQL Server",
        "trusted_connection": "no",
    }

    with pytest.raises(ValueError, match="Username and password"):
        utils.create_connection_string(sql_config)


def test_read_sql_script_success(tmp_path):
    sql_file = tmp_path / "query.sql"
    sql_file.write_text("SELECT 1;", encoding="utf-8")

    result = utils.read_sql_script(str(sql_file))

    assert result == "SELECT 1;"


def test_read_sql_script_missing_file_raises_error():
    with pytest.raises(FileNotFoundError):
        utils.read_sql_script("missing_query.sql")


def test_format_sql_script_success():
    sql = "USE {database_name}; SELECT * FROM {schema_name}.DimCustomers;"

    result = utils.format_sql_script(
        sql,
        {"database_name": "ORDER_DDS", "schema_name": "dbo"},
    )

    assert result == "USE ORDER_DDS; SELECT * FROM dbo.DimCustomers;"


def test_format_sql_script_missing_parameter_raises_error():
    sql = "USE {database_name}; SELECT * FROM {schema_name}.DimCustomers;"

    with pytest.raises(KeyError, match="Missing SQL parameter"):
        utils.format_sql_script(sql, {"database_name": "ORDER_DDS"})


def test_split_sql_batches_handles_go_statements():
    sql = """
CREATE TABLE A (id INT);
GO
CREATE TABLE B (id INT);
GO
"""

    result = utils.split_sql_batches(sql)

    assert result == [
        "CREATE TABLE A (id INT);",
        "CREATE TABLE B (id INT);",
    ]


@patch("utils.get_database_connection")
def test_execute_sql_script_success_calls_execute_and_commit(mock_get_connection):
    mock_connection = MagicMock()
    mock_cursor = MagicMock()
    mock_connection.cursor.return_value = mock_cursor
    mock_get_connection.return_value = mock_connection

    result = utils.execute_sql_script(
        config_file_path="fake_config.cfg",
        sql_script="SELECT 1;",
        use_transaction=True,
    )

    assert result == {"success": True}
    mock_cursor.execute.assert_called_once_with("SELECT 1;")
    mock_connection.commit.assert_called_once()
    mock_connection.rollback.assert_not_called()
    mock_connection.close.assert_called_once()


@patch("utils.get_database_connection")
def test_execute_sql_script_failure_rolls_back(mock_get_connection):
    mock_connection = MagicMock()
    mock_cursor = MagicMock()
    mock_cursor.execute.side_effect = Exception("database error")
    mock_connection.cursor.return_value = mock_cursor
    mock_get_connection.return_value = mock_connection

    with pytest.raises(Exception, match="database error"):
        utils.execute_sql_script(
            config_file_path="fake_config.cfg",
            sql_script="SELECT 1;",
            use_transaction=True,
        )

    mock_connection.rollback.assert_called_once()
    mock_connection.close.assert_called_once()


@patch("utils.execute_sql_script")
@patch("utils.read_sql_script")
def test_read_format_execute_sql_success(mock_read_sql_script, mock_execute_sql_script):
    mock_read_sql_script.return_value = "USE {database_name}; SELECT 1;"
    mock_execute_sql_script.return_value = {"success": True}

    result = utils.read_format_execute_sql(
        config_file_path="fake_config.cfg",
        sql_file_path="fake_query.sql",
        parameters={"database_name": "ORDER_DDS"},
    )

    assert result == {"success": True}
    mock_execute_sql_script.assert_called_once_with(
        config_file_path="fake_config.cfg",
        sql_script="USE ORDER_DDS; SELECT 1;",
        section_name="sql_server",
        use_transaction=True,
    )
