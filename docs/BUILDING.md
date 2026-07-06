# Building from source

## Requirements

- Windows
- Unreal Engine 5.2.1
- PowerShell 5.1 or later

## Asset project

Open:

```text
Source\Unreal\AssemblyNotIncluded.uproject
```

The editor-only `AssemblyNotIncludedGenerator` plugin owns the reproducible widget and actor generation source. Enable it only when regenerating assets. Its output belongs under:

```text
/Game/Mods/AssemblyNotIncluded
```

Disable the generator before cooking.

## Release build

From the repository root:

```powershell
.\Scripts\Build-Release.ps1 -EngineRoot "D:\Program Files\Epic Games\UE_5.2"
```

The script:

1. Cleans generated Unreal output.
2. Cooks only the Assembly Not Included assets.
3. Builds a minimal IoStore logic-mod container.
4. Combines the container with the runtime tested against the [zDEV UE4SS experimental-latest build](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest) at Git SHA `c2ac2464`.
5. Produces `artifacts\AssemblyNotIncluded-v0.6.6.zip`.
6. Rejects unexpected package files or inconsistent identifiers.

The project source does not include game assets, UE4SS, or the signature-bypass files.
