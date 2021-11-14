// TODO:
// Hide gui when * is toggled
void Main()
{
    auto speeder = Speeder();
    while(true){
        speeder.Tick();
        yield();
    }
}