import logging as py_logging
from pathlib import Path


class ExecutionIdFilter(py_logging.Filter):
    def __init__(self, execution_id: str):
        super().__init__()
        self.execution_id = execution_id

    def filter(self, record):
        record.execution_id = self.execution_id
        return True


def setup_logger(
    execution_id: str,
    log_file: str = "logs/logs_dimensional_data_pipeline.txt",
):
    """
    Creates and configures the dimensional pipeline logger.

    Logs include:
    - timestamp
    - log level
    - execution_id
    - log message
    """

    Path(log_file).parent.mkdir(parents=True, exist_ok=True)

    logger_name = f"dimensional_data_pipeline_{execution_id}"

    logger = py_logging.getLogger(logger_name)
    logger.setLevel(py_logging.INFO)
    logger.propagate = False

    if logger.handlers:
        return logger

    formatter = py_logging.Formatter(
        fmt="%(asctime)s | %(levelname)s | execution_id=%(execution_id)s | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    file_handler = py_logging.FileHandler(log_file)
    file_handler.setLevel(py_logging.INFO)
    file_handler.setFormatter(formatter)
    file_handler.addFilter(ExecutionIdFilter(execution_id))

    console_handler = py_logging.StreamHandler()
    console_handler.setLevel(py_logging.INFO)
    console_handler.setFormatter(formatter)
    console_handler.addFilter(ExecutionIdFilter(execution_id))

    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    return logger
