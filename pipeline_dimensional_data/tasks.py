from pathlib import Path
from typing import Any, Dict, Optional
import sys


PROJECT_ROOT = Path(__file__).resolve().parents[1]

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))


from utils import read_format_execute_sql
from pipeline_dimensional_data import config


def check_previous_task(
    previous_task_result: Optional[Dict[str, Any]],
    current_task_name: str,
) -> None:
    """
    Checks whether the previous task completed successfully.

    Args:
        previous_task_result (Optional[Dict[str, Any]]): Result from the previous task.
        current_task_name (str): Name of the current task.

    Raises:
        RuntimeError: If the previous task did not succeed.
    """
    if previous_task_result is None:
        return

    if not previous_task_result.get("success"):
        raise RuntimeError(
            f"{current_task_name} cannot run because the previous task failed."
        )


def build_common_parameters(
    database_name: str,
    schema_name: str,
    execution_id: str,
) -> Dict[str, Any]:
    """
    Builds common SQL parameters used by dimension update scripts.

    Args:
        database_name (str): Dimensional database name.
        schema_name (str): Schema name.
        execution_id (str): Pipeline execution id.

    Returns:
        Dict[str, Any]: SQL parameters.
    """
    return {
        "database_name": database_name,
        "schema_name": schema_name,
        "execution_id": execution_id,
    }


def build_fact_parameters(
    database_name: str,
    schema_name: str,
    start_date: str,
    end_date: str,
    execution_id: str,
) -> Dict[str, Any]:
    """
    Builds SQL parameters used by fact and fact error update scripts.

    Args:
        database_name (str): Dimensional database name.
        schema_name (str): Schema name.
        start_date (str): Start date for fact ingestion.
        end_date (str): End date for fact ingestion.
        execution_id (str): Pipeline execution id.

    Returns:
        Dict[str, Any]: SQL parameters.
    """
    parameters = build_common_parameters(
        database_name=database_name,
        schema_name=schema_name,
        execution_id=execution_id,
    )

    parameters.update(
        {
            "start_date": start_date,
            "end_date": end_date,
        }
    )

    return parameters


def run_sql_script_task(
    sql_file_path: Path,
    parameters: Dict[str, Any],
    task_name: str,
    previous_task_result: Optional[Dict[str, Any]] = None,
    use_transaction: bool = True,
) -> Dict[str, Any]:
    """
    Executes one parametrized SQL script as a pipeline task.

    Args:
        sql_file_path (Path): Path to SQL script.
        parameters (Dict[str, Any]): Parameters used for SQL formatting.
        task_name (str): Name of the task.
        previous_task_result (Optional[Dict[str, Any]]): Previous task result.
        use_transaction (bool): Whether SQL should be executed atomically.

    Returns:
        Dict[str, Any]: Task result.
    """
    check_previous_task(
        previous_task_result=previous_task_result,
        current_task_name=task_name,
    )

    result = read_format_execute_sql(
        config_file_path=str(config.CONFIG_FILE_PATH),
        sql_file_path=str(sql_file_path),
        parameters=parameters,
        section_name=config.CONFIG_SECTION_NAME,
        use_transaction=use_transaction,
    )

    return {
        "success": result["success"],
        "task_name": task_name,
        "sql_file": str(sql_file_path),
    }


