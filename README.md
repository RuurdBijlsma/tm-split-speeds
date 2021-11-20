This plugin shows your current speed and your speed difference to your personal best at checkpoint splits, similar to how you can see your time and time difference to your PB in the base game.

## Configuration
This plugin has a few tweakable settings:
* Colour shown when ahead of pb speed (default is green).
* Colour shown when behind pb speed (default is orange).
* Whether to show only the difference in speed, the current speed, or both.
* Toggle to show anyways when GUI is hidden.

## Changelog
### 0.2.7
* Store pb speeds when retiring on a map with no pb yet, similar to time splits
* Use the font the game uses (Oswald Regular)

### 0.2.6
* Synchronize splits with actual pb splits on solo maps.
* Fix stretched resolution scaling.
* Fix overlay not showing when Openplanet F3 overlay is off.
* Add size slider.
* Add button to clear stored speeds for current map or all maps.

## Source code
The source code of this plugin is [on GitHub](https://github.com/RuurdBijlsma/tm-split-speeds).

## Limitations
* You have to have driven a PB while having this plugin installed for it to register. PB speeds per map are stored in the Openplanet user folder.
* The speeds can vary by at most ~.5 km/h, this isn't a big issue since the speeds are rounded to the nearest integer anyways. It's possible to see a speed difference of 1 km/h on pf maps because of this.
