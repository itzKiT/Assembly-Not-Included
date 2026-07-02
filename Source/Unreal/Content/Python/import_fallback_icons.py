import os
import unreal

project_dir = unreal.Paths.project_dir()
source_dir = os.path.join(project_dir, "IconSources")
destination = "/Game/Mods/AssemblyNotIncluded/Icons"

tasks = []
for filename in sorted(os.listdir(source_dir)):
    if not filename.lower().endswith(".png"):
        continue
    task = unreal.AssetImportTask()
    task.filename = os.path.join(source_dir, filename)
    task.destination_path = destination
    task.destination_name = os.path.splitext(filename)[0]
    task.automated = True
    task.replace_existing = True
    task.replace_existing_settings = True
    task.save = True
    tasks.append(task)

unreal.AssetToolsHelpers.get_asset_tools().import_asset_tasks(tasks)
unreal.EditorAssetLibrary.save_directory(destination, only_if_is_dirty=False, recursive=True)
print("ASSEMBLY_NOT_INCLUDED_ICON_IMPORT_COUNT={}".format(len(tasks)))

