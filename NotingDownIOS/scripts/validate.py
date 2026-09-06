"""Fast, dependency-free repository checks. This does not replace an Xcode build."""
import ast
import json
from pathlib import Path
import re
import shutil
import subprocess
from urllib.parse import unquote
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def main():
    swift = sorted(ROOT.rglob("*.swift"))
    swift = [path for path in swift if "artifacts" not in path.parts]
    compiler = shutil.which("swiftc")
    if not compiler:
        raise RuntimeError("Install Swift (or select Xcode) to parse Swift sources.")
    subprocess.run([compiler, "-frontend", "-parse", *map(str, swift)], check=True)
    for path in (ROOT / "scripts").glob("*.py"):
        ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    model = ROOT / "NotingDown/CoreData/CoreDataModels.xcdatamodeld/CoreDataModels.xcdatamodel/contents"
    ET.parse(model)
    scheme = ET.parse(ROOT / "NotingDown.xcodeproj/xcshareddata/xcschemes/NotingDown.xcscheme")
    plutil = shutil.which("plutil")
    if not plutil:
        raise RuntimeError("plutil is required to validate the Xcode project.")
    project = json.loads(subprocess.check_output(
        [plutil, "-convert", "json", "-o", "-", "--", str(ROOT / "NotingDown.xcodeproj/project.pbxproj")],
        text=True,
    ))
    objects = project["objects"]
    target_ids = objects[project["rootObject"]]["targets"]
    targets = {objects[key]["name"]: key for key in target_ids}
    assert set(targets) == {"NotingDown", "NotingDownTests", "NotingDownUITests"}
    for ref in scheme.findall(".//BuildableReference"):
        assert ref.attrib["BlueprintIdentifier"] == targets[ref.attrib["BlueprintName"]]
    for name, target_id in targets.items():
        target = objects[target_id]
        assert target["productReference"] in objects
        for phase in target["buildPhases"]:
            assert phase in objects
        for group in target["fileSystemSynchronizedGroups"]:
            assert (ROOT / objects[group]["path"]).is_dir()
        for dependency in target["dependencies"]:
            assert objects[dependency]["target"] == targets["NotingDown"]
        configs = objects[target["buildConfigurationList"]]["buildConfigurations"]
        assert len(configs) == 2
        for config in configs:
            settings = objects[config]["buildSettings"]
            assert settings["IPHONEOS_DEPLOYMENT_TARGET"] == "16.6"
            if name == "NotingDown":
                assert settings["INFOPLIST_KEY_NSMicrophoneUsageDescription"]
                assert settings["INFOPLIST_KEY_NSSpeechRecognitionUsageDescription"]
    catalog = json.loads((ROOT / "NotingDown/Localizable.xcstrings").read_text(encoding="utf-8"))
    assert catalog["sourceLanguage"] == "en"
    for key, item in catalog["strings"].items():
        for language in ("en", "es"):
            value = item["localizations"][language]["stringUnit"]["value"]
            assert sorted(re.findall(r"%(?:lld|@)", key)) == sorted(re.findall(r"%(?:lld|@)", value)), key
    assert catalog["strings"]["Save"]["localizations"]["es"]["stringUnit"]["value"] == "Guardar"
    for readme in (ROOT / "ReadMe.md", ROOT.parent / "README.md"):
        text = readme.read_text(encoding="utf-8")
        assert "file:///" not in text, f"Machine-local link in {readme}"
        for link in re.findall(r'\]\(([^)]+)\)|src="([^"]+)"', text):
            url = next(value for value in link if value).strip("<>")
            if "://" not in url and not url.startswith("#"):
                destination = readme.parent / unquote(url.split("#")[0])
                assert destination.exists(), f"Broken link: {destination}"
    print(f"PASS: parsed {len(swift)} Swift files; project, test scheme, Core Data model, "
          f"{len(catalog['strings'])} bilingual strings, Python scripts and README links validated.")
    print("Xcode compilation, runtime tests, accessibility review and performance measurements remain separate checks.")


if __name__ == "__main__":
    main()
