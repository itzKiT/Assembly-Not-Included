#include "Modules/ModuleManager.h"

#include "AssetRegistry/AssetRegistryModule.h"
#include "WidgetBlueprint.h"
#include "Blueprint/WidgetBlueprintGeneratedClass.h"
#include "Blueprint/WidgetTree.h"
#include "Components/Border.h"
#include "Components/Button.h"
#include "Components/CanvasPanel.h"
#include "Components/CanvasPanelSlot.h"
#include "Components/HorizontalBox.h"
#include "Components/HorizontalBoxSlot.h"
#include "Components/ScrollBox.h"
#include "Components/SizeBox.h"
#include "Components/Slider.h"
#include "Components/TextBlock.h"
#include "Components/VerticalBox.h"
#include "Components/VerticalBoxSlot.h"
#include "Components/WrapBox.h"
#include "Components/WrapBoxSlot.h"
#include "Engine/Blueprint.h"
#include "GameFramework/Actor.h"
#include "Kismet2/BlueprintEditorUtils.h"
#include "Kismet2/KismetEditorUtilities.h"
#include "Containers/Ticker.h"
#include "EdGraphSchema_K2.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "UObject/Package.h"
#include "UObject/SavePackage.h"

namespace
{
const TCHAR* PackageRoot = TEXT("/Game/Mods/AssemblyNotIncluded");

FText Text(const FString& Value)
{
    return FText::FromString(Value);
}

void SaveAsset(UObject* Asset)
{
    if (!Asset)
    {
        return;
    }

    UPackage* Package = Asset->GetOutermost();
    FAssetRegistryModule::AssetCreated(Asset);
    Package->MarkPackageDirty();

    const FString Filename = FPackageName::LongPackageNameToFilename(
        Package->GetName(),
        FPackageName::GetAssetPackageExtension());

    FSavePackageArgs Args;
    Args.TopLevelFlags = RF_Public | RF_Standalone;
    Args.SaveFlags = SAVE_NoError;
    UPackage::SavePackage(Package, Asset, *Filename, Args);
}

UTextBlock* MakeText(UWidgetTree* Tree, const FName Name, const FString& Label, int32 Size, const FLinearColor Color)
{
    UTextBlock* Widget = Tree->ConstructWidget<UTextBlock>(UTextBlock::StaticClass(), Name);
    Widget->SetText(Text(Label));
    Widget->SetColorAndOpacity(FSlateColor(Color));
    FSlateFontInfo Font = Widget->GetFont();
    Font.Size = Size;
    Widget->SetFont(Font);
    return Widget;
}

void AddVertical(UVerticalBox* Box, UWidget* Widget, const FMargin& Padding = FMargin(0.0f, 3.0f))
{
    UVerticalBoxSlot* Slot = Box->AddChildToVerticalBox(Widget);
    Slot->SetPadding(Padding);
    Slot->SetHorizontalAlignment(HAlign_Fill);
}

UButton* MakeButton(UWidgetTree* Tree, UWrapBox* Row, const FName Name, const FString& Label)
{
    UButton* Button = Tree->ConstructWidget<UButton>(UButton::StaticClass(), Name);
    Button->bIsVariable = true;
    Button->SetBackgroundColor(FLinearColor(0.13f, 0.018f, 0.075f, 1.0f));

    UTextBlock* Caption = MakeText(
        Tree,
        FName(*(Name.ToString() + TEXT("_Label"))),
        Label,
        16,
        FLinearColor(1.0f, 0.94f, 0.97f, 1.0f));
    Caption->bIsVariable = true;
    Caption->SetJustification(ETextJustify::Center);
    Button->AddChild(Caption);

    UWrapBoxSlot* Slot = Row->AddChildToWrapBox(Button);
    Slot->SetPadding(FMargin(5.0f));
    Slot->SetHorizontalAlignment(HAlign_Fill);
    Slot->SetVerticalAlignment(VAlign_Fill);
    Slot->SetFillSpanWhenLessThan(240.0f);
    return Button;
}

void AddButtons(UWidgetTree* Tree, UWrapBox* Row, const TArray<TPair<FString, FString>>& Buttons)
{
    for (const TPair<FString, FString>& Entry : Buttons)
    {
        MakeButton(Tree, Row, FName(*Entry.Key), Entry.Value);
    }
}

USlider* AddTuningSlider(
    UWidgetTree* Tree,
    UVerticalBox* Content,
    const FName SliderName,
    const FName ValueName,
    const FString& Label,
    const FString& Range)
{
    UHorizontalBox* Header = Tree->ConstructWidget<UHorizontalBox>(
        UHorizontalBox::StaticClass(),
        FName(*(SliderName.ToString() + TEXT("_Header"))));

    UTextBlock* Caption = MakeText(
        Tree,
        FName(*(SliderName.ToString() + TEXT("_Caption"))),
        Label,
        15,
        FLinearColor(1.0f, 0.94f, 0.97f, 1.0f));
    UHorizontalBoxSlot* CaptionSlot = Header->AddChildToHorizontalBox(Caption);
    CaptionSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
    CaptionSlot->SetHorizontalAlignment(HAlign_Left);

    UTextBlock* Value = MakeText(
        Tree,
        ValueName,
        TEXT("1.00x"),
        15,
        FLinearColor(1.0f, 0.16f, 0.55f, 1.0f));
    Value->bIsVariable = true;
    Value->SetJustification(ETextJustify::Right);
    UHorizontalBoxSlot* ValueSlot = Header->AddChildToHorizontalBox(Value);
    ValueSlot->SetSize(FSlateChildSize(ESlateSizeRule::Automatic));
    ValueSlot->SetHorizontalAlignment(HAlign_Right);
    AddVertical(Content, Header, FMargin(3.0f, 4.0f, 3.0f, 0.0f));

    USlider* Slider = Tree->ConstructWidget<USlider>(
        USlider::StaticClass(),
        SliderName);
    Slider->bIsVariable = true;
    Slider->SetMinValue(0.0f);
    Slider->SetMaxValue(1.0f);
    Slider->SetValue(0.5f);
    Slider->SetStepSize(0.01f);
    Slider->SetIndentHandle(true);
    Slider->SetSliderBarColor(FLinearColor(0.34f, 0.04f, 0.18f, 1.0f));
    Slider->SetSliderHandleColor(FLinearColor(1.0f, 0.04f, 0.45f, 1.0f));
    AddVertical(Content, Slider, FMargin(3.0f, 3.0f, 3.0f, 0.0f));

    UTextBlock* Hint = MakeText(
        Tree,
        FName(*(SliderName.ToString() + TEXT("_Hint"))),
        Range,
        11,
        FLinearColor(0.69f, 0.55f, 0.63f, 1.0f));
    Hint->SetJustification(ETextJustify::Right);
    AddVertical(Content, Hint, FMargin(3.0f, 0.0f, 3.0f, 3.0f));
    return Slider;
}

void AddVehicleTuningControls(UWidgetTree* Tree, UWrapBox* Row)
{
    USizeBox* Card = Tree->ConstructWidget<USizeBox>(
        USizeBox::StaticClass(),
        TEXT("VehicleTuningCard"));
    Card->SetWidthOverride(500.0f);

    UBorder* Backdrop = Tree->ConstructWidget<UBorder>(
        UBorder::StaticClass(),
        TEXT("VehicleTuningBackdrop"));
    Backdrop->SetBrushColor(FLinearColor(0.055f, 0.008f, 0.032f, 1.0f));
    Backdrop->SetPadding(FMargin(9.0f, 7.0f));
    Card->AddChild(Backdrop);

    UVerticalBox* Content = Tree->ConstructWidget<UVerticalBox>(
        UVerticalBox::StaticClass(),
        TEXT("VehicleTuningContent"));
    Backdrop->AddChild(Content);

    UTextBlock* Title = MakeText(
        Tree,
        TEXT("VehicleTuningTitle"),
        TEXT("LIVE TIRE GRIP TUNE"),
        16,
        FLinearColor(1.0f, 0.18f, 0.58f, 1.0f));
    AddVertical(Content, Title, FMargin(3.0f, 0.0f, 3.0f, 3.0f));

    AddTuningSlider(
        Tree,
        Content,
        TEXT("Slider_TireGrip"),
        TEXT("TireGripValue"),
        TEXT("TIRE GRIP"),
        TEXT("0.50x     STOCK     2.00x"));

    UButton* Reset = Tree->ConstructWidget<UButton>(
        UButton::StaticClass(),
        TEXT("Btn_ResetVehicleTune"));
    Reset->bIsVariable = true;
    Reset->SetBackgroundColor(FLinearColor(0.26f, 0.012f, 0.12f, 1.0f));
    Reset->AddChild(MakeText(
        Tree,
        TEXT("Btn_ResetVehicleTune_Label"),
        TEXT("RESET ACTIVE VEHICLE GRIP"),
        14,
        FLinearColor::White));
    AddVertical(Content, Reset, FMargin(3.0f, 6.0f, 3.0f, 2.0f));

    UWrapBoxSlot* Slot = Row->AddChildToWrapBox(Card);
    Slot->SetPadding(FMargin(5.0f));
    Slot->SetHorizontalAlignment(HAlign_Fill);
    Slot->SetFillEmptySpace(true);
    Slot->SetFillSpanWhenLessThan(520.0f);
}

UButton* AddWideButton(
    UWidgetTree* Tree,
    UVerticalBox* Content,
    const FName Name,
    const FString& Label,
    const FLinearColor Color,
    int32 FontSize = 17)
{
    UButton* Button = Tree->ConstructWidget<UButton>(UButton::StaticClass(), Name);
    Button->bIsVariable = true;
    Button->SetBackgroundColor(Color);
    UTextBlock* Caption = MakeText(
        Tree,
        FName(*(Name.ToString() + TEXT("_Label"))),
        Label,
        FontSize,
        FLinearColor(1.0f, 0.95f, 0.98f, 1.0f));
    Caption->SetJustification(ETextJustify::Center);
    Button->AddChild(Caption);
    AddVertical(Content, Button, FMargin(3.0f, 4.0f));
    return Button;
}

UWrapBox* AddCollapsible(
    UWidgetTree* Tree,
    UVerticalBox* Content,
    const FString& Id,
    const FString& Label)
{
    AddWideButton(
        Tree,
        Content,
        FName(*(TEXT("Btn_Toggle") + Id)),
        TEXT("+  ") + Label,
        FLinearColor(0.20f, 0.018f, 0.105f, 1.0f),
        18);

    UWrapBox* Panel = Tree->ConstructWidget<UWrapBox>(
        UWrapBox::StaticClass(),
        FName(*(TEXT("Panel_") + Id)));
    Panel->bIsVariable = true;
    Panel->SetInnerSlotPadding(FVector2D(3.0f, 3.0f));
    Panel->SetVisibility(ESlateVisibility::Collapsed);
    AddVertical(Content, Panel, FMargin(8.0f, 2.0f, 8.0f, 5.0f));
    return Panel;
}

UWidgetBlueprint* CreateMenuWidget()
{
    const FString PackageName = FString(PackageRoot) + TEXT("/WBP_AssemblyNotIncluded");
    UPackage* Package = CreatePackage(*PackageName);
    UWidgetBlueprint* Blueprint = Cast<UWidgetBlueprint>(FKismetEditorUtilities::CreateBlueprint(
        UUserWidget::StaticClass(),
        Package,
        TEXT("WBP_AssemblyNotIncluded"),
        BPTYPE_Normal,
        UWidgetBlueprint::StaticClass(),
        UWidgetBlueprintGeneratedClass::StaticClass()));

    if (!Blueprint || !Blueprint->WidgetTree)
    {
        return nullptr;
    }

    UWidgetTree* Tree = Blueprint->WidgetTree;
    UCanvasPanel* Root = Tree->ConstructWidget<UCanvasPanel>(
        UCanvasPanel::StaticClass(),
        TEXT("Root"));
    Tree->RootWidget = Root;

    UBorder* Backdrop = Tree->ConstructWidget<UBorder>(
        UBorder::StaticClass(),
        TEXT("Backdrop"));
    Backdrop->SetBrushColor(FLinearColor(0.004f, 0.003f, 0.006f, 0.99f));
    Backdrop->SetPadding(FMargin(14.0f));
    UCanvasPanelSlot* BackdropSlot = Root->AddChildToCanvas(Backdrop);
    BackdropSlot->SetAnchors(FAnchors(0.5f, 0.5f));
    BackdropSlot->SetAlignment(FVector2D(0.5f, 0.5f));
    BackdropSlot->SetPosition(FVector2D::ZeroVector);
    BackdropSlot->SetSize(FVector2D(560.0f, 680.0f));

    UVerticalBox* Layout = Tree->ConstructWidget<UVerticalBox>(
        UVerticalBox::StaticClass(),
        TEXT("Layout"));
    Backdrop->AddChild(Layout);

    UTextBlock* Title = MakeText(
        Tree,
        TEXT("Title"),
        TEXT("ASSEMBLY NOT INCLUDED"),
        27,
        FLinearColor(1.0f, 0.08f, 0.48f, 1.0f));
    Title->SetJustification(ETextJustify::Center);
    AddVertical(Layout, Title, FMargin(3.0f, 0.0f, 3.0f, 1.0f));

    UTextBlock* Subtitle = MakeText(
        Tree,
        TEXT("Subtitle"),
        TEXT("F7"),
        13,
        FLinearColor(0.78f, 0.64f, 0.71f, 1.0f));
    Subtitle->SetJustification(ETextJustify::Center);
    AddVertical(Layout, Subtitle, FMargin(3.0f, 0.0f, 3.0f, 8.0f));

    UScrollBox* Scroll = Tree->ConstructWidget<UScrollBox>(
        UScrollBox::StaticClass(),
        TEXT("MenuScroll"));
    UVerticalBoxSlot* ScrollSlot = Layout->AddChildToVerticalBox(Scroll);
    ScrollSlot->SetSize(FSlateChildSize(ESlateSizeRule::Fill));
    ScrollSlot->SetHorizontalAlignment(HAlign_Fill);

    UVerticalBox* Content = Tree->ConstructWidget<UVerticalBox>(
        UVerticalBox::StaticClass(),
        TEXT("MenuContent"));
    Scroll->AddChild(Content);

    AddWideButton(
        Tree,
        Content,
        TEXT("Btn_OpenItemCatalog"),
        TEXT("ITEM SPAWNER"),
        FLinearColor(0.76f, 0.012f, 0.30f, 1.0f),
        20);

    UWrapBox* Barrels = AddCollapsible(
        Tree, Content, TEXT("Barrels"), TEXT("FULL BARRELS"));
    AddButtons(Tree, Barrels, {
        {TEXT("Btn_BarrelPetrol"), TEXT("Petrol  |  100 L")},
        {TEXT("Btn_BarrelDiesel"), TEXT("Diesel  |  100 L")},
        {TEXT("Btn_BarrelOil"), TEXT("Oil  |  20 L")},
        {TEXT("Btn_BarrelWater"), TEXT("Water  |  100 L")}
    });

    UWrapBox* Paint = AddCollapsible(
        Tree, Content, TEXT("Paint"), TEXT("PAINT STUDIO"));
    AddButtons(Tree, Paint, {
        {TEXT("Btn_OpenPaintStudio"), TEXT("CHOOSE COLOR & SPAWN  |  AUTO-SAVES")},
        {TEXT("Btn_PaintStandard"), TEXT("Next Can: Standard")},
        {TEXT("Btn_PaintInfinite"), TEXT("Next Can: Infinite")},
        {TEXT("Btn_InfinitePaint"), TEXT("Max Existing Cans")}
    });
    AddButtons(Tree, Paint, {
        {TEXT("Btn_PaintSwatch1"), TEXT("SAVED 1  |  EMPTY")},
        {TEXT("Btn_PaintSwatch2"), TEXT("SAVED 2  |  EMPTY")},
        {TEXT("Btn_PaintSwatch3"), TEXT("SAVED 3  |  EMPTY")},
        {TEXT("Btn_PaintSwatch4"), TEXT("SAVED 4  |  EMPTY")},
        {TEXT("Btn_PaintSwatch5"), TEXT("SAVED 5  |  EMPTY")},
        {TEXT("Btn_PaintSwatch6"), TEXT("SAVED 6  |  EMPTY")},
        {TEXT("Btn_PaintSwatch7"), TEXT("SAVED 7  |  EMPTY")},
        {TEXT("Btn_PaintSwatch8"), TEXT("SAVED 8  |  EMPTY")},
        {TEXT("Btn_ClearPaintSwatches"), TEXT("Clear Saved Swatches")}
    });

    UWrapBox* Vehicles = AddCollapsible(
        Tree, Content, TEXT("Vehicles"), TEXT("COMPLETED VEHICLES"));
    AddButtons(Tree, Vehicles, {
        {TEXT("Btn_Car_C18"), TEXT("C18")},
        {TEXT("Btn_Car_Caddie"), TEXT("Caddie")},
        {TEXT("Btn_Car_Escada"), TEXT("Escada")},
        {TEXT("Btn_Car_P51"), TEXT("P-51")},
        {TEXT("Btn_Car_Loft"), TEXT("Loft")},
        {TEXT("Btn_Car_Golf"), TEXT("Golf")},
        {TEXT("Btn_Car_GTR"), TEXT("GTR")},
        {TEXT("Btn_Car_IFA"), TEXT("IFA")},
        {TEXT("Btn_Car_Kage"), TEXT("Kage")},
        {TEXT("Btn_Car_Dada"), TEXT("Dada")},
        {TEXT("Btn_Car_Tomahawk"), TEXT("Tomahawk")},
        {TEXT("Btn_Car_Musgoat"), TEXT("Musgoat")},
        {TEXT("Btn_Car_Peak"), TEXT("Peak")},
        {TEXT("Btn_Car_Bonphiac"), TEXT("Bonphiac")},
        {TEXT("Btn_Car_Poyopa"), TEXT("Poyopa")},
        {TEXT("Btn_Car_Speedle"), TEXT("Speedle")},
        {TEXT("Btn_Car_TriClops"), TEXT("TriClops")},
        {TEXT("Btn_Car_UAZ"), TEXT("UAZ")},
        {TEXT("Btn_Car_Toilet"), TEXT("Toilet Car")},
        {TEXT("Btn_Car_HotDog"), TEXT("Hot-Dog Trailer")},
        {TEXT("Btn_Car_Trailer"), TEXT("Trailer")}
    });

    UWrapBox* VehicleTools = AddCollapsible(
        Tree, Content, TEXT("VehicleTools"), TEXT("ACTIVE VEHICLE"));
    AddButtons(Tree, VehicleTools, {
        {TEXT("Btn_VehicleInfo"), TEXT("Inspect Vehicle")},
        {TEXT("Btn_VehicleInvulnerable"), TEXT("Invulnerability")},
        {TEXT("Btn_VehicleFill"), TEXT("Fill Fluids")},
        {TEXT("Btn_VehicleInfinite"), TEXT("Unlimited Fluids")},
        {TEXT("Btn_RechargeBatteries"), TEXT("Recharge Batteries")},
        {TEXT("Btn_VehicleClean"), TEXT("Polish Vehicle")},
        {TEXT("Btn_VehicleRemoveRust"), TEXT("Remove Rust")},
        {TEXT("Btn_VehicleRust"), TEXT("Rust Vehicle")},
        {TEXT("Btn_SuperSubwoofer"), TEXT("Long-Range Speaker")}
    });
    AddVehicleTuningControls(Tree, VehicleTools);

    UWrapBox* Player = AddCollapsible(
        Tree, Content, TEXT("Player"), TEXT("PLAYER"));
    AddButtons(Tree, Player, {
        {TEXT("Btn_Speed"), TEXT("Roadrunner Speed")},
        {TEXT("Btn_Jump"), TEXT("Moon Jump")},
        {TEXT("Btn_Health"), TEXT("Refill Health")},
        {TEXT("Btn_Hunger"), TEXT("Refill Hunger")},
        {TEXT("Btn_Thirst"), TEXT("Refill Thirst")},
        {TEXT("Btn_PissFull"), TEXT("Fill Bladder")},
        {TEXT("Btn_PissEmpty"), TEXT("Empty Bladder")}
    });

    UWrapBox* World = AddCollapsible(
        Tree, Content, TEXT("World"), TEXT("TIME & WEATHER"));
    AddButtons(Tree, World, {
        {TEXT("Btn_TimeDawn"), TEXT("Dawn")},
        {TEXT("Btn_TimeNoon"), TEXT("Noon")},
        {TEXT("Btn_TimeDusk"), TEXT("Dusk")},
        {TEXT("Btn_TimeNight"), TEXT("Night")},
        {TEXT("Btn_WeatherClear"), TEXT("Clear")},
        {TEXT("Btn_WeatherStorm"), TEXT("Storm")},
        {TEXT("Btn_WeatherSnow"), TEXT("Rain")},
        {TEXT("Btn_WeatherTrueSnow"), TEXT("Snow")}
    });

    UTextBlock* QuickLabel = MakeText(
        Tree,
        TEXT("QuickLabel"),
        TEXT("QUICK TOOLS"),
        14,
        FLinearColor(0.92f, 0.40f, 0.67f, 1.0f));
    AddVertical(Content, QuickLabel, FMargin(8.0f, 10.0f, 8.0f, 2.0f));

    UWrapBox* Quick = Tree->ConstructWidget<UWrapBox>(
        UWrapBox::StaticClass(),
        TEXT("Panel_Quick"));
    Quick->SetInnerSlotPadding(FVector2D(3.0f, 3.0f));
    AddVertical(Content, Quick, FMargin(5.0f, 0.0f, 5.0f, 5.0f));
    AddButtons(Tree, Quick, {
        {TEXT("Btn_InfiniteBrushes"), TEXT("Unlimited Brushes")},
        {TEXT("Btn_InfiniteAmmo"), TEXT("Unlimited AK Ammo")},
        {TEXT("Btn_AddMoney"), TEXT("Add $5,000")},
        {TEXT("Btn_RemoveMoney"), TEXT("Remove $5,000")},
        {TEXT("Btn_SpawnZombie"), TEXT("Spawn Zombie")},
        {TEXT("Btn_DestroyTarget"), TEXT("Destroy Look Target")}
    });

    UButton* Close = Tree->ConstructWidget<UButton>(
        UButton::StaticClass(),
        TEXT("Btn_Close"));
    Close->bIsVariable = true;
    Close->SetBackgroundColor(FLinearColor(0.34f, 0.008f, 0.12f, 1.0f));
    Close->AddChild(MakeText(
        Tree,
        TEXT("Btn_Close_Label"),
        TEXT("CLOSE"),
        16,
        FLinearColor::White));
    AddVertical(Layout, Close, FMargin(3.0f, 8.0f, 3.0f, 1.0f));

    Tree->ForEachWidget([Blueprint](UWidget* Widget)
    {
        UButton* Button = Cast<UButton>(Widget);
        if (!Button || !Button->GetFName().ToString().StartsWith(TEXT("Btn_")))
        {
            return;
        }

        const FString Suffix = Button->GetFName().ToString().RightChop(4);
        const FName HandlerName(*(TEXT("ANI_") + Suffix));
        UEdGraph* Graph = FBlueprintEditorUtils::CreateNewGraph(
            Blueprint,
            HandlerName,
            UEdGraph::StaticClass(),
            UEdGraphSchema_K2::StaticClass());
        FBlueprintEditorUtils::AddFunctionGraph<UFunction>(
            Blueprint,
            Graph,
            true,
            static_cast<UFunction*>(nullptr));

        FDelegateEditorBinding Binding;
        Binding.ObjectName = Button->GetName();
        Binding.PropertyName = TEXT("OnClicked");
        Binding.FunctionName = HandlerName;
        Binding.Kind = EBindingKind::Function;
        Blueprint->Bindings.Add(Binding);
    });

    FBlueprintEditorUtils::MarkBlueprintAsStructurallyModified(Blueprint);
    FKismetEditorUtilities::CompileBlueprint(Blueprint);
    SaveAsset(Blueprint);
    return Blueprint;
}

UWidgetBlueprint* CreateSpeedometerWidget()
{
    const FString PackageName =
        FString(PackageRoot) + TEXT("/WBP_AssemblyNotIncludedSpeedometer");
    UPackage* Package = CreatePackage(*PackageName);
    UWidgetBlueprint* Blueprint =
        Cast<UWidgetBlueprint>(FKismetEditorUtilities::CreateBlueprint(
            UUserWidget::StaticClass(),
            Package,
            TEXT("WBP_AssemblyNotIncludedSpeedometer"),
            BPTYPE_Normal,
            UWidgetBlueprint::StaticClass(),
            UWidgetBlueprintGeneratedClass::StaticClass()));

    if (!Blueprint || !Blueprint->WidgetTree)
    {
        return nullptr;
    }

    UWidgetTree* Tree = Blueprint->WidgetTree;
    UCanvasPanel* Root = Tree->ConstructWidget<UCanvasPanel>(
        UCanvasPanel::StaticClass(),
        TEXT("SpeedometerRoot"));
    Tree->RootWidget = Root;

    UBorder* Accent = Tree->ConstructWidget<UBorder>(
        UBorder::StaticClass(),
        TEXT("SpeedometerAccent"));
    Accent->SetBrushColor(FLinearColor(1.0f, 0.02f, 0.43f, 0.94f));
    Accent->SetPadding(FMargin(2.0f));

    UCanvasPanelSlot* AccentSlot = Root->AddChildToCanvas(Accent);
    AccentSlot->SetAnchors(FAnchors(1.0f, 1.0f));
    AccentSlot->SetAlignment(FVector2D(1.0f, 1.0f));
    AccentSlot->SetPosition(FVector2D(-36.0f, -112.0f));
    AccentSlot->SetSize(FVector2D(270.0f, 100.0f));

    UBorder* Backdrop = Tree->ConstructWidget<UBorder>(
        UBorder::StaticClass(),
        TEXT("SpeedometerBackdrop"));
    Backdrop->SetBrushColor(FLinearColor(0.004f, 0.003f, 0.008f, 0.93f));
    Backdrop->SetPadding(FMargin(12.0f, 8.0f));
    Accent->AddChild(Backdrop);

    UVerticalBox* Layout = Tree->ConstructWidget<UVerticalBox>(
        UVerticalBox::StaticClass(),
        TEXT("SpeedometerLayout"));
    Backdrop->AddChild(Layout);

    UTextBlock* Label = MakeText(
        Tree,
        TEXT("SpeedometerLabel"),
        TEXT("VEHICLE SPEED"),
        12,
        FLinearColor(1.0f, 0.16f, 0.55f, 1.0f));
    Label->SetJustification(ETextJustify::Center);
    AddVertical(Layout, Label, FMargin(0.0f, 0.0f, 0.0f, 1.0f));

    UTextBlock* Value = MakeText(
        Tree,
        TEXT("SpeedValue"),
        TEXT("000  KM/H"),
        32,
        FLinearColor(1.0f, 0.96f, 0.98f, 1.0f));
    Value->bIsVariable = true;
    Value->SetJustification(ETextJustify::Center);
    AddVertical(Layout, Value, FMargin(0.0f));

    FBlueprintEditorUtils::MarkBlueprintAsStructurallyModified(Blueprint);
    FKismetEditorUtilities::CompileBlueprint(Blueprint);
    SaveAsset(Blueprint);
    return Blueprint;
}

UBlueprint* CreateModActor()
{
    const FString PackageName = FString(PackageRoot) + TEXT("/ModActor");
    UPackage* Package = CreatePackage(*PackageName);
    UBlueprint* Blueprint = FKismetEditorUtilities::CreateBlueprint(
        AActor::StaticClass(),
        Package,
        TEXT("ModActor"),
        BPTYPE_Normal,
        UBlueprint::StaticClass(),
        UBlueprintGeneratedClass::StaticClass());
    if (Blueprint)
    {
        FBlueprintEditorUtils::MarkBlueprintAsStructurallyModified(Blueprint);
        FKismetEditorUtilities::CompileBlueprint(Blueprint);
        SaveAsset(Blueprint);
    }
    return Blueprint;
}

void GenerateAssets()
{
    UE_LOG(LogTemp, Display, TEXT("Assembly Not Included: generating clean-room assets"));
    CreateModActor();
    CreateMenuWidget();
    CreateSpeedometerWidget();
    UE_LOG(LogTemp, Display, TEXT("Assembly Not Included: asset generation complete"));
}
}

class FAssemblyNotIncludedGeneratorModule final : public IModuleInterface
{
public:
    virtual void StartupModule() override
    {
        if (FParse::Param(FCommandLine::Get(), TEXT("GenerateAssemblyNotIncludedAssets")))
        {
            FTSTicker::GetCoreTicker().AddTicker(
                FTickerDelegate::CreateLambda([](float)
                {
                    GenerateAssets();
                    RequestEngineExit(TEXT("Assembly Not Included assets generated"));
                    return false;
                }),
                1.0f);
        }
    }
};

IMPLEMENT_MODULE(FAssemblyNotIncludedGeneratorModule, AssemblyNotIncludedGenerator)
