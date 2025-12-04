import json
import os
import threading

DATA_FILE = os.environ.get("LEADS_DATA_FILE", os.path.join(os.path.dirname(__file__), "leads_data.json"))
_lock = threading.Lock()

_dummy_data = [
    {"name": "John", "last_name": "Doe", "deal-id": 1, "is_active": True, "est_value": 5000},
    {"name": "Jane", "last_name": "Smith", "deal-id": 2, "is_active": True, "est_value": 7500},
    {"name": "Sam", "last_name": "Lee", "deal-id": 3, "is_active": False, "est_value": 3200},
]


def _ensure_data_file():
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    if not os.path.exists(DATA_FILE):
        _save_inventory(_dummy_data)


def _load_inventory():
    _ensure_data_file()
    try:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
            if isinstance(data, list):
                return data
    except Exception:
        pass
    return list(_dummy_data)


def _save_inventory(data):
    with _lock:
        with open(DATA_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)


inventory = _load_inventory()


def Get():
    return inventory


def Add(inventory, item):
    item["is_active"] = IsDealActive(inventory, item["deal-id"])
    validate_item(item)
    inventory.append(item)
    _save_inventory(inventory)
    return inventory


def Remove(inventory, itemid):
    if 0 <= itemid < len(inventory):
        inventory.pop(itemid)
        _save_inventory(inventory)
    return inventory


def Update(inventory, itemid, new_item):
    validate_item(new_item)
    if 0 <= itemid < len(inventory):
        inventory[itemid] = new_item
        _save_inventory(inventory)
    return inventory


def CloseDeal(inventory, itemid):
    changed = False
    for item in inventory:
        if item["deal-id"] == itemid:
            item["is_active"] = False
            changed = True
    if changed:
        _save_inventory(inventory)
    return inventory


def IsDealActive(inventory, itemid):
    for item in inventory:
        if item["deal-id"] == itemid:
            return item["is_active"]
    return True


def validate_item(item):
    required_fields = ["name", "last_name", "deal-id", "is_active", "est_value"]
    for field in required_fields:
        if field not in item:
            raise ValueError(f"Missing required field: {field}")
    return True
