#!/usr/bin/env python3
"""Construit Resources/ods9.deflate depuis le fichier words.js d'ODS9.

Le dépôt source publie la liste dans une constante JavaScript contenant un
flux gzip encodé en Base64. Ce script télécharge une révision figée, contrôle
son empreinte, valide les formes et produit le flux DEFLATE brut attendu par
Foundation. Il n'utilise que la bibliothèque standard de Python.
"""

from __future__ import annotations

import argparse
import base64
import binascii
import gzip
import hashlib
import os
from pathlib import Path
import re
import tempfile
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
import zlib


SCRIPT_VERSION = "1.0.0"
SOURCE_COMMIT = "cdb84ccf6952d8a2e240e6144895b1bca3c92380"
SOURCE_URL = (
    "https://raw.githubusercontent.com/Thecoolsim/ODS9/"
    f"{SOURCE_COMMIT}/words.js"
)
SOURCE_SHA256 = "e6dcb6b51f9ae23786b706ded689ec3e49c888dd3a08620939d0ed3b186c35a0"
WORD_DATA_SHA256 = "a3e92f5a5044229e3daad6d56152ef2c4fa9e0ec4e69805571fdeffe341ce6c7"

EXPECTED_WORD_COUNT = 416_349
EXPECTED_INDEXED_COUNT = 407_128
EXPECTED_LONG_WORD_COUNT = 9_221
MINIMUM_WORD_LENGTH = 2
MAXIMUM_WORD_LENGTH = 21
ENGINE_MAXIMUM_WORD_LENGTH = 15

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = REPOSITORY_ROOT / "Resources" / "ods9.deflate"
WORDS_JS_PATTERN = re.compile(
    rb'\A\s*const\s+WORDS_GZ\s*=\s*"([A-Za-z0-9+/=]+)";\s*\Z'
)
WORD_PATTERN = re.compile(r"[A-Z]+")
DOWNLOAD_USER_AGENT = (
    "LettresEtScores-iOS-ODS9-builder/1.0 "
    "(https://github.com/jourquin/LettresEtScores-iOS)"
)


class BuildError(RuntimeError):
    """Erreur contrôlée de téléchargement, de validation ou de génération."""


def sha256(contents: bytes) -> str:
    return hashlib.sha256(contents).hexdigest()


def verify_source(source: bytes, origin: str) -> bytes:
    actual_hash = sha256(source)

    if actual_hash != SOURCE_SHA256:
        raise BuildError(
            f"Empreinte SHA-256 inattendue pour {origin} :\n"
            f"attendue : {SOURCE_SHA256}\n"
            f"obtenue  : {actual_hash}"
        )

    return source


def download_source() -> bytes:
    request = Request(
        SOURCE_URL,
        headers={"User-Agent": DOWNLOAD_USER_AGENT},
    )

    try:
        with urlopen(request, timeout=30) as response:
            source = response.read()
    except (HTTPError, URLError, TimeoutError, OSError) as error:
        raise BuildError(f"Téléchargement impossible : {error}") from error

    return verify_source(source, SOURCE_URL)


def decode_words_js(source: bytes) -> bytes:
    match = WORDS_JS_PATTERN.fullmatch(source)

    if match is None:
        raise BuildError(
            "Format words.js non reconnu : constante WORDS_GZ absente."
        )

    try:
        compressed = base64.b64decode(match.group(1), validate=True)
        return gzip.decompress(compressed)
    except (binascii.Error, gzip.BadGzipFile, EOFError, OSError) as error:
        raise BuildError(f"Contenu gzip/Base64 invalide : {error}") from error


def normalize_and_validate(decoded: bytes) -> bytes:
    try:
        text = decoded.decode("ascii")
    except UnicodeDecodeError as error:
        raise BuildError("La liste décodée n'est pas en ASCII.") from error

    if "\r" in text:
        raise BuildError("La liste contient des fins de ligne CR/CRLF.")

    words = text.splitlines()

    if len(words) != EXPECTED_WORD_COUNT:
        raise BuildError(
            f"Nombre de formes inattendu : {len(words):,} au lieu de "
            f"{EXPECTED_WORD_COUNT:,}."
        )

    if any(WORD_PATTERN.fullmatch(word) is None for word in words):
        raise BuildError("La liste contient une forme autre que A-Z.")

    if any(
        not MINIMUM_WORD_LENGTH <= len(word) <= MAXIMUM_WORD_LENGTH
        for word in words
    ):
        raise BuildError(
            "La liste contient une forme hors des longueurs "
            f"{MINIMUM_WORD_LENGTH} à {MAXIMUM_WORD_LENGTH}."
        )

    if words != sorted(words):
        raise BuildError("La liste n'est pas triée alphabétiquement.")

    if len(set(words)) != len(words):
        raise BuildError("La liste contient des doublons.")

    indexed_count = sum(
        len(word) <= ENGINE_MAXIMUM_WORD_LENGTH for word in words
    )
    long_word_count = len(words) - indexed_count

    if indexed_count != EXPECTED_INDEXED_COUNT:
        raise BuildError(
            "Nombre de formes de 2 à 15 lettres inattendu : "
            f"{indexed_count:,}."
        )

    if long_word_count != EXPECTED_LONG_WORD_COUNT:
        raise BuildError(
            "Nombre de formes de 16 à 21 lettres inattendu : "
            f"{long_word_count:,}."
        )

    normalized = ("\n".join(words) + "\n").encode("ascii")
    actual_hash = sha256(normalized)

    if actual_hash != WORD_DATA_SHA256:
        raise BuildError(
            "Empreinte de la liste normalisée inattendue :\n"
            f"attendue : {WORD_DATA_SHA256}\n"
            f"obtenue  : {actual_hash}"
        )

    return normalized


