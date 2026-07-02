using UnrealBuildTool;

public class AssemblyNotIncludedGenerator : ModuleRules
{
    public AssemblyNotIncludedGenerator(ReadOnlyTargetRules Target) : base(Target)
    {
        PCHUsage = PCHUsageMode.NoPCHs;
        PrivateDefinitions.Add("__has_feature(x)=0");
        PublicDependencyModuleNames.AddRange(new[] { "Core", "CoreUObject", "Engine" });
        PrivateDependencyModuleNames.AddRange(new[]
        {
            "AssetRegistry",
            "BlueprintGraph",
            "Kismet",
            "Slate",
            "SlateCore",
            "UMG",
            "UMGEditor",
            "UnrealEd"
        });
    }
}
