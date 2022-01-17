[Setting name="Show current speed at cp" category="General"]
bool showCurrentSpeed = true;

[Setting name="Show difference to pb speed at cp" category="General"]
bool showSpeedDiff = true;

[Setting name="Text shadow" category="General"]
bool textShadow = false;

[Setting name="Dense UI" category="General"]
bool denseUI = false;

[Setting name="UI Scale" min=0.1 max=2 category="General"]
float scale = 1;

[Setting name="Anchor X position" min=0 max=1 category="General"]
float anchorX = .49458;

[Setting name="Anchor Y position" min=0 max=1 category="General"]
float anchorY = .249;

[Setting name="Show when GUI is hidden" category="General"]
bool showWhenGuiHidden = false;

[Setting name="Use native TM colours (blue / red)" category="General"]
bool nativeColours = false;

[Setting color name="Faster than pb colour" category="General"]
vec4 fasterColour = vec4(0, .63, .12, .75);

[Setting color name="Slower than pb colour" category="General"]
vec4 slowerColour = vec4(1, .5, 0, .75);

[Setting color name="Current speed background colour" category="General"]
vec4 textBgColour = vec4(0, 0, 0, 0.867);

[Setting color name="Text colour" category="General"]
vec4 textColour = vec4(1, 1, 1, 1);

vec4 sameSpeedColour = vec4(.5, .5, .5, .75);
vec4 shadowColour = vec4(0, 0, 0, .6);
Resources::Font@ font;

int shadowX = 1;
int shadowY = 1;
int fontSize = 34;

class GUI {
    float currentSpeed = 0;
    float difference = 0;
    bool hasDiff = false;
    bool showDiff = false;
    bool guiHidden = false;
    bool visible = true;

    GUI() {
	    @font = Resources::GetFont("Oswald-Regular.ttf");
    }

    void Render() {
        if(nativeColours){
            fasterColour = vec4(0, .123, .822, .75);
            slowerColour = vec4(.869, 0.117, 0.117, .784);
        }

        if(!showDiff || (guiHidden && !showWhenGuiHidden) || !visible)
            return;

        float scaleX = float(Draw::GetWidth()) / 2560;
        float scaleY = float(Draw::GetHeight()) / 1440;

        nvg::Save();
        nvg::Scale(scaleX, scaleY);
        RenderDefaultUI();
        nvg::Restore();
    }

    void RenderDefaultUI() {
        uint box1Width = uint(scale * 67);
        uint box2Width = uint(scale * 78);
        uint boxHeight = uint(scale * 57);
        uint padding = 7;
        uint x = uint(anchorX * 2560);
        uint y = uint(anchorY * 1440 - boxHeight / 2);
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
            string text = Text::Format("%.0f", currentSpeed);
            nvg::TextAlign(nvg::Align::Right | nvg::Align::Middle);
            if(textShadow){
                nvg::FillColor(shadowColour);
                nvg::TextBox(x - box1Width + shadowX - padding, y + boxHeight / 2 + shadowY + textOffsetY, box1Width, text);
            }
            nvg::FillColor(textColour);
            nvg::TextBox(x - box1Width - padding, y + boxHeight / 2 + textOffsetY, box1Width, text);
        }
        // Draw difference
        if(showSpeedDiff && hasDiff) {
            // Draw box
            nvg::BeginPath();
            nvg::Rect(x, y, box2Width, boxHeight);
            vec4 boxColour = slowerColour;
            if(difference > 1)
                boxColour = fasterColour;
            else if(difference < 1 && difference > -1)
                boxColour = sameSpeedColour;
            nvg::FillColor(boxColour);
            nvg::Fill();
            nvg::ClosePath();
            // Draw text
            string text = Text::Format("%.0f", difference);
            if(difference < 1 && difference > -1)
                text = '0';
            nvg::TextAlign(nvg::Align::Right | nvg::Align::Middle);
            if(textShadow) {
                nvg::FillColor(shadowColour);
                nvg::TextBox(x + shadowX - padding, y + boxHeight / 2 + shadowY + textOffsetY, box2Width, text);
            }
            nvg::FillColor(textColour);
            nvg::TextBox(x - padding, y + boxHeight / 2 + textOffsetY, box2Width, text);
        }
    }
}