---
layout: post
comments: false
title: "Real-Time Pose Detection with TensorFlow Lite and Conan in C++"
meta_title: "Real-Time Object Detection with TensorFlow Lite and Conan in C++ - Conan Blog" 
meta_description: "Discover how to leverage TensorFlow Lite and Conan package manager for seamless integration in C++ to create cutting-edge real-time pose detection applications."
---

In this post, we will explore how to use Tensorflow Lite in C++ for real-time human pose
estimation through a neural network from Tensorflow Hub trained for this purpose. We will
develop an example that uses OpenCV to load a video that we will process frame by frame to
obtain the joint locations in each image. The output of our application will look
something like this:

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-04-24/pose-detection-tensorflow.gif" style="display: block; margin-left: auto; margin-right: auto;" alt="Pose estimation"/>
</p>


### A short introduction

TensorFlow Lite is a library specially designed for deploying deep learning models on
mobile, microcontrollers and other edge devices. The main difference between TensorFlow
and TensorFlow Lite is that TensorFlow is used for creating and training machine learning
models, while TensorFlow Lite is a simpler version designed for running those models on
devices like mobile phones.

Tensorflow Hub is a repository where we can find lots of trained machine learning models,
ready to be used in our applications. For the case of our example we will use the
[MoveNet.SinglePose.Lightning](https://tfhub.dev/google/lite-model/movenet/singlepose/lightning/tflite/float16/4)
model but there are other many models compatible with Tensorflow Lite in the Tensorflow Hub. Some examples include:

- [Image style
  transfer](https://tfhub.dev/google/magenta/arbitrary-image-stylization-v1-256/2)
- [Image depth estimation from monocular
  images](https://tfhub.dev/intel/midas/v2_1_small/1)
- Different types of applications of image classification like for
  [crop-dissease](https://tfhub.dev/agripredict/disease-classification/1), [insect
  identification](https://tfhub.dev/google/aiy/vision/classifier/insects_V1/1) or [food
  classification](https://tfhub.dev/google/aiy/vision/classifier/food_V1/1).
- [Image superresolution](https://tfhub.dev/captain-pool/esrgan-tf2/1)

### Using Tensorflow Lite in your application

All the source code for this example is available in the [Conan 2.0 examples
repo](https://github.com/conan-io/examples2), you can check out the sources:

{% highlight bash %}
git clone https://github.com/conan-io/examples2.git
cd cd examples2/examples/libraries/tensorflow-lite/pose-estimation/
{% endhighlight %}

There, you will find the project, let's have a look to the relevant files:

{% highlight txt %}
.
├── CMakeLists.txt
├── assets
│   ├── dancing.mov
│   └── lite-model_movenet_singlepose_lightning_tflite_float16_4.tflite
├── conanfile.py
└── src
    └── main.cpp
{% endhighlight %}

You can see the source code and *CMakeLists.txt* for our application, the video we are going
to process, and the model for the neural network we will load into TensorFlow Lite. Our
application runs the inference on the model (make predictions based on input data) to
detect human keypoints, providing us with the positions of various body joints. The
application follows this diagram:

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-04-24/blocks.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Application structure"/>
</p>

#### Loading the neural network model

As we previously mentioned we will use the
[MoveNet.SinglePose.Lightning](https://tfhub.dev/google/lite-model/movenet/singlepose/lightning/tflite/float16/4)
model in our example. This model in is in the form of a `.tflite` file. The first step is
loading the `.tflite` model into memory. This file contains the model's execution graph.
This model is stored in the `FlatBufferModel` class and you can create an instance of it
using the `BuildFromFile` method with the model file name as input argument.

{% highlight cpp %}

auto model = tflite::FlatBufferModel::BuildFromFile(model_file.c_str());

if (!model) {
    throw std::runtime_error("Failed to load TFLite model");
}

{% endhighlight %}

Then, we build an `Interpreter` that is the class that will take the model and define
execute the operations it defines on input data, also providing access to the output. To
do so, we use the `InterpreterBuilder`, that will allocate memory for the `Interpreter`
and manage the set up so that the `Interpreter` can read the provided model. Note that
before running the inference we tell the interpreter to allocate memory for the model's
tensors calling the`AllocateTensors()` method.
In the last line of this block we also call `PrintInterpreterState` that is a debugging
utility useful to inspect the state of the interpreter nodes and tensors.

{% highlight cpp %}

tflite::ops::builtin::BuiltinOpResolver op_resolver;

std::unique_ptr<tflite::Interpreter> interpreter;

tflite::InterpreterBuilder(*model, op_resolver)(&interpreter);

if (interpreter->AllocateTensors() != kTfLiteOk) {
    throw std::runtime_error("Failed to allocate tensors");
}

tflite::PrintInterpreterState(interpreter.get());

{% endhighlight %}

#### Read and transform the input data

Now we have our interpreter ready to feed it with some data and run the inference, but
first we have to adapt our data to the input accepted by the model. In this case, if we
check the
[documentation](https://tfhub.dev/google/lite-model/movenet/singlepose/lightning/tflite/float16/4)
for this specific model we can see that the input must be in the form of "an uint8 tensor
of shape: 192x192x3. Channels order: RGB with values in [0, 255]". 

Although not necessary, we could access the input tensor from the interpreter to confirm
the tensor input size that in this case is `[1,192,192,3]`. The first element is the batch
size, that is 1 as we are only using one image as the input of the model.

{% highlight cpp %}
auto input = interpreter->inputs()[0];

auto input_batch_size = interpreter->tensor(input)->dims->data[0];
auto input_height = interpreter->tensor(input)->dims->data[1];
auto input_width = interpreter->tensor(input)->dims->data[2];
auto input_channels = interpreter->tensor(input)->dims->data[3];

std::cout << "The input tensor has the following dimensions: ["
          << input_batch_size << "," 
          << input_height << "," 
          << input_width << ","
          << input_channels << "]" << std::endl;
{% endhighlight %}

We want to perform the pose detection in a video which has dimensions of 640x360 pixels,
so we have to crop and resize the video frames to 192x192 pixels before inputing them to
the model (we have omitted the frame capture code for simplicity but you can find the code
in the repository). To do so, we use the
[resize()](https://docs.opencv.org/4.5.5/da/d54/group__imgproc__transform.html#ga47a974309e9102f5f08231edc7e7529d)
function from the OpenCV library.

{% highlight cpp %}

// unprocessed frames from our video
int image_width = frame.size().width; // 640 in our example
int image_height = frame.size().height; // 360 in our example

int square_dim = std::min(image_width, image_height); // the min dimension is 360 in our case
int delta_height = (image_height - square_dim) / 2;   // so this is 0 
int delta_width = (image_width - square_dim) / 2;     // and this 140

cv::Mat resized_image; // this is the input for the model

// crop to 360x360 and then resize to 192x192
cv::resize(frame(cv::Rect(delta_width, 
                          delta_height, 
                          square_dim, 
                          square_dim)), 
           resized_image, 
           cv::Size(input_width, input_height));

{% endhighlight %}

The final step is to copy the data from the resized video frame to the input of the
interpreter. We can get a pointer to the input tensor getting `typed_input_tensor` from
the interpreter.

{% highlight cpp %}
memcpy(interpreter->typed_input_tensor<unsigned char>(0), 
       resized_image.data, 
       resized_image.total() * resized_image.elemSize());
{% endhighlight %}

This diagram summarizes the whole size conversion pipeline for the video frames.

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-04-24/input-output-tensor-size.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Tensor sizes"/>
</p>

#### Running inference

After preparing and copying the input data to the input tensor we can finally run the
inference which can be done by calling to the `Invoke()` method of the interpreter. If the
inference runs succesfully we can recover the output tensor from the model getting
`typed_output_tensor` from the interpreter. 

{% highlight cpp %}

if (interpreter->Invoke() != kTfLiteOk) {
    std::cerr << "Inference failed" << std::endl;
    return -1;
}

float *results = interpreter->typed_output_tensor<float>(0);

{% endhighlight %}


#### Interpreting output

Each model outputs the tensor data from the inference in a certain format that we have to
interpret. In this case the
[documentation](https://tfhub.dev/google/lite-model/movenet/singlepose/lightning/tflite/float16/4)
for the model states that the output is a float32 tensor of shape [1, 1, 17, 3], storing
this information:

- The first two channels of the last dimension represents the yx coordinates (normalized
  to image frame, i.e. range in [0.0, 1.0]) of the 17 keypoints (in the order of: [nose,
  left eye, right eye, left ear, right ear, left shoulder, right shoulder, left elbow,
  right elbow, left wrist, right wrist, left hip, right hip, left knee, right knee, left
  ankle, right ankle]).

<p class="centered">
    <img  src="{{ site.baseurl }}/assets/post_images/2023-04-24/output-tensor.png" style="display: block; margin-left: auto; margin-right: auto;" alt="Output tensor keypoints"/>
</p>

- The third channel of the last dimension represents the prediction confidence scores of
  each keypoint, also in the range [0.0, 1.0].

We created a `draw_keypoints()` helper function that takes the output tensor and orders
the different output coordinates to draw the pose skeleton over the video frame. We also
have take the confidence of the output into account filtering those results that have a
confidence under the 0.2 threshold.

{% highlight cpp %}

const int num_keypoints = 17;
const float confidence_threshold = 0.2;

const std::vector<std::pair<int, int>> connections = {
    {0, 1}, {0, 2}, {1, 3}, {2, 4}, {5, 6}, {5, 7}, 
    {7, 9}, {6, 8}, {8, 10}, {5, 11}, {6, 12}, {11, 12}, 
    {11, 13}, {13, 15}, {12, 14}, {14, 16}
};

void draw_keypoints(cv::Mat &resized_image, float *output)
{
    int square_dim = resized_image.rows;

    for (int i = 0; i < num_keypoints; ++i) {
        float y = output[i * 3];
        float x = output[i * 3 + 1];
        float conf = output[i * 3 + 2];

        if (conf > confidence_threshold) {
            int img_x = static_cast<int>(x * square_dim);
            int img_y = static_cast<int>(y * square_dim);
            cv::circle(resized_image, cv::Point(img_x, img_y), 2, cv::Scalar(255, 200, 200), 1);
        }
    }

    // draw skeleton
    for (const auto &connection : connections) {
        int index1 = connection.first;
        int index2 = connection.second;
        float y1 = output[index1 * 3];
        float x1 = output[index1 * 3 + 1];
        float conf1 = output[index1 * 3 + 2];
        float y2 = output[index2 * 3];
        float x2 = output[index2 * 3 + 1];
        float conf2 = output[index2 * 3 + 2];

        if (conf1 > confidence_threshold && conf2 > confidence_threshold) {
            int img_x1 = static_cast<int>(x1 * square_dim);
            int img_y1 = static_cast<int>(y1 * square_dim);
            int img_x2 = static_cast<int>(x2 * square_dim);
            int img_y2 = static_cast<int>(y2 * square_dim);
            cv::line(resized_image, cv::Point(img_x1, img_y1), cv::Point(img_x2, img_y2), cv::Scalar(200, 200, 200), 1);
        }
    }
}
{% endhighlight %}

### Using Conan to manage Tensorflow Lite and OpenCV dependencies

Consuming the Tensorflow Lite and OpenCV libraries using Conan is quite straightforward.
If you have a look at the CMakeLists.txt of the project if has nothing particular about
Conan.

{% highlight cmake %}
cmake_minimum_required(VERSION 3.15)
project(pose-estimation CXX)

find_package(tensorflowlite REQUIRED)
find_package(OpenCV REQUIRED)

add_executable(pose-estimation src/main.cpp)

target_link_libraries(pose-estimation PRIVATE 
                      tensorflow::tensorflowlite 
                      opencv::opencv)
{% endhighlight %}

On the Conan side we just need to create a conanfile.py declaring the dependencies for the
project.

{% highlight python %}
from conan import ConanFile
from conan.tools.cmake import cmake_layout


class PoseEstimationRecipe(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeDeps", "CMakeToolchain"

    def requirements(self):
        self.requires("tensorflow-lite/2.10.0")
        self.requires("opencv/4.5.5")
        self.requires("libwebp/1.3.0", override=True)
        self.requires("eigen/3.4.0", override=True)

    def layout(self):
        cmake_layout(self)
{% endhighlight %}

As you can see we just declare the dependencies in the `requirements()` method of the
ConanFile. We also are declaring the layout() for the project as cmake_layout as we are
using CMake for building. You can check the [consuming packages tutorial
section](https://docs.conan.io/2/tutorial/consuming_packages) of the Conan documentation
for more information.

Now let’s build the project and run the application.

{% highlight bash %}
conan install . -o opencv/*:with_ffmpeg=False -o opencv/*:with_gtk=False -c tools.system.package_manager:mode=install -c tools.system.package_manager:sudo=True
cmake --preset conan-release
cmake --build --preset conan-release
build/Release/pose-estimation
{% endhighlight %}

### Conclusions

- Lo fácil que es usar tensorflow-lite con Conan, lo complicado que sería manejar todas esas dependencias manualmente
- Ahora tienes las bases, prueba a hacer tus propias aplicaciones!