def compress_words(word_data: bytes) -> bytes:
    compressor = zlib.compressobj(
        level=9,
        method=zlib.DEFLATED,
        wbits=-zlib.MAX_WBITS,
    )
    compressed = compressor.compress(word_data) + compressor.flush()

    try:
        round_trip = zlib.decompress(
            compressed,
            wbits=-zlib.MAX_WBITS,
        )
    except zlib.error as error:
        raise BuildError("Le flux DEFLATE généré est invalide.") from error

    if round_trip != word_data:
        raise BuildError("Le contrôle après compression a échoué.")

    return compressed


def atomic_write(destination: Path, contents: bytes) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.NamedTemporaryFile(
        prefix=f".{destination.name}.",
        suffix=".tmp",
        dir=destination.parent,
        delete=False,
    ) as temporary_file:
        temporary_path = Path(temporary_file.name)
        temporary_file.write(contents)

    try:
        os.replace(temporary_path, destination)
    finally:
        temporary_path.unlink(missing_ok=True)


def write_resource(destination: Path, word_data: bytes) -> str:
    compressed = compress_words(word_data)
    atomic_write(destination, compressed)
    return sha256(compressed)


def check_resource(resource_path: Path) -> str:
    if not resource_path.is_file():
        raise BuildError(f"Ressource introuvable : {resource_path}")

    compressed = resource_path.read_bytes()

    try:
        word_data = zlib.decompress(
            compressed,
            wbits=-zlib.MAX_WBITS,
        )
    except zlib.error as error:
        raise BuildError(f"Flux DEFLATE invalide : {resource_path}") from error

    if sha256(word_data) != WORD_DATA_SHA256:
        raise BuildError(
            "Le contenu décompressé ne correspond pas à la source figée."
        )

    words = word_data.decode("ascii").splitlines()

    if len(words) != EXPECTED_WORD_COUNT:
        raise BuildError(f"Nombre de formes inattendu : {len(words):,}.")

    indexed_count = sum(
        len(word) <= ENGINE_MAXIMUM_WORD_LENGTH for word in words
    )

    if indexed_count != EXPECTED_INDEXED_COUNT:
        raise BuildError(
            f"Nombre de formes indexables inattendu : {indexed_count:,}."
        )

    return sha256(compressed)


def parse_arguments(arguments: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Construit la ressource ODS9 DEFLATE de Lettres & Scores iOS."
        )
    )
    source_group = parser.add_mutually_exclusive_group()
    source_group.add_argument(
        "--source",
        type=Path,
        help="fichier words.js local à utiliser sans téléchargement",
    )
    source_group.add_argument(
        "--check",
        action="store_true",
        help="contrôle la ressource existante sans réseau ni modification",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"ressource à produire ou contrôler (défaut : {DEFAULT_OUTPUT})",
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {SCRIPT_VERSION}",
    )
    return parser.parse_args(arguments)


def main(arguments: list[str] | None = None) -> int:
    options = parse_arguments(arguments)
    output_path = options.output.expanduser().resolve()

    if output_path.suffix.lower() != ".deflate":
        print("Erreur : --output doit désigner un fichier .deflate.")
        return 2

    try:
        if options.check:
            resource_hash = check_resource(output_path)
            print(f"OK : {output_path}")
            print("416 349 formes, dont 407 128 indexées par l'application")
            print(f"SHA-256 de la ressource : {resource_hash}")
            return 0

        if options.source is None:
            print(f"Téléchargement de {SOURCE_URL}")
            source = download_source()
        else:
            source_path = options.source.expanduser().resolve()
            source = verify_source(
                source_path.read_bytes(),
                str(source_path),
            )

        word_data = normalize_and_validate(decode_words_js(source))
        resource_hash = write_resource(output_path, word_data)
        check_resource(output_path)

        print(f"Ressource créée : {output_path}")
        print("416 349 formes, dont 407 128 indexées par l'application")
        print(f"SHA-256 de la ressource : {resource_hash}")
        return 0
    except (BuildError, OSError, UnicodeError) as error:
        print(f"Erreur : {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
