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
        diffText = Text::Format("%.0f", difference);
        if(difference < 1 && difference > -1)
            diffText = '0';
        speedText = Text::Format("%.0f", currentSpeed);
        currentColour = sameSpeedColour;
        if(difference > 1) currentColour = fasterColour;
        else if(difference < -1) currentColour = slowerColour;
    
        if(!UI::IsGameUIVisible() && !showWhenGuiHidden)
            return;

        if(font == 0) return;
        if(!enabled) return;
        if(!visible) return;

        float h = float(Draw::GetHeight());
        float w = float(Draw::GetWidth());
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
        uint box1Width = uint(scale * 67);
        uint box2Width = uint(scale * 78);
        uint boxHeight = uint(scale * 57);
        uint padding = 7;
        bool online = (GetApp()).PlaygroundScript is null;
#if TMNEXT
        float anchorXOnline = anchorX;
        float anchorYOnline = anchorY;
#endif
        uint x = uint((online ? anchorXOnline : anchorX) * 2560);
        uint y = uint((online ? anchorYOnline : anchorY) * 1440 - boxHeight / 2);
        uint textOffsetY = 0;
        nvg::FontFace(font);

        if(denseUI) {
            boxHeight = uint(scale * 40);
            nvg::FontSize(scale * fontSize - 5);
            textOffsetY = 3;
            y += 17;
        } else {
            nvg::FontSize(scale * fontSize);
            textOffsetY = 3;
        }

        // Draw current speed
        if(showCurrentSpeed) {
            // Draw box
            nvg::BeginPath();
            nvg::Rect(x - box1Width, y, box1Width, boxHeight);
            nvg::FillColor(textBgColour);
            nvg::Fill();
            nvg::ClosePath();
            // Draw text
            nvg::TextAlign(nvg::Align::Right | nvg::Align::Middle);
            if(textShadow){
                nvg::FillColor(shadowColour);
                nvg::TextBox(x - box1Width + shadowX - padding, y + boxHeight / 2 + shadowY + textOffsetY, box1Width, speedText);
            }
            nvg::FillColor(textColour);
            nvg::TextBox(x - box1Width - padding, y + boxHeight / 2 + textOffsetY, box1Width, speedText);
        }
        // Draw difference
#if TMNEXT
        int marginBetween = 0;
#elif MP4
        int marginBetween = 3;
#endif
        if(showSpeedDiff && hasDiff) {
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
                nvg::TextBox(marginBetween + x + shadowX - padding, y + boxHeight / 2 + shadowY + textOffsetY, box2Width, diffText);
            }
            nvg::FillColor(textColour);
            nvg::TextBox(marginBetween + x - padding, y + boxHeight / 2 + textOffsetY, box2Width, diffText);
        }
    }
}
