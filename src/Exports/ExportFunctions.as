namespace SplitSpeeds {
    bool get_visible() {
        return GUI::visible;
    }
    bool get_hasDifference() {
        return GUI::hasDiff;
    }

    float get_speed() {
        return GUI::currentSpeed;
    }
    float get_difference() {
        return GUI::difference;
    }
    string get_differenceText() {
        return GUI::diffText;
    }
    string get_speedText() {
        return GUI::speedText;
    }

    vec4 get_slowerColour() {
        return slowerColour;
    }
    vec4 get_fasterColour() {
        return fasterColour;
    }
    vec4 get_sameSpeedColour() {
        return GUI::sameSpeedColour;
    }
    vec4 get_currentColour() {
        return GUI::currentColour;
    }
}