import os
import json
from typing import Any, Dict, List
from hexbytes import HexBytes
from eth_utils import keccak

base_dir = os.path.dirname(os.path.abspath(__file__))
relative_path = f"./deployments.json"

def edit_value(_key, _value):
    file_path = os.path.join(base_dir, relative_path)
    with open(file_path, "r+") as file:  # Use 'r+' mode to read and write in one go
        data = json.load(file)
        data[_key] = _value
        file.seek(0)  # Move to the start of the file for writing
        json.dump(data, file, indent=4)
        file.truncate()  # Remove any leftover data from previous content if shorter
    # Ensure data is on disk
    with open(file_path, "rb") as f:  # Open in binary mode for os.fsync
        os.fsync(f.fileno())

def get_value(_key):
    file_path = os.path.join(base_dir, relative_path)
    # Small delay to ensure file system has updated
    with open(file_path, "r") as file:
        data = json.load(file)
    
    return data[_key]

def load_abi(relative_path: str) -> Dict[str, Any]:
    """Load contract ABI from a JSON file located relative to the calling file.
    
    In the calling file, Pass the relative path to the ABI file based on the module's location

    Forexample: abi = `load_abi("./.build/abi/MyContract.json")`
    >>>
    """
    base_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(base_dir, relative_path)
    
    try:
        with open(file_path, "r") as file:
            return json.load(file)
    except FileNotFoundError:
        print(f"ABI file not found at: {file_path}")
        raise
    except json.JSONDecodeError:
        print(f"Failed to decode JSON from file: {file_path}")
        raise

def get_event_topic(abi: List[Dict[str, Any]], event_name: str) -> HexBytes:
    """
    Fetch contract events and return a built event signature string.
    """
    for item in abi:
        if item.get("type") == "event" and item.get("name") == event_name:
            types = ",".join(input["type"] for input in item["inputs"])
            event_signature = f"{event_name}({types})"
            return keccak(text=event_signature)
    print(f"Event '{event_name}' not found in ABI.")
    raise ValueError(f"Event '{event_name}' not found in ABI.")

def get_event_abi(abi: List[Dict[str, Any]], event_name: str) -> Dict[str, Any]:
    """
    Fetch contract events and return the event ABI.
    """
    for item in abi:
        if item.get("type") == "event" and item.get("name") == event_name:
            return item
    print(f"Event '{event_name}' not found in ABI.")
    raise ValueError(f"Event '{event_name}' not found in ABI.")