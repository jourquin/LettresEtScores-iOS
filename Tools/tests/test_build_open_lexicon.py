import importlib.util
import tempfile
import unittest
import zipfile
from collections import Counter
from pathlib import Path


SCRIPT_PATH = Path(__file__).resolve().parents[1] / "build_open_lexicon.py"
SPEC = importlib.util.spec_from_file_location("build_open_lexicon", SCRIPT_PATH)
assert SPEC is not None
assert SPEC.loader is not None
builder = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(builder)


class NormalizeFormTests(unittest.TestCase):
    def test_normalizes_accents_and_ligatures(self):
        self.assertEqual(builder.normalize_form("été"), ("ETE", None))
        self.assertEqual(builder.normalize_form("cœur"), ("COEUR", None))
        self.assertEqual(builder.normalize_form("cæcum"), ("CAECUM", None))

    def test_rejects_non_simple_forms(self):
        self.assertEqual(
            builder.normalize_form("arc-en-ciel"),
            (None, "not_simple"),
        )
        self.assertEqual(
            builder.normalize_form("l'été"),
            (None, "not_simple"),
        )
        self.assertEqual(
            builder.normalize_form("j3"),
            (None, "not_simple"),
        )

    def test_rejects_unsupported_characters_and_lengths(self):
        self.assertEqual(
            builder.normalize_form("µcal"),
            (None, "unsupported_character"),
        )
        self.assertEqual(builder.normalize_form("a"), (None, "too_short"))
        self.assertEqual(
            builder.normalize_form("abcdefghijklmnop"),
            (None, "too_long"),
        )


class ReproducibleArchiveTests(unittest.TestCase):
    def test_archive_is_reproducible_and_self_describing(self):
        statistics = Counter({"unique_words": 2, "source_rows": 2})

        with tempfile.TemporaryDirectory() as directory:
            first = Path(directory) / "first.zip"
            second = Path(directory) / "second.zip"

            builder.write_output_archive(
                first,
                ["CHAT", "CHATS"],
                "Texte de licence\n",
                statistics,
            )
            builder.write_output_archive(
                second,
                ["CHAT", "CHATS"],
                "Texte de licence\n",
                statistics,
            )

            self.assertEqual(first.read_bytes(), second.read_bytes())

            with zipfile.ZipFile(first) as archive:
                self.assertEqual(
                    set(archive.namelist()),
                    {
                        builder.OUTPUT_WORDS_MEMBER,
                        builder.OUTPUT_NOTICE_MEMBER,
                        builder.OUTPUT_LICENSE_MEMBER,
                        builder.OUTPUT_MANIFEST_MEMBER,
                    },
                )
                self.assertEqual(
                    archive.read(builder.OUTPUT_WORDS_MEMBER),
                    b"CHAT\nCHATS\n",
                )


if __name__ == "__main__":
    unittest.main()
