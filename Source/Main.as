// TODO:
// Optimizations!
// GUI
void Main()
{
    auto speeder = Speeder();
    speeder.Init();
    while(true){
        speeder.Tick();
        yield();
    }
}