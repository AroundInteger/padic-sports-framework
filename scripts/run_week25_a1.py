#!/usr/bin/env python3
"""Run FOUNDATION.md §8 week 2.5 — Dominion Q1, Q3, Q5, Q8."""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from pipeline.padic_pef.a1_experiments import main

if __name__ == "__main__":
    main()
