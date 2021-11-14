// TODO:
// Hide gui when * is toggled

Speeder@ speeder = null;

void Main(){
    @speeder = Speeder();
}

void Update(float dt){
    if(speeder !is null)
        speeder.Tick();
}

void RenderInterface(){
    if(speeder !is null)
        speeder.gui.Render();
}