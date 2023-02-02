#if DEPENDENCY_DID

vec4 DIDColor = vec4(0,0,0,0);
string DIDTextTotal = "";
string DIDTextDiff = "";

class SplitSpeedDID : DID::LaneProvider {
	DID::LaneProviderSettings@ getProviderSetup() {
		DID::LaneProviderSettings settings;
		settings.author = "RuteNL";
		settings.internalName = "SplitSpeeds/TotalSpeed";
		settings.friendlyName = "Split Speeds (Current)";
		return settings;
	}

	DID::LaneConfig@ getLaneConfig(DID::LaneConfig@ &in defaults) {
		DID::LaneConfig c = defaults;
		c.content = DIDTextTotal;
		return c;
	}
}

class SplitSpeedDiffDID : DID::LaneProvider {
	DID::LaneProviderSettings@ getProviderSetup() {
		DID::LaneProviderSettings settings;
		settings.author = "RuteNL";
		settings.internalName = "SplitSpeeds/SpeedDelta";
		settings.friendlyName = "Split Speeds (Difference)";
		return settings;
	}

	DID::LaneConfig@ getLaneConfig(DID::LaneConfig@ &in defaults) {
		DID::LaneConfig c = defaults;
		c.content = DIDTextDiff;
        c.color = DIDColor;
		return c;
	}
}
#endif
