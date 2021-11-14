$compress = @{
    Path = "./sugo-pro.ttf", "./info.toml", "./Source"
    CompressionLevel = "Fastest"
    DestinationPath = "../SplitSpeeds.zip"
}
Compress-Archive @compress -Force

Move-Item -Path "../SplitSpeeds.zip" -Destination "../SplitSpeeds.op" -Force

Write-Host("Done!")
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")