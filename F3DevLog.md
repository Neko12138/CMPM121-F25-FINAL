# CMPM121-F25-FINAL F3

## Selected requirements

[continuous inventory]: We chose this requirement because we already have a key in inventory; we just need to make it a continuously held item.

[touchscreen]: This is the easiest (or most feasible) requirement among the remaining ones, so we chose it.

[i18n + l10n]: We have people on our team who understand Chinese, so it will be relatively simple to implement.

[unlimited undo]: We already have a "restart" function; to do "undo," we only need to extract the part from the "restart" function.

## How we satisfied the software requirements

[Continuous Inventory]: We've broken down the original keys into multiple parts and changed the player's task from finding the keys to finding all the keys. This allows the key progress to accumulate continuously. Furthermore, the unlocking requirement has changed from True or False to based on the number of keys collected.

[Touchscreen]: The touchscreen uses virtualButtons to generate several virtual buttons on the screen and connects them to the corresponding functions of existing buttons. Most importantly, when the player releases the virtual button, it performs the opposite function. For example, pressing a button accelerates, and releasing it adds speed in the opposite direction.

[i18n + l10n]: Each UI element's required text is bound to a variable corresponding to a text library, divided into three different modules. Variables are entered where text needs to be displayed. Then, L is given the function to switch modules, enabling quick language switching. Theoretically, it supports more languages.

[Unlimited Undo]: We previously had "Restart," and undo's function is very similar to "Restart." The only difference is that the player's position cannot be changed, and time cannot be restarted. Therefore, we identified the parts of the "Reopen" function that needed to be retained and assigned them to the "Undo" function.

## Reflection

Keith Kida:Looking back on the F3 requirements, we originally wanted to do save system instead of touck screen system, however due to unable to fully utilize the save data, we decided to go with the touch screen since it seemed more easier to implement

Jeffery Mei:In F3, to meet the first requirement of the F3 Requirements, we changed one of the gameplay mechanics. Instead of having only one real key in our three rooms, players now need to collect all the keys from the three rooms to return to the main room and unlock the restriction on the red block. Additionally, we added several different features to enhance the player experience. For example, language switching, an unlimited undo function, and support for touch-based movement on touchscreen computers. The implementation of these features added diversity to our game.

Wade Xu:After F2, I started planning what requirements to include early on. Because we were using the Love2D platform, some requirements were limited. Continuous inventory and multiple languages ​​were things we decided to do from the beginning. Infinite undo was also decided later after confirming the effects to be implemented. However, because the remaining requirements were relatively difficult, we had a hard time making a decision. The save system was originally relatively simple, but due to "Intentional Game Design," implementing a save system was difficult and almost useless. Furthermore, Love2D requires reading the Windows registry to load system themes, so visual themes could not be implemented. In the end, we chose a touch screen and borrowed other people's computers for testing and recording.
