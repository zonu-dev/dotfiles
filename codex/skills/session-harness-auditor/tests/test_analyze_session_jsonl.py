import json
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "analyze_session_jsonl.py"


class AnalyzeSessionJsonlTest(unittest.TestCase):
    def run_analyzer(self, output: str) -> str:
        event = {
            "type": "response_item",
            "payload": {"type": "function_call_output", "output": output},
        }
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "session.jsonl"
            path.write_text(json.dumps(event) + "\n", encoding="utf-8")
            return subprocess.check_output(["python3", str(SCRIPT), str(path)], text=True)

    def test_reports_oversized_output(self):
        report = self.run_analyzer(
            "Original token count: 100001 Total output lines: 10001"
        )
        self.assertIn("## Oversized Tool Outputs", report)
        self.assertIn("original_tokens=100001, output_lines=10001", report)

    def test_ignores_output_at_threshold(self):
        report = self.run_analyzer(
            "Original token count: 100000 Total output lines: 10000"
        )
        self.assertIn("- No oversized tool outputs detected.", report)


if __name__ == "__main__":
    unittest.main()
