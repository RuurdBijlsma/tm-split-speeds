$compress = @{
    Path = "./sugo-pro.ttf", "./info.toml", "./Source"
    CompressionLevel = "Fastest"
    DestinationPath = "../SplitSpeeds.zip"
}
Compress-Archive @compress -Force

Rename-Item -Path "../SplitSpeeds.zip" -NewName "SplitSpeeds.op"

$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")