def create_dimensional_database_task(
    previous_task_result: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Creates the ORDER_DDS database by running dimensional_database_creation.sql.

    This task is for initial setup. It is not usually part of the regular
    dimensional data pipeline execution.
    """
    return run_sql_script_task(
        sql_file_path=config.DIMENSIONAL_DATABASE_CREATION_SQL,
        parameters={},
        task_name="create_dimensional_database_task",
        previous_task_result=previous_task_result,
        use_transaction=False,
    )


def create_staging_raw_tables_task(
    previous_task_result: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Creates staging raw tables by running staging_raw_table_creation.sql.

    This task is for initial setup. It is not usually part of the regular
    dimensional data pipeline execution.
    """
    return run_sql_script_task(
        sql_file_path=config.STAGING_RAW_TABLE_CREATION_SQL,
        parameters={},
        task_name="create_staging_raw_tables_task",
        previous_task_result=previous_task_result,
        use_transaction=True,
    )


def create_dimensional_tables_task(
    previous_task_result: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Creates dimensional database tables by running dimensional_db_table_creation.sql.

    This task is for initial setup. It is not usually part of the regular
    dimensional data pipeline execution.
    """
    return run_sql_script_task(
        sql_file_path=config.DIMENSIONAL_DB_TABLE_CREATION_SQL,
        parameters={},
        task_name="create_dimensional_tables_task",
        previous_task_result=previous_task_result,
        use_transaction=True,
    )


def create_dimensional_database_objects_task() -> Dict[str, Any]:
    """
    Runs all initial DDL scripts sequentially.

    Order:
        1. Create ORDER_DDS database
        2. Create staging raw tables
        3. Create dimensional tables

    Returns:
        Dict[str, Any]: Final task result.
    """
    database_result = create_dimensional_database_task()

    staging_result = create_staging_raw_tables_task(
        previous_task_result=database_result,
    )

    dimensional_tables_result = create_dimensional_tables_task(
        previous_task_result=staging_result,
    )

    return {
        "success": dimensional_tables_result["success"],
        "task_name": "create_dimensional_database_objects_task",
    }


def update_dimensions_task(
    database_name: str,
    schema_name: str,
    execution_id: str,
    previous_task_result: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Updates all dimension tables.

    The requirement asks for separate update_dim_{table}.sql scripts.
    Therefore, this one Python task executes multiple dimension scripts
    sequentially.

    Args:
        database_name (str): Dimensional database name.
        schema_name (str): Schema name.
        execution_id (str): Pipeline execution id.
        previous_task_result (Optional[Dict[str, Any]]): Previous task result.

    Returns:
        Dict[str, Any]: Task result.
    """
    task_name = "update_dimensions_task"

    check_previous_task(
        previous_task_result=previous_task_result,
        current_task_name=task_name,
    )

    parameters = build_common_parameters(
        database_name=database_name,
        schema_name=schema_name,
        execution_id=execution_id,
    )

    executed_files = []

    for sql_file_path in config.DIMENSION_SQL_FILES:
        result = run_sql_script_task(
            sql_file_path=sql_file_path,
            parameters=parameters,
            task_name=f"update_dimension_script_task:{sql_file_path.name}",
            previous_task_result=None,
            use_transaction=True,
        )

        if not result.get("success"):
            return {
                "success": False,
                "task_name": task_name,
                "failed_file": str(sql_file_path),
            }

        executed_files.append(str(sql_file_path))

    return {
        "success": True,
        "task_name": task_name,
        "executed_files": executed_files,
        "execution_id": execution_id,
    }


def update_fact_error_task(
    database_name: str,
    schema_name: str,
    start_date: str,
    end_date: str,
    execution_id: str,
    previous_task_result: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Inserts faulty rows into FactOrdersError.

    A faulty row means it cannot enter FactOrders because of missing or invalid
    natural keys in dimension lookups.

    Args:
        database_name (str): Dimensional database name.
        schema_name (str): Schema name.
        start_date (str): Start date for fact error ingestion.
        end_date (str): End date for fact error ingestion.
        execution_id (str): Pipeline execution id.
        previous_task_result (Optional[Dict[str, Any]]): Previous task result.

    Returns:
        Dict[str, Any]: Task result.
    """
    parameters = build_fact_parameters(
        database_name=database_name,
        schema_name=schema_name,
        start_date=start_date,
        end_date=end_date,
        execution_id=execution_id,
    )

    result = run_sql_script_task(
        sql_file_path=config.UPDATE_FACT_ERROR_SQL,
        parameters=parameters,
        task_name="update_fact_error_task",
        previous_task_result=previous_task_result,
        use_transaction=True,
    )

    return {
        "success": result["success"],
        "task_name": "update_fact_error_task",
        "execution_id": execution_id,
    }


def update_fact_task(
    database_name: str,
    schema_name: str,
    start_date: str,
    end_date: str,
    execution_id: str,
    previous_task_result: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Inserts valid rows into FactOrders.

    Args:
        database_name (str): Dimensional database name.
        schema_name (str): Schema name.
        start_date (str): Start date for fact ingestion.
        end_date (str): End date for fact ingestion.
        execution_id (str): Pipeline execution id.
        previous_task_result (Optional[Dict[str, Any]]): Previous task result.

    Returns:
        Dict[str, Any]: Task result.
    """
    parameters = build_fact_parameters(
        database_name=database_name,
        schema_name=schema_name,
        start_date=start_date,
        end_date=end_date,
        execution_id=execution_id,
    )

    result = run_sql_script_task(
        sql_file_path=config.UPDATE_FACT_SQL,
        parameters=parameters,
        task_name="update_fact_task",
        previous_task_result=previous_task_result,
        use_transaction=True,
    )

    return {
        "success": result["success"],
        "task_name": "update_fact_task",
        "execution_id": execution_id,
    }