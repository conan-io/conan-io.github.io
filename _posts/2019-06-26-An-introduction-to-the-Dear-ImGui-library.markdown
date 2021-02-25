---
layout: post
comments: false
title: "An introduction to the Dear ImGui library"
meta_title: "An introduction to the Dear ImGui library - Blog - Conan.io"
meta_description: "In introduction, and screencast showing how to use ImGui, the
 Immediate Mode Graphics library with Conan, the package manager for C++."
last_modified_at: "2021-02-24"
---

As developers, many of us have faced the pain of introducing graphical
interfaces to our programs. Traditional GUI libraries add a degree of complexity
which you may not want if you are making tools that are intended for a variety
of tasks such as debugging. Here we present a library that makes it possible to
create [loggers](https://github.com/ocornut/imgui/issues/2529),
[profilers](https://github.com/ocornut/imgui/issues/2265),
[debuggers](https://github.com/ocornut/imgui/issues/2265) or even an [entire
game making editor](https://github.com/ocornut/imgui/issues/1607) quickly and
easily. The entire
[example](https://github.com/conan-io/examples/tree/master/libraries/dear-imgui/basic)
presented here is available on Github.

### Update 2021-02-23 : Screencast Available

Based on the feedback from this blog post, we've recorded a screencast where we
perform all the steps and show the results live. We plan to do more of these
screencasts in the future, so pleased stay tuned to this blog for future
updates.

{% include youtube-embed.html id="O2E-W9P-jKc" %}

Also, for more video content about using Conan, we've published a large
collection of video-based content organized into [self-paced training courses in
the JFrog
Academy](https://blog.conan.io/2020/09/24/New-conan-training-series.html).

### Dear ImGui?

[Dear ImGui](https://github.com/ocornut/imgui) is an amazing C++ GUI library
mainly used in game developement. The project is open-source software, licensed
under MIT license. Dear ImGui focuses on simplicity and productivity using what
is called [Immediate Mode GUI paradigm](https://caseymuratori.com/blog_0001).

Immediate mode GUI's are different from the traditional retained-mode interfaces
in that widgets are created and drawn on each frame vs the traditional approach
of first creating a widget and adding callbacks to it. Some of the benefits of
this paradigm are your UI "lives closer" to your data and that it allows for
fast prototyping.

Dear ImGui is mainly designed for developers to use in content creation and
debug tools. It's renderer agnostic in the way that you have to provide the
tools to render the data but It's very easy to integrate into your own code as
it has multiple bindings for different window and events handling libraries
(like [GLFW](https://www.glfw.org/), [SDL2](https://www.libsdl.org/index.php)
and GLUT) and multiple renderers (like OpenGL, DirectX and
[Vulkan](https://www.khronos.org/vulkan/)).

Dear ImGui comes with lots of widgets like windows, labels, input boxes,
progress bars, buttons, sliders, trees, etc. You can see some examples in the
image beneath.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2019-06-26/conan-imgui-widgets.gif"  align="center"  alt="Different Dear ImGui widgets"/>
</p>

### Integrating Dear ImGui in your application

The typical use of ImGui is when you already have a 3D-pipeline enabled
application like a content creation or game development tool where you want to
add a GUI. Let's see how easy it is to integrate ImGui in our application. Our
example application renders a triangle using OpenGL3. We will use GLFW to manage
window creation and events handling. As ImGui is independent of the rendering
system and platform we have to introduce some binding for our rendering system.
Fortunately, there are many premade bindings in Dear ImGui's repo. As we will
use Dear ImGui v1.74 these are the ones we will need:

* [imgui_impl_opengl3.cpp](https://github.com/ocornut/imgui/blob/v1.74/examples/imgui_impl_opengl3.cpp)
* [imgui_impl_opengl3.h](https://github.com/ocornut/imgui/blob/v1.74/examples/imgui_impl_opengl3.h)
* [imgui_impl_glfw.cpp](https://github.com/ocornut/imgui/blob/v1.74/examples/imgui_impl_glfw.cpp)
* [imgui_impl_glfw.h](https://github.com/ocornut/imgui/blob/v1.74/examples/imgui_impl_glfw.h)

The minimal code to make this work is in ``main.cpp``. First, you initialize the
window for rendering and then you have to initialize a Dear ImGui context and
the helper platform and Renderer bindings. You can change the rendering style if
you want as well.

    {% highlight cpp %}
    // Setup Dear ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO &io = ImGui::GetIO();
    // Setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init(glsl_version);
    // Setup Dear ImGui style
    ImGui::StyleColorsDark();
    {% endhighlight %}

Then you enter the main application loop where you can clearly see the
difference with the classical retained mode GUI's.

    {% highlight cpp %}
    while (!glfwWindowShouldClose(window))
    {
        glfwPollEvents();
        glClearColor(0.45f, 0.55f, 0.60f, 1.00f);
        glClear(GL_COLOR_BUFFER_BIT);

        // feed inputs to dear imgui, start new frame
        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        // rendering our geometries
        triangle_shader.use();
        glBindVertexArray(vao);
        glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, 0);
        glBindVertexArray(0);

        // render your GUI
        ImGui::Begin("Demo window");
        ImGui::Button("Hello!");
        ImGui::End();

        // Render dear imgui into screen
        ImGui::Render();
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        int display_w, display_h;
        glfwGetFramebufferSize(window, &display_w, &display_h);
        glViewport(0, 0, display_w, display_h);
        glfwSwapBuffers(window);
    }
    {% endhighlight %}

And, we must do some cleanup when the loop ends.

    {% highlight cpp %}
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
    {% endhighlight %}

So, this is what we get:

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2019-06-26/conan-imgui-hello-world.gif" align="center" alt="ImGui Hello World"/>
</p>

Let's say, for example, that we want to change the triangle's
position/orientation and colour. That would be as simple as calling some sliders
and a colour picker and passing the data to the triangle via shader uniforms:

    {% highlight cpp %}
    // render your GUI
    ImGui::Begin("Triangle Position/Color");
    static float rotation = 0.0;
    ImGui::SliderFloat("rotation", &rotation, 0, 2 * PI);
    static float translation[] = {0.0, 0.0};
    ImGui::SliderFloat2("position", translation, -1.0, 1.0);
    static float color[4] = { 1.0f,1.0f,1.0f,1.0f };
    // pass the parameters to the shader
    triangle_shader.setUniform("rotation", rotation);
    triangle_shader.setUniform("translation", translation[0], translation[1]);
    // color picker
    ImGui::ColorEdit3("color", color);
    // multiply triangle's color with this color
    triangle_shader.setUniform("color", color[0], color[1], color[2]);
    {% endhighlight %}

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2019-06-26/conan-imgui-triangle-rotate-color.gif" align="center" alt="Change triangle's color"/>
</p>

There are some basic drawing tools as well.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2019-06-26/conan-imgui-logo.png" align="center" alt="Render Conan logo"/>
</p>

If you want to explore the different library widgets and options the best way to
do it is to make a call to ``ImGui::ShowDemoWindow()`` and have a look at the
different examples.

### Setting up a project with Conan

Setting up a project that uses ImGui is a matter of minutes with Conan. [A Conan
package for ImGui](https://conan.io/center/imgui) has been created and added to
Conan-Center already. The example shown here is using Windows and Visual Studio
2017 but it is very similar in [MacOS or
Linux](https://github.com/conan-io/examples/blob/master/libraries/dear-imgui/basic/README.md).

If you want to give a try tou can download all the files from the Conan examples
repo:

    {% highlight bash %}
    git clone https://github.com/conan-io/examples.git
    cd examples/libraries/dear-imgui/basic
    {% endhighlight %}

First, let's inspect the CMake project. It has the bindings for GLFW and OpenGL3
and two more files to handle OpenGL shaders and file reading. It will also copy
the shaders that render the triangle to the working directory each time the
application is recompiled.

    {% highlight cmake %}
    cmake_minimum_required(VERSION 3.0)
    project(dear-imgui-conan CXX)

    set(CMAKE_PREFIX_PATH ${CMAKE_BINARY_DIR})
    set(CMAKE_MODULE_PATH ${CMAKE_BINARY_DIR})

    # CONFIG option is important so
    # CMake doesn't search for modules in default directory
    find_package(imgui CONFIG)
    find_package(glfw CONFIG)
    find_package(glew CONFIG)

    add_executable( dear-imgui-conan
                    main.cpp
                    opengl_shader.cpp
                    file_manager.cpp
                    opengl_shader.h
                    file_manager.h
                    bindings/imgui_impl_glfw.cpp
                    bindings/imgui_impl_opengl3.cpp
                    bindings/imgui_impl_glfw.h
                    bindings/imgui_impl_opengl3.h
                    assets/simple-shader.vs
                    assets/simple-shader.fs
    )

    add_custom_command(TARGET
                    dear-imgui-conan
                    POST_BUILD
                    COMMAND
                        ${CMAKE_COMMAND} -E copy
                            ${PROJECT_SOURCE_DIR}/assets/simple-shader.vs
                            ${PROJECT_BINARY_DIR}
                    COMMAND
                        ${CMAKE_COMMAND} -E copy
                            ${PROJECT_SOURCE_DIR}/assets/simple-shader.fs
                            ${PROJECT_BINARY_DIR}
    )

    target_compile_definitions(dear-imgui-conan
        PUBLIC IMGUI_IMPL_OPENGL_LOADER_GLEW
    )

    target_link_libraries(dear-imgui-conan
                    imgui::imgui
                    glfw::glfw
                    glew::glew
    )
    {% endhighlight %}

We will also need the *conanfile* to declare the libraries it depends on.
Besides from the GLFW library we already talked about we need the GLEW library
to handle OpenGL functions loading. We will use ``cmake_multi`` to generate
projects for Debug and Release configurations. An imports section was also added
to download the required bindings for GLFW and OpenGL3.

    {% highlight text %}
    [requires]
    imgui/1.74
    glfw/3.3.2
    glew/2.1.0
    [generators]
    cmake_find_package_multi

    [imports]
    ./misc/bindings, imgui_impl_glfw.cpp -> ../bindings
    ./misc/bindings, imgui_impl_opengl3.cpp -> ../bindings
    ./misc/bindings, imgui_impl_glfw.h -> ../bindings
    ./misc/bindings, imgui_impl_opengl3.h -> ../bindings
    {% endhighlight %}

Now let's build the project and run the application.

    {% highlight bash %}
    cd dear-imgui-conan-example
    mkdir build
    cd build
    conan install .. -s build_type=Release
    conan install .. -s build_type=Debug
    cmake .. -G "Visual Studio 15 2017 Win64"
    cmake --build . --config Release cd Release
    dear-imgui-conan
    {% endhighlight %}

### Conclusions

Dear ImGui is a powerful library with an easy to use API which integrates into
3D-pipeline enabled applications almost seamlessly. It has lots of widgets and
can be a great tool to make debugging software such as profilers, loggers or
object editors of any kind. Also, new functionalities like
[docking](https://github.com/ocornut/imgui/issues/2109) or [multiple
viewports](https://github.com/ocornut/imgui/issues/1542) are currently being
developed. Now it's time to experiment with the library and making it interact
with your own code!
