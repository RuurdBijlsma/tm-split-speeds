[Setting name="Show current speed at cp"]
bool showCurrentSpeed = true;

[Setting name="Show difference to pb speed at cp"]
bool showSpeedDiff = true;

[Setting name="Anchor X position" min=0 max=1]
float anchorX = .49458;

[Setting name="Anchor Y position" min=0 max=1]
float anchorY = .249;

[Setting name="Use native TM colours (blue / red)"]
bool nativeColours = false;

[Setting color name="Faster than pb colour"]
vec4 fasterColour = vec4(0, .63, .12, .75);

[Setting color name="Slower than pb colour"]
vec4 slowerColour = vec4(1, .5, 0, .75);

vec4 sameSpeedColour = vec4(.5, .5, .5, .75);

vec4 textBgColour = vec4(0, 0, 0, 0.86);
vec4 textColour = vec4(1, 1, 1, 1);
vec4 shadowColour = vec4( 0, 0, 0, .5);
Resources::Font@ font;

int shadowX = 1;
int shadowY = 1;
int fontSize = 43;

class GUI{
    float currentSpeed = 0;
    float difference = 0;
    bool hasDiff = false;
    bool showDiff = false;
    bool guiHidden = false;

    GUI(){
	    @font = Resources::GetFont("sugo-pro.ttf");
    }

    void Render(){
        if(nativeColours){
            fasterColour = vec4(0, .15, 1, .75);
            slowerColour = vec4(.83, 0, 0, .75);
        }

        if(!showDiff || guiHidden)
            return;
        uint box1Width = 67;
        uint box2Width = 78;
        uint boxHeight = 58;
        uint padding = 7;
        uint x = uint(anchorX * Draw::GetWidth());
        uint y = uint(anchorY * Draw::GetHeight() - boxHeight / 2);
        // Draw current speed
        if(showCurrentSpeed){
            // Draw box
            nvg::BeginPath();
            nvg::Rect(x - box1Width, y, box1Width, boxHeight);
            nvg::FillColor(textBgColour);
            nvg::Fill();
            nvg::ClosePath();
            // Draw text
            nvg::FontFace(font);
            string text = Text::Format("%.0f", currentSpeed);
            nvg::TextAlign(nvg::Align::Right | nvg::Align::Middle);
            nvg::FontSize(fontSize);
            nvg::FillColor(shadowColour);
            nvg::TextBox(x - box1Width + shadowX, y + boxHeight / 2 + shadowY, box1Width - padding, text);
            nvg::FillColor(textColour);
            nvg::TextBox(x - box1Width, y + boxHeight / 2, box1Width - padding, text);
        }
        // Draw difference
        if(showSpeedDiff && hasDiff){
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
            nvg::FontFace(font);
            string text = Text::Format("%.0f", difference);
            if(difference < 1 && difference > -1)
                text = '0';
            nvg::TextAlign(nvg::Align::Right | nvg::Align::Middle);
            nvg::FontSize(fontSize);
            nvg::FillColor(shadowColour);
            nvg::TextBox(x + shadowX, y + boxHeight / 2 + shadowY, box2Width - padding, text);
            nvg::FillColor(textColour);
            nvg::TextBox(x, y + boxHeight / 2, box2Width - padding, text);
        }
    }
}