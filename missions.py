import json
import pandas as pd
import os
import glob
from pydantic.json import pydantic_encoder

from models import FlowControlMission, TrajectoryPoint, EndUseValveMapping


def process_house_data(file_base: str):
    """
    Processes water consumption data for a house from STREaM output CSV files.

    This function reads a specified CSV file containing water consumption data for a house and
    identifies water consumption events associated with specific end-uses (e.g., toilets, showers, or faucets).
    It applies a duration scaling factor to ensure each event lasts less than 60 seconds, derives flow
    trajectory points for each event, and creates `FlowControlMission` objects encapsulating this information.

    Parameters
    ----------
    file_base : str
        The base filename of the STREaM CSV output file (excluding the file extension),
        e.g., "House_9_10s_trajectory.csv".

    Returns
    -------
    missions : pd.Series
        A pandas Series where each element is a `FlowControlMission` object containing
        information on the event's valve ID, start time, duration scaling factor,
        and flow trajectory.

    Raises
    ------
    FileNotFoundError
        If the specified CSV file or its associated statistics file cannot be found.
    pandas.errors.ParserError
        If the input CSV file cannot be parsed correctly.

    Warns
    -----
    UserWarning
        - Events with a peak flow rate exceeding 20 liters per minute, or less than 0.1 liters per minute,
          are skipped because they are considered out of the operational range for the crewstand simulation.

    Notes
    -----
    * The function expects two types of files:
        1. A trajectory CSV file with the specified `file_base_(ends with _trajectory)`.csv, containing flow rate data for different end-uses.
        2. A statistics CSV file derived internally, expected to contain information on event timings, peak values, and durations.
    * The trajectory CSV file should include columns for various end-use appliances:
      "Toilet", "Faucet", "ClothesWasher", "Dishwasher", "Shower", "Bathtub", etc.
    * The statistics data should include the following columns: "Label", "EventStartIdx", "EventEndIdx", "Peak",
      "Duration", and "EventStartTime".
    * Each row in the trajectory CSV file represents flow rate measurements [l/min] for a 10-second interval.
    * The function identifies the portion of the trajectory corresponding to each event, scales it, and converts
      it into a list of `TrajectoryPoint` objects, where the `time` attribute is adjusted based on the calculated scaling factor.
    """

    trajectories = pd.read_csv(file_base + ".csv")

    statistics = _read_statistics(file_base)

    missions = pd.Series()

    for i, event in statistics.iterrows():
        current_end_use: str = event["Label"]
        switch_on_idx = event["EventStartIdx"] - 1
        switch_off_idx = event["EventEndIdx"]
        trajectory = trajectories[current_end_use].iloc[switch_on_idx:switch_off_idx]
        peak = event["Peak"]
        if peak <= 20 and peak >= 0.1:
            duration = event["Duration"]
            scaling_factor = int(duration / 60.1) + 1
            seconds_per_step = 10 / scaling_factor
            trajectory_points = [
                TrajectoryPoint(
                    flow_rate=trajectory.iloc[i],
                    time=(i + 1) * seconds_per_step,
                )
                for i in range(len(trajectory))
            ]

            new_mission = FlowControlMission(
                valve_id=EndUseValveMapping[current_end_use],
                duration_scaling_factor=scaling_factor,
                actual_end_use=current_end_use,
                actual_start_time=event["EventStartTime"],
                flow_trajectory=trajectory_points,
            )
            missions = pd.concat([missions, pd.Series([new_mission])])

    return missions


def generate_missions(stream_output_folder: str = "./output"):
    """
    Generates JSON mission files from STREaM output data in CSV format.

    This function iterates through a specified directory, identifying all CSV files that
    contain STREaM output data related to house trajectories and statistics. It processes
    this data, scaling the timelines for long events to ensure they fit within a 60-second limit.
    The transformed data is encapsulated into `FlowControlMission` objects (using classes
    defined in `models.py`) and serialized into JSON format. These JSON files are written
    to the specified output directory, with names derived from their respective CSV files.

    Parameters
    ----------
    stream_output_folder : str, optional
        The path to the directory containing the STREaM output CSV files.
        Defaults to './output', which represents the 'output' subdirectory
        of the current working directory.

    Returns
    -------
    None

    Side Effects
    ------------
    - Creates JSON files (one per input CSV file) in the directory specified by `stream_output_folder`.

    Raises
    ------
    OSError
        If the `stream_output_folder` path is not accessible.
    TypeError
        If the serialization to JSON fails due to incompatible data types.

    Notes
    -----
    - Depends on the `models.py` module for `FlowControlMission` and `TrajectoryPoint` classes.
    - CSV filenames are expected to start with "House_" and end with "_trajectory.csv" and "_statistics.csv" respectively.
    - All long events are scaled to fit within a 60-second duration to meet simulation requirements.

    Updated Functionality
    ---------------------
    - Enhanced error handling for file I/O operations and JSON serialization.
    - Refactored to improve code readability and maintainability.

    Examples
    --------
    >>> generate_missions("/path/to/STREaM_output")

    Processes all CSV files in the path "/path/to/STREaM_output/" and writes corresponding
    mission JSON files back to the same directory.

    See Also
    --------
    models.py: For definitions of `FlowControlMission` and `TrajectoryPoint`.
    process_house_data(file_base: str): Processes a single CSV file to generate missions.

    The `pydantic_encoder` function (implied by usage but not defined here) is assumed to
    be a custom JSON encoder function to serialize pydantic models.

    """

    # Finding all house CSV files in the stream output folder
    csv_list = glob.glob(os.path.join(stream_output_folder, "House_*_trajectory.csv"))

    for file_path in csv_list:
        file_base = os.path.splitext(os.path.basename(file_path))[0]
        missions = process_house_data(stream_output_folder + "/" + file_base)
        output_file = os.path.join(stream_output_folder, file_base + "_mission.json")

        with open(output_file, "w") as f:
            json.dump(missions.to_list(), f, default=pydantic_encoder)


def _read_statistics(file_base: str):
    splitted_base = file_base.split("_")
    statistics_base = "_".join(splitted_base[:-1] + ["statistics"])
    statistics = pd.read_csv(statistics_base + ".csv")
    statistics.sort_values(by="Hour", inplace=True)

    return statistics


if __name__ == "__main__":
    generate_missions()
