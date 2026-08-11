#!/usr/bin/env python3
"""Validate MATLAB algorithm templates: structure, docs, and parameter safety.

These tests verify that MATLAB templates have proper H1 help lines,
input validation, error handling, and output structure — the minimum
quality bar for competition-grade code.  They do NOT require MATLAB
to run; they parse .m source files for expected patterns.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path


MATLAB_DIR = Path(__file__).resolve().parent.parent / "assets" / "code" / "matlab"


def matlab_files() -> list[Path]:
    return sorted(MATLAB_DIR.glob("*.m"))


# ---------- Helpers ----------

def read_m(name: str) -> str:
    path = MATLAB_DIR / name
    return path.read_text(encoding="utf-8")


def has_H1(name: str) -> bool:
    """H1 line: first comment line after 'function' that describes the function."""
    text = read_m(name)
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if line.strip().startswith("function"):
            for j in range(i + 1, min(i + 5, len(lines))):
                candidate = lines[j].strip()
                if candidate.startswith("%") and len(candidate) > 3:
                    return True
    return False


def has_validateattributes(name: str) -> bool:
    return "validateattributes(" in read_m(name)


def has_help_example(name: str) -> bool:
    return "Example:" in read_m(name)


def has_error_handling(name: str) -> bool:
    text = read_m(name)
    return "try" in text or "error(" in text or "catch" in text


def has_output_struct(name: str) -> bool:
    """Check at least 3 result.field assignments."""
    text = read_m(name)
    matches = re.findall(r"result\.\w+\s*=", text)
    return len(matches) >= 3


def count_lines(name: str) -> int:
    return len(read_m(name).split("\n"))


# ---------- Test Cases ----------

class TestMatlabFilesExist(unittest.TestCase):
    """All expected MATLAB template files must be present."""

    EXPECTED = [
        "topsis.m",
        "entropy_weight.m",
        "grey_prediction.m",
        "genetic_algorithm.m",
        "particle_swarm.m",
        "linear_programming.m",
        "integer_programming.m",
        "vikor.m",
        "critic_weight.m",
        "simulated_annealing.m",
        "kalman_filter.m",
        "monte_carlo_simulation.m",
        "bootstrap_ci.m",
        "dbscan.m",
        "dijkstra.m",
        "vns.m",
        "nsga2.m",
        "random_forest.m",
    ]

    def test_all_files_present(self):
        existing = {p.name for p in matlab_files()}
        missing = [f for f in self.EXPECTED if f not in existing]
        self.assertEqual(
            missing, [],
            f"Missing MATLAB templates: {missing}. "
            f"Expected {len(self.EXPECTED)}, found {len(existing)}."
        )

    def test_no_empty_files(self):
        for path in matlab_files():
            with self.subTest(file=path.name):
                content = path.read_text(encoding="utf-8")
                self.assertGreater(len(content.strip()), 50,
                    f"{path.name} is too short (< 50 chars)")

    def test_valid_function_signature(self):
        for path in matlab_files():
            with self.subTest(file=path.name):
                content = path.read_text(encoding="utf-8")
                self.assertIn("function ", content,
                    f"{path.name} must start with a function definition")


class TestMatlabDocumentation(unittest.TestCase):
    """Every MATLAB template must have H1 line and usage examples."""

    FILES_WITH_MIN_DOC = [
        "topsis.m",
        "entropy_weight.m",
        "grey_prediction.m",
        "genetic_algorithm.m",
        "particle_swarm.m",
        "linear_programming.m",
        "integer_programming.m",
        "vikor.m",
        "critic_weight.m",
        "simulated_annealing.m",
        "kalman_filter.m",
        "monte_carlo_simulation.m",
        "bootstrap_ci.m",
        "dbscan.m",
        "dijkstra.m",
        "vns.m",
        "nsga2.m",
        "random_forest.m",
    ]

    def test_H1_help_line(self):
        for fname in self.FILES_WITH_MIN_DOC:
            with self.subTest(file=fname):
                self.assertTrue(has_H1(fname),
                    f"{fname} must have an H1 help line after 'function'")

    def test_has_example_section(self):
        for fname in self.FILES_WITH_MIN_DOC:
            with self.subTest(file=fname):
                self.assertTrue(has_help_example(fname),
                    f"{fname} must have an 'Example:' section in help text")


class TestMatlabInputValidation(unittest.TestCase):
    """All non-trivial templates must validate inputs."""

    NEEDS_VALIDATION = [
        "topsis.m",
        "entropy_weight.m",
        "grey_prediction.m",
        "genetic_algorithm.m",
        "particle_swarm.m",
        "linear_programming.m",
        "integer_programming.m",
        "vikor.m",
        "critic_weight.m",
        "simulated_annealing.m",
        "kalman_filter.m",
        "monte_carlo_simulation.m",
        "bootstrap_ci.m",
        "dbscan.m",
        "dijkstra.m",
        "vns.m",
        "nsga2.m",
        "random_forest.m",
    ]

    def test_validateattributes_present(self):
        for fname in self.NEEDS_VALIDATION:
            with self.subTest(file=fname):
                self.assertTrue(has_validateattributes(fname),
                    f"{fname} must use validateattributes() for input checking")


class TestMatlabErrorHandling(unittest.TestCase):
    """Templates must handle edge cases with explicit error()."""

    NEEDS_ERROR_HANDLING = [
        "topsis.m",
        "entropy_weight.m",
        "grey_prediction.m",
        "genetic_algorithm.m",
        "particle_swarm.m",
        "linear_programming.m",
        "integer_programming.m",
        "vikor.m",
        "critic_weight.m",
        "simulated_annealing.m",
        "kalman_filter.m",
        "monte_carlo_simulation.m",
        "bootstrap_ci.m",
        "dbscan.m",
        "vns.m",
        "nsga2.m",
        "random_forest.m",
    ]

    def test_error_handling_present(self):
        for fname in self.NEEDS_ERROR_HANDLING:
            with self.subTest(file=fname):
                self.assertTrue(has_error_handling(fname),
                    f"{fname} must have error() for edge cases or try-catch")


class TestMatlabOutputStructure(unittest.TestCase):
    """Templates must return structured output with at least 3 named fields."""

    def test_output_structure_complete(self):
        for path in matlab_files():
            fname = path.name
            with self.subTest(file=fname):
                self.assertTrue(has_output_struct(fname),
                    f"{fname} must return result struct with >= 3 named fields")


class TestMatlabMinimalSize(unittest.TestCase):
    """Check that competition-grade templates meet minimum size thresholds."""

    CORE_ALGORITHMS = [
        ("topsis.m", 80),
        ("entropy_weight.m", 80),
        ("grey_prediction.m", 80),
        ("vikor.m", 80),
    ]

    def test_minimum_lines(self):
        for fname, min_lines in self.CORE_ALGORITHMS:
            with self.subTest(file=fname):
                actual = count_lines(fname)
                self.assertGreaterEqual(actual, min_lines,
                    f"{fname}: {actual} lines < expected minimum {min_lines}")


if __name__ == "__main__":
    unittest.main()
