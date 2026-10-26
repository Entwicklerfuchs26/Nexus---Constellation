#!/usr/bin/env python3
"""
Skill Tree MCP Server — liest/schreibt Skills über die Skill-Tree-Backend-API
(Express, Port 3001, data/skills.json). Voraussetzung: skill-tree.service läuft.
"""

import httpx
from fastmcp import FastMCP

URL = "http://127.0.0.1:3001"
mcp = FastMCP("SkillTree")


@mcp.tool()
def get_skills() -> list:
    """Alle Skills aus dem Skill Tree abrufen (id, name, gruppe, status,
    fortschritt 0-100, messkriterien/Notizen, parent)."""
    r = httpx.get(f"{URL}/api/skills", timeout=10)
    return r.json() or []


@mcp.tool()
def update_skill(id: str, status: str | None = None, fortschritt: int | None = None,
                  messkriterien: str | None = None, completed: bool | None = None) -> dict:
    """Einen Skill anhand seiner ID ändern.
    status: 'aktiv' oder 'gesperrt' (freigeschaltet/gesperrt).
    fortschritt: 0-100.
    messkriterien: Notizen/Messkriterien-Text.
    completed: Bequemlichkeits-Flag — true setzt fortschritt auf 100.
    Nur übergebene Felder werden geändert, der Rest bleibt unverändert."""
    skills = httpx.get(f"{URL}/api/skills", timeout=10).json() or []
    skill = next((s for s in skills if s["id"] == id), None)
    if skill is None:
        return {"error": f"Skill '{id}' nicht gefunden"}

    if status is not None:
        skill["status"] = status
    if fortschritt is not None:
        skill["fortschritt"] = fortschritt
    if messkriterien is not None:
        skill["messkriterien"] = messkriterien
    if completed:
        skill["fortschritt"] = 100

    httpx.put(f"{URL}/api/skills", json=skills, timeout=10)
    return skill


if __name__ == "__main__":
    mcp.run()
