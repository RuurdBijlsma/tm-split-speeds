$compress = @{
    Path = "./Oswald-Regular.ttf", "./info.toml", "./src"
    CompressionLevel = "Fastest"
    DestinationPath = "../temp.zip"
}
Compress-Archive @compress -Force

Move-Item -Path "../temp.zip" -Destination "../SplitSpeeds.op" -Force

Write-Host("Done!")
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")