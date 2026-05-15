import configparser
from pathlib import Path
from typing import Any, Dict, List
from uuid import uuid4

import pyodbc


def generate_execution_id() -> str:
    """
    Generates a unique execution id for one pipeline run.

    Returns:
        str: Unique UUID string.
    """
    return str(uuid4())


def get_sql_config(filename: str, section_name: str = "sql_server") -> Dict[str, Any]:
    """
    Reads SQL Server configuration details from a .cfg file.

    Expected config example:

        [sql_server]
        server = localhost
        port = 1433
        database = ORDER_DDS
        username = sa
        password = YOUR_PASSWORD_HERE
        driver = ODBC Driver 18 for SQL Server
        trust_server_certificate = yes

    Windows trusted connection is also supported:

        [sql_server]
        server = localhost\\SQLEXPRESS
        database = ORDER_DDS
        driver = ODBC Driver 18 for SQL Server
        trusted_connection = yes
        trust_server_certificate = yes

    Args:
        filename (str): Path to the config file.
        section_name (str): Config section name.

    Returns:
        Dict[str, Any]: SQL Server connection parameters.
    """
    config_path = Path(filename)

    if not config_path.exists():
        raise FileNotFoundError(f"Config file was not found: {config_path}")

    parser = configparser.ConfigParser()
    parser.read(config_path)

    if not parser.has_section(section_name):
        raise ValueError(
            f"Config section [{section_name}] was not found. "
            f"Available sections: {parser.sections()}"
        )

    section = parser[section_name]

    required_keys = ["server", "database", "driver"]
    missing_keys = [key for key in required_keys if key not in section]

    if missing_keys:
        raise ValueError(
            f"Missing required config keys in [{section_name}]: {missing_keys}"
        )

    sql_config = {
        "server": section.get("server"),
        "port": section.get("port", fallback=None),
        "database": section.get("database"),
        "username": section.get("username", fallback=None),
        "password": section.get("password", fallback=None),
        "driver": section.get("driver"),
        "trusted_connection": section.get("trusted_connection", fallback="no"),
        "trust_server_certificate": section.get(
            "trust_server_certificate",
            fallback="yes",
        ),
        "encrypt": section.get("encrypt", fallback="no"),
    }

    return sql_config


def create_connection_string(sql_config: Dict[str, Any]) -> str:
    """
    Creates a SQL Server connection string from the config dictionary.

    Supports both:
        1. SQL authentication: username/password
        2. Windows authentication: trusted_connection = yes

    Args:
        sql_config (Dict[str, Any]): SQL Server config dictionary.

    Returns:
        str: pyodbc connection string.
    """
    server = sql_config["server"]
    port = sql_config.get("port")

    if port:
        server = f"{server},{port}"

    conn_parts = [
        f"DRIVER={{{sql_config['driver']}}}",
        f"SERVER={server}",
        f"DATABASE={sql_config['database']}",
        f"Encrypt={sql_config.get('encrypt', 'no')}",
        f"TrustServerCertificate={sql_config.get('trust_server_certificate', 'yes')}",
    ]

    trusted_connection = str(
        sql_config.get("trusted_connection", "no")
    ).lower()

    if trusted_connection in ["yes", "true"]:
        conn_parts.append("Trusted_Connection=yes")
    else:
        username = sql_config.get("username")
        password = sql_config.get("password")

        if not username or not password:
            raise ValueError(
                "Username and password are required unless trusted_connection=yes."
            )

        conn_parts.append(f"UID={username}")
        conn_parts.append(f"PWD={password}")

    return ";".join(conn_parts) + ";"


def get_database_connection(
    config_file_path: str,
    section_name: str = "sql_server",
) -> pyodbc.Connection:
    """
    Creates and returns a SQL Server database connection.

    Args:
        config_file_path (str): Path to sql_server_config.cfg.
        section_name (str): Config section name.

    Returns:
        pyodbc.Connection: SQL Server connection.
    """
    sql_config = get_sql_config(config_file_path, section_name)
    connection_string = create_connection_string(sql_config)

    return pyodbc.connect(connection_string)


