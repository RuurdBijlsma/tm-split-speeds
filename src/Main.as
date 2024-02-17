// TODO 
// Make session best dings
// Test other games
// Test multiplayer, editor, solo, training, etc alles
// edit campaign map is stuk ofzo? sometimes n editor validation of maps that are/are modified campaign maps, the split will save as 0


void Main() {
    print("MAIN YEP");
    Map::Main();
}

void Render() {
}

void Update(float dt) {
    Detector::Update();
    Waypoint::Update();
    Race::Update();
    Map::Update();
}