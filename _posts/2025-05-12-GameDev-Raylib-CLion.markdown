---
layout: post
title: "Level Up Your C++ Game Dev: raylib, the Free CLion, and Conan!"
description: "Explore how to use raylib for game development with the newly free CLion for non-commercial use and manage dependencies with the Conan C++ package manager plugin."
meta_title: "Level Up Your C++ Game Dev - Conan Blog"
categories: [cpp, gamedev, clion, conan, raylib]
---

Great news for C++ enthusiasts and aspiring game developers! JetBrains [recently
announced](https://blog.jetbrains.com/clion/2025/05/clion-is-now-free-for-non-commercial-use/)
that **CLion**, their C++ IDE, is now **free for non-commercial use**!

This is the perfect opportunity to dive into game development with C++ [using
the Conan Plugin for
CLion](https://blog.conan.io/introducing-new-conan-clion-plugin/). In this post,
we'll explore [raylib](https://www.raylib.com/), a simple and fun C library for
game programming, and show you how to set up a project for a small [runner
game](https://en.wikipedia.org/wiki/Endless_runner) using the **Conan CLion
plugin** to manage dependencies seamlessly.

<div style="text-align: center;">
  <img src="{{ site.baseurl }}/assets/post_images/2025-05-12/jump-to-survive.gif"
       alt="Jump to Survive Mini-Game"/>
</div>

<br>

### Why raylib?

Created by Ramon Santamaria, **raylib** is an excellent choice for starting your
game development journey, offering a straightforward, easy-to-use C library
ideal for beginners and rapid prototyping. It's cross-platform (Windows, Linux,
macOS, Android, HTML5, etc.), and uses hardware-accelerated OpenGL for
rendering. Key features include 2D/3D graphics, audio processing, a powerful
math module, input handling, and [extensive
examples](https://github.com/raysan5/raylib/tree/master/examples).

### Setting Up with the Conan CLion Plugin

Setting up **raylib** in CLion is straightforward using the Conan plugin. You
can find the complete source code for this example in our examples repository.
To clone it, run:

{% highlight bash %}
git clone https://github.com/conan-io/examples2
{% endhighlight %}

- First, install the plugin if you haven't already. Go to *CLion → Settings →
  Plugins* and search for the Conan plugin in the Marketplace.
- Then, go to *File → Open* and navigate to the
  `examples2/examples/libraries/raylib/introduction` folder from the cloned
  repository.
- Click the Conan plugin icon and configure the path to the Conan executable.
- Open the CMake configuration menu and click "Reload CMake Project". During the
  project’s configuration step, Conan will automatically download **raylib** and
  its dependencies.
- At this point, you're ready to build the project.

For more details, please refer to our [previous post about the
plugin](https://blog.conan.io/introducing-new-conan-clion-plugin/).


### Our Project: A Simple Runner Game with raylib

To showcase **raylib** in action, we'll build a classic 2D runner game. The player,
a blue rectangle, must jump over red rectangular obstacles that approach from
the right. The goal is to survive as long as possible, with the score increasing
for each successfully avoided obstacle. To make it a bit more challenging, the
width of the obstacles and the space between them will be randomized.

Before diving into the specifics of the code, it's helpful to understand
raylib's 2D coordinate system. By default, the origin (0,0) is at the **top-left
corner** of the window. The X-axis increases to the right, and the Y-axis
increases downwards. This is a common convention in 2D graphics libraries.

<div style="text-align: center;">
  <img src="{{ site.baseurl }}/assets/post_images/2025-05-12/raylib-coordinate-system.png"
       alt="raylib 2D Coordinate System"/>
</div>
<br>

Now, let's dive into some key aspects of the code:

#### Initializing the Game World

Every **raylib** game starts by setting up the main window. This is done with a
single line that defines its dimensions and title. After that, we set a target
frame rate for consistent game speed:

{% highlight cpp %}
const int screenW = 800;
const int screenH = 450;
InitWindow(screenW, screenH, "Jump to Survive!");

SetTargetFPS(60); // Aim for 60 frames per second
{% endhighlight %}

#### The Player and Physics

Our player is a simple rectangle. We define its initial position (`x`, `y` from the top-left) and size, along
with variables for its physics:

{% highlight cpp %}
Rectangle player = { 100, screenH - 80, 40, 60 }; // {x, y, width, height}
float vy = 0; // Player's current vertical velocity
const float gravity = 1000.0f; // Affects how quickly the player falls
const float jumpImpulse = -450.0f; // Upward force for jump (negative as Y increases downwards)
const int groundY = screenH - 20; // Y-coordinate for the top of the ground
{% endhighlight %}

The core of the player's movement happens within the game loop. We first check
for input to make the player jump. Note that `player.y + player.height >=
groundY` checks if the bottom of the player is at or below the ground level.

{% highlight cpp %}
// Inside the main game loop, if (!gameOver)
if (IsKeyPressed(KEY_SPACE) && player.y + player.height >= groundY) {
    vy = jumpImpulse; // Apply upward force
}
{% endhighlight %}

Then, we apply gravity. `GetFrameTime()` gives us the `deltaTime` (dt), crucial
for frame-rate independent physics:

{% highlight cpp %}
vy += gravity * dt;
player.y += vy * dt; // Positive Y is downwards
{% endhighlight %}
And finally, we ensure the player doesn't fall through the ground:
{% highlight cpp %}
if (player.y + player.height > groundY) {
    player.y = groundY - player.height; // Snap player's bottom to ground level
    vy = 0; // Reset vertical speed
}
{% endhighlight %}

#### Managing Obstacles

Obstacles are also rectangles, managed in a `std::vector`. To add some
unpredictability, we'll randomize their width and the interval at which they
spawn.

First, we define the ranges for these random values:

{% highlight cpp %}
std::vector<Rectangle> obstacles;
float spawnTimer = 0.0f;
float spawnInterval = 1.2f; // Initial spawn interval
const float obstacleSpeed = 300.0f;

const float minSpawnInterval = 0.8f;
const float maxSpawnInterval = 1.6f;

const int minObsWidth = 40;
const int maxObsWidth = 120;
{% endhighlight %}

Using raylib's `GetRandomValue()` we randomly spawn obstacles with also random
sizes:

{% highlight cpp %}
// Inside the game loop, if (!gameOver)
spawnTimer += dt;
if (spawnTimer >= spawnInterval) {
    spawnTimer = 0.0f;
    // Recalculate the next spawn interval randomly
    spawnInterval = GetRandomValue(int(minSpawnInterval*100), int(maxSpawnInterval*100)) / 100.0f;
    // Determine a random width for the new obstacle
    int w = GetRandomValue(minObsWidth, maxObsWidth);
    // Spawn obstacle at the right edge, resting on the ground, with the random width
    obstacles.push_back({ (float)screenW, (float)(groundY - 40), (float)w, 40.0f });
}
{% endhighlight %}

The movement and collision logic for obstacles is handled looping over them and
calculating their position based on their horizontal speed and using
`CheckCollisionRecs()` between the player and obstacles. In case it returns
`true` that would mean that the game ends.

{% highlight cpp %}
// Still inside the game loop, iterating through obstacles
for (int i = 0; i < (int)obstacles.size(); i++) {
    obstacles[i].x -= obstacleSpeed * dt; // Move obstacle left
    if (CheckCollisionRecs(player, obstacles[i])) {
        gameOver = true; // Set game over state
    }
}
{% endhighlight %}

Obstacles that go off-screen to the left are removed, and the score is updated:

{% highlight cpp %}
// After iterating through obstacles
if (!obstacles.empty() && obstacles.front().x + obstacles.front().width < 0) {
    obstacles.erase(obstacles.begin()); // Remove the first obstacle (which is off-screen)
    score++;
}
{% endhighlight %}

#### The Game Loop and Drawing

The entire game logic and drawing are encapsulated in a `while` loop that runs
as long as the window does not close (e.g., user presses ESC or clicks the close
button):

{% highlight cpp %}
while (!WindowShouldClose()) {
    float deltaTime = GetFrameTime(); // Time since last frame

    // ... (game logic and physics updates for player and obstacles) ...

    // Drawing operations must be between BeginDrawing() and EndDrawing()
    BeginDrawing();
    ClearBackground(RAYWHITE); // Clear the screen to white each frame

    DrawRectangle(0, groundY, screenW, 20, DARKGRAY); // Draw ground
    DrawRectangleRec(player, BLUE); // Draw player

    for (auto &obs : obstacles) {
        DrawRectangleRec(obs, RED); // Draw obstacles
    }

    DrawText(TextFormat("Score: %d", score), 10, 10, 20, BLACK); // Display score

    if (gameOver) {
        DrawText("GAME OVER! Press R to restart", 200, screenH/2 - 20, 20, MAROON);
    }

    EndDrawing();
}
{% endhighlight %}

`BeginDrawing()` prepares a fresh canvas for the frame, and `ClearBackground` is
essential to prevent visual artifacts from previous frames. **raylib** offers a
rich set of `Draw...` functions for various shapes and text. `TextFormat()` is a
utility for creating formatted strings. You can check those in the [raylib
cheatsheet](https://www.raylib.com/cheatsheet/cheatsheet.html).

#### Game Over and Restart

A simple `gameOver` boolean flag handles the game state. If `true`, the main
game logic is skipped, and a "GAME OVER" message appears. Pressing 'R' resets
the game. It's important to also reset the `spawnInterval` to its initial
default value, or a sensible average, if you want consistent restarts.

{% highlight cpp %}
// Inside the game loop, in the 'else' branch of 'if (!gameOver)'
if (IsKeyPressed(KEY_R)) {
    // Reset player, obstacles, score, and gameOver flag
    player.y = screenH - 80; // Reset player's Y position
    vy = 0;
    obstacles.clear(); // Remove all current obstacles
    spawnTimer = 0.0f; // Reset spawn timer
    spawnInterval = 1.2f; // Reset spawn interval to initial/average
    score = 0; // Reset score
    gameOver = false; // Set game state back to active
}
{% endhighlight %}

#### Cleanup

Finally, when the game loop exits, `CloseWindow()` is
called to free resources and close the OpenGL context:

{% highlight cpp %}
CloseWindow(); // Unload all loaded data and close window
return 0;
{% endhighlight %}

### Next Steps: Your Turn to Create!

Now that you have the basic runner game up and running, the fun really begins!
This project serves as a great starting point. Consider these ideas to get you
started:

* **New Mechanics**: Transform the game into a "Flappy Bird" style by changing
  obstacle spawning to create gaps and modifying player movement for repeated
  "flaps".
* **Add Depth**: Introduce power-ups (like invincibility or higher jumps),
  diverse obstacle types (circles, polygons, sprites with varied behaviors), or
  even a simple scoring system based on time or obstacles passed.
* **Polish**: Enhance the game with improved visuals like textures, scrolling
  backgrounds, particle effects, and immerse the player with sound effects for
  jumps, scoring, and game over events.

### Conclusion

Whether you're a student taking your first steps into coding, a hobbyist with a
cool game idea, or an open-source developer building tools, now is a fantastic
time to explore what you can create. So, [download
CLion](https://www.jetbrains.com/clion/), grab **raylib** through the [CLion
Conan Plugin](https://blog.conan.io/introducing-new-conan-clion-plugin/), and
start building your dream game today!

Happy coding!
