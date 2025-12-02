# CMPM121-F25-FINAL F2

## How we satisfied the software requirements

1.We adopted the 3D rendering and physics simulation libraries used in F1.

2.This project implements a room-switching system that allows players to move freely between multiple rooms. The program defines four independent rooms (main, room1, room2, room3) and has written a dedicated world-building function for each room. Players can click the room button at the bottom of the screen to trigger `enterRoom(name)`. This allows players to enter different rooms at any time to explore, fully fulfilling the requirement of "allowing players to move between multiple scenes".

3.Pressing the spacebar triggers the detection of nearby objects. In rooms 1, 2, and 3, players can enter the yellow interactive area and use the spacebar to "select" the area to check for the presence of keys. These interactions all depend on the player approaching and triggering objects.

4.Keys acquired by the player in a room are recorded as `hasKey = true` and displayed in the HUD's Inventory UI. Most importantly, the key acquisition status directly affects the puzzle progress in the main room. 5. Players cannot unlock the wooden crate without the key. Once the key is added to the Inventory, the crate can be successfully unlocked.

6.Players must find the key within the maze room to unlock the crate. Once unlocked, the crate transforms from a static object into a dynamic one, which can be pushed or dragged by the player using the physics system. Players need to utilize realistic physics effects, such as inertia, collision, and movement limitations, to accurately move the crate to the designated green target area to solve the puzzle.

7.The puzzle-solving process contains no randomness; it relies entirely on the player's skill and strategy to strategically control the character's movement and the direction of the physical dragging of the crate, guiding it through obstacles in confined spaces to reach the target area. Running out of time results in failure, while successfully pushing the crate into the target area is considered a success.

8.The game explicitly includes at least two triggerable endings: Success (when the crate is pushed to the green target area) and Fail (when time runs out and the objective is not achieved). The system will set gameState to success or fail and clearly display the final result on the HUD, while prompting the player to press the R key to restart the game.

## Reflection

Keith Kida:Looking back on my F2, we were originally going plan on having more rooms and have keys in each one to move to a different room which ultimately lead to a key to move the crate in the main room. However, due to that plan take too much time to make as well as may take too long to complete with a timer, we ultimately chose to have the player go to different rooms to find the keys needed.

Jeffery Mei:In the early stages of conception, our team's theme was to push the sphere into a specific area to be successful in solving the puzzle.  As development progresses, our general thinking has not changed.  Just replace the sphere with a square.  The second is to add some challenge to the puzzles.  We added some preconditions.  Players need to find keys to push the square to win.  Players need to go around some cylinders in different rooms 1, 2, and 3 to find the real key.

Wade Xu:My initial idea was just three new rooms and a key, with no obstacles. Since there was a holiday in between, I didn't want to push too hard. Later, during discussions, we felt that repeatedly searching for the key was a bit boring, so we designed it to have only one key, and players would "not find the key" elsewhere. After completion, we had more time than we expected, so we added obstacles.
