[Setting name="Synchronize split speeds with PB" category="General" description="Delete stored speed splits when they do not match your PB time. With this disabled the speed splits are stored permanently."]
bool keepSync = true;

enum CompareType {
    PersonalBest,
    SessionBest,
}

[Setting name="What speed should be compared" category="General" description="Show comparison to your personal best or your session best. Session best resets when a new map loads."]
CompareType compareType = CompareType::PersonalBest;

[Setting name="Show current speed at cp" category="UI"]
bool showCurrentSpeed = true;

[Setting name="Show difference to pb speed at cp" category="UI"]
bool showSpeedDiff = true;

[Setting name="Text shadow" category="UI"]
bool textShadow = false;

[Setting name="Dense UI" category="UI"]
bool denseUI = false;

[Setting name="Show when GUI is hidden" category="UI"]
bool showWhenGuiHidden = false;

[Setting name="Use native TM colours (blue / red)" category="UI"]
bool nativeColours = false;

[Setting color name="Text colour" category="UI"]
vec4 textColour = vec4(1, 1, 1, 1);

[Setting name="Show decimal in current speed" category="UI"]
bool showSpeedDecimal = false;

[Setting name="Show decimal in speed difference" category="UI"]
bool showSplitDecimal = false;


#if MP4

[Setting name="Use world speed instead of front speed" category="General" description="World speed takes into account your sideways speed, it is more accurate when drifting or sliding sideways"]
bool useWorldSpeed = true;

[Setting color name="Use different anchor position for online" category="UI"]
bool useOnlinePos = true;

[Setting name="UI Scale" min=0.1 max=2 category="UI"]
float scale = 1.15;

[Setting name="Anchor X position" min=0 max=1 category="UI"]
float anchorX = .501;
[Setting name="Online anchor X position" min=0 max=1 category="UI"]
float anchorXOnline = 0.4995;

[Setting name="Anchor Y position" min=0 max=1 category="UI"]
float anchorY = .251;
[Setting name="Online anchor Y position" min=0 max=1 category="UI"]
float anchorYOnline = 0.677;

[Setting color name="Faster than pb colour" category="UI"]
vec4 fasterColour = vec4(0, .479, .011, .812);

[Setting color name="Slower than pb colour" category="UI"]
vec4 slowerColour = vec4(.761, .38, 0, .75);

[Setting color name="Current speed background colour" category="UI"]
vec4 textBgColour = vec4(0, 0, 0, 0.761);

#elif TMNEXT

[Setting name="UI Scale" min=0.1 max=2 category="UI"]
float scale = 1;

[Setting name="Anchor X position" min=0 max=1 category="UI"]
float anchorX = .49458;

[Setting name="Anchor Y position" min=0 max=1 category="UI"]
float anchorY = .249;

[Setting color name="Faster than pb colour" category="UI"]
vec4 fasterColour = vec4(0, .63, .12, .75);

[Setting color name="Slower than pb colour" category="UI"]
vec4 slowerColour = vec4(1, .5, 0, .75);

[Setting color name="Current speed background colour" category="UI"]
vec4 textBgColour = vec4(0, 0, 0, 0.867);

#elif TURBO

[Setting name="UI Scale" min=0.1 max=2 category="UI"]
float scale = 1;

[Setting name="Anchor X position" min=0 max=1 category="UI"]
float anchorX = .501;

[Setting name="Anchor Y position" min=0 max=1 category="UI"]
float anchorY = .251;

[Setting color name="Faster than pb colour" category="UI"]
vec4 fasterColour = vec4(0, .63, .12, .75);

[Setting color name="Slower than pb colour" category="UI"]
vec4 slowerColour = vec4(1, .5, 0, .75);

[Setting color name="Current speed background colour" category="UI"]
vec4 textBgColour = vec4(0, 0, 0, 0.867);
#endif
