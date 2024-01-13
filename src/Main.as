// TODO 
// Make session best dings
// Test other games
// Test multiplayer, editor, solo, training, etc alles

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