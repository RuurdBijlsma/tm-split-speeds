namespace GUI {
    vec4 currentColour = vec4(0, 0, 0, 0);
    vec4 sameSpeedColour = vec4(.5, .5, .5, .75);
    vec4 shadowColour = vec4(0, 0, 0, .6);
    nvg::Font font;

    int shadowX = 1;
    int shadowY = 1;
    int fontSize = 34;

    float currentSpeed = 0;
    float difference = 0;
    uint showTime = 0;
    bool visible = false;
    bool hasDiff = false;
    bool enabled = true;
    string diffText = "";
    string speedText = "";

    void Initialize() {
	    font = nvg::LoadFont("Oswald-Regular.ttf");
    }

    void Render() {
        if(nativeColours){
            fasterColour = vec4(0, .123, .822, .75);
            slowerColour = vec4(.869, 0.117, 0.117, .784);
        }

        // showTime is the time when the ui element was shown
        visible = Time::Now < showTime + 3000;
        diffText = Text::Format(showSplitDecimal ? "%.1f" : "%.0f", difference);
        if(difference < (showSplitDecimal ? 0.1 : 1) && difference > (showSplitDecimal ? -0.1 : -1))
            diffText = '0';
        speedText = Text::Format(showSpeedDecimal ? "%.1f" : "%.0f", currentSpeed);
        currentColour = sameSpeedColour;
        if(difference > (showSplitDecimal ? 0.1 : 1)) currentColour = fasterColour;
        else if(difference < (showSplitDecimal ? -0.1 : -1)) currentColour = slowerColour;
    
        if(!UI::IsGameUIVisible() && !showWhenGuiHidden)
            return;

        if(font == 0) return;
        if(!enabled) return;
        if(!visible) return;

        float h = float(Draw::GetHeight());
        float w = float(Draw::GetWidth());
        // if h or w is 0, game is minimized
        if(h == 0) return;
        if(w == 0) return;
        float scaleX, scaleY, offsetX = 0;
        if(w / h > 16. / 9) {
            auto correctedW = (h / 9.) * 16;
            scaleX = correctedW / 2560;
            scaleY = h / 1440;
            offsetX = (w - correctedW) / 2;
        } else {
            scaleX = w / 2560;
            scaleY = h / 1440;
        }

        nvg::Save();
        nvg::Translate(offsetX, 0);
        nvg::Scale(scaleX, scaleY);
        RenderDefaultUI();
        nvg::Restore();
    }

    void RenderDefaultUI() {
        uint box1Width = uint(scale * (showSpeedDecimal ? 70 : 67));
        uint box2Width = uint(scale * (showSpeedDecimal ? 74 : 77));
        uint boxHeight = uint(scale * 57);
        uint padding = 7;
        bool online = (GetApp()).PlaygroundScript is null;
#if TMNEXT || TURBO
        float anchorXOnline = anchorX;
        float anchorYOnline = anchorY;
        bool useOnlinePos = false;
#endif
        uint x = uint(((online && useOnlinePos) ? anchorXOnline : anchorX) * 2560) + (showSpeedDecimal ? 4 : 1);
#if MP4
        x -= showSpeedDecimal ? 4 : 1;
#endif
        uint y = uint(((online && useOnlinePos) ? anchorYOnline : anchorY) * 1440 - boxHeight / 2);
        nvg::FontFace(font);

        int denseAdjustment = 0;
        uint textOffsetY = 3;
        if(denseUI) {
            boxHeight = uint(scale * 40);
            textOffsetY = 3;
            y += 17;
            denseAdjustment = -5;
        }

        // Draw current speed
        if(showCurrentSpeed) {
            auto charSurplus = Math::Max(0, speedText.Length - 3);
            nvg::FontSize(scale * (fontSize + denseAdjustment - charSurplus * 2.75));
            auto padding1 = padding - charSurplus * 1.5;
            if(denseUI) {
                padding1 += 6;
            }

            // Draw box
            nvg::BeginPath();
            nvg::Rect(x - box1Width, y, box1Width, boxHeight);
            nvg::FillColor(textBgColour);
            nvg::Fill();
            nvg::ClosePath();
            // Draw text
            nvg::TextAlign(nvg::Align::Left | nvg::Align::Middle);


            if(textShadow){
                nvg::FillColor(shadowColour);
                nvg::TextBox(x + padding1 - box1Width + shadowX, y + boxHeight / 2 + shadowY + textOffsetY, box1Width, speedText);
            }
            nvg::FillColor(textColour);
            nvg::TextBox(x + padding1 - box1Width, y + boxHeight / 2 + textOffsetY, box1Width, speedText);
        }
        // Draw difference
#if TMNEXT
        int marginBetween = 0;
#elif TURBO
        int marginBetween = 0;
#elif MP4
        int marginBetween = 3;
#endif
        if(showSpeedDiff && hasDiff) {
            auto charSurplus = Math::Max(0, diffText.Length - 4);
            nvg::FontSize(scale * (fontSize + denseAdjustment - charSurplus * 2.75));
            padding -= int(charSurplus * 2.5);
            if(denseUI) {
                padding += 6;
            }

            // Draw box
            nvg::BeginPath();
            nvg::Rect(marginBetween + x, y, box2Width, boxHeight);
            nvg::FillColor(currentColour);
            nvg::Fill();
            nvg::ClosePath();
            // Draw text
            nvg::TextAlign(nvg::Align::Right | nvg::Align::Middle);

            if(textShadow) {
                nvg::FillColor(shadowColour);
                nvg::TextBox(marginBetween + x - padding + shadowX, y + boxHeight / 2 + shadowY + textOffsetY, box2Width, diffText);
            }
            nvg::FillColor(textColour);
            nvg::TextBox(marginBetween + x - padding, y + boxHeight / 2 + textOffsetY, box2Width, diffText);
        }
    }
}