def read_sql_script(sql_file_path: str) -> str:
    """
    Reads an SQL script from a .sql file.

    Args:
        sql_file_path (str): Path to the SQL file.

    Returns:
        str: SQL script content.
    """
    sql_path = Path(sql_file_path)

    if not sql_path.exists():
        raise FileNotFoundError(f"SQL file was not found: {sql_path}")

    return sql_path.read_text(encoding="utf-8")


def format_sql_script(sql_script: str, parameters: Dict[str, Any]) -> str:
    """
    Formats a parametrized SQL script using Python .format().

    Example SQL placeholders:
        {database_name}
        {schema_name}
        {start_date}
        {end_date}
        {execution_id}

    Args:
        sql_script (str): SQL script with placeholders.
        parameters (Dict[str, Any]): Placeholder values.

    Returns:
        str: Formatted SQL script.
    """
    try:
        return sql_script.format(**parameters)
    except KeyError as error:
        missing_key = error.args[0]
        raise KeyError(f"Missing SQL parameter: {missing_key}") from error


def split_sql_batches(sql_script: str) -> List[str]:
    """
    Splits SQL Server scripts into batches by GO statements.

    pyodbc cannot execute GO directly because GO is understood by SSMS/sqlcmd,
    not by SQL Server itself.

    Args:
        sql_script (str): SQL script content.

    Returns:
        List[str]: SQL batches.
    """
    batches = []
    current_batch = []

    for line in sql_script.splitlines():
        if line.strip().upper() == "GO":
            batch = "\n".join(current_batch).strip()

            if batch:
                batches.append(batch)

            current_batch = []
        else:
            current_batch.append(line)

    final_batch = "\n".join(current_batch).strip()

    if final_batch:
        batches.append(final_batch)

    return batches


def execute_sql_script(
    config_file_path: str,
    sql_script: str,
    section_name: str = "sql_server",
    use_transaction: bool = True,
) -> Dict[str, Any]:
    """
    Executes an SQL script through pyodbc.

    If use_transaction=True:
        - all batches are committed together
        - rollback is applied if an error happens

    Args:
        config_file_path (str): Path to SQL Server config file.
        sql_script (str): SQL script to execute.
        section_name (str): Config section name.
        use_transaction (bool): Whether to execute atomically.

    Returns:
        Dict[str, Any]: Success result.
    """
    connection = None

    try:
        connection = get_database_connection(
            config_file_path=config_file_path,
            section_name=section_name,
        )
        connection.autocommit = not use_transaction

        cursor = connection.cursor()

        batches = split_sql_batches(sql_script)

        for batch in batches:
            cursor.execute(batch)

        if use_transaction:
            connection.commit()

        cursor.close()

        return {"success": True}

    except Exception:
        if connection is not None and use_transaction:
            connection.rollback()

        raise

    finally:
        if connection is not None:
            connection.close()


def read_format_execute_sql(
    config_file_path: str,
    sql_file_path: str,
    parameters: Dict[str, Any],
    section_name: str = "sql_server",
    use_transaction: bool = True,
) -> Dict[str, Any]:
    """
    Reads a parametrized SQL file, formats it, and executes it.

    Args:
        config_file_path (str): Path to SQL Server config file.
        sql_file_path (str): Path to SQL script.
        parameters (Dict[str, Any]): SQL placeholder values.
        section_name (str): Config section name.
        use_transaction (bool): Whether to execute atomically.

    Returns:
        Dict[str, Any]: Success result.
    """
    sql_script = read_sql_script(sql_file_path)
    formatted_sql_script = format_sql_script(sql_script, parameters)

    return execute_sql_script(
        config_file_path=config_file_path,
        sql_script=formatted_sql_script,
        section_name=section_name,
        use_transaction=use_transaction,
    )