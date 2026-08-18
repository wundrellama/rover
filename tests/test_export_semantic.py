import re
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "bin" / "export-semantic.py"
ROVER_ACT = ROOT / "desk" / "lib" / "rover-act.hoon"
SCHEMA = ROOT / "docs" / "schema-m0.sql"


def declared_primary_keys():
    source = "\n".join(
        path.read_text(encoding="utf-8") for path in (ROVER_ACT, SCHEMA)
    )
    return {
        relation: [column.strip() for column in columns.split(",")]
        for relation, columns in re.findall(
            r"CREATE TABLE rover\.\.([a-z0-9-]+).*?PRIMARY KEY \(([^)]+)\)",
            source,
            re.DOTALL,
        )
    }


class CountQueryTest(unittest.TestCase):
    def test_count_queries_select_each_exported_relations_primary_key(self):
        completed = subprocess.run(
            [
                "python3",
                str(HELPER),
                "count-sql",
                str(ROVER_ACT),
                str(SCHEMA),
                "--chunk-size",
                "1",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        queries = completed.stdout.splitlines()
        relations = subprocess.run(
            ["python3", str(HELPER), "relations", str(ROVER_ACT)],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.splitlines()

        self.assertEqual(101, len(queries))
        self.assertEqual(relations, [query.split()[1] for query in queries])
        keys = declared_primary_keys()
        for relation, query in zip(relations, queries):
            match = re.fullmatch(
                rf"FROM {re.escape(relation)} X SELECT (.+);", query
            )
            self.assertIsNotNone(match, query)
            selected = [
                column.strip().removeprefix("X.")
                for column in match.group(1).split(",")
            ]
            self.assertEqual(keys[relation], selected, relation)

        self.assertEqual(
            "FROM odometer-observations X SELECT X.odometer-id;",
            queries[relations.index("odometer-observations")],
        )
        self.assertEqual(
            "FROM fuel-fill-tags X SELECT X.acquisition-id, X.tag-id;",
            queries[relations.index("fuel-fill-tags")],
        )


if __name__ == "__main__":
    unittest.main()
