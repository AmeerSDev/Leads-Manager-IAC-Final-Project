import importlib
import json
import sys
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[3]
APP_DIR = ROOT_DIR / "app"

if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))


def test_leads_manager_persistence(monkeypatch, tmp_path):
    # point the app to a temp data file so we don't touch repo files
    data_file = tmp_path / "leads.json"
    monkeypatch.setenv("LEADS_DATA_FILE", str(data_file))
    leads_mod = importlib.reload(importlib.import_module("LeadsManager"))

    # start with dummy data persisted
    initial = leads_mod.Get()
    assert len(initial) >= 1
    assert data_file.exists()

    # add a lead and ensure it persists
    new_lead = {"name": "Test", "last_name": "User", "deal-id": 42, "is_active": True, "est_value": 1234}
    leads_mod.Add(leads_mod.Get(), new_lead)
    with data_file.open() as f:
        persisted = json.load(f)
    assert any(item["deal-id"] == 42 for item in persisted)

    # close the deal and ensure state saved
    leads_mod.CloseDeal(leads_mod.Get(), 42)
    with data_file.open() as f:
        persisted = json.load(f)
    assert any(item["deal-id"] == 42 and item["is_active"] is False for item in persisted)
