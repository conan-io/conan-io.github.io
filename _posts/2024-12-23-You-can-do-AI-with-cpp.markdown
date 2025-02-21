---
layout: post
comments: false
title: "Yes, You Can Do AI with C++!"
meta_title: "C++ AI Libraries Available in Conan Center Index"
description: "Learn how to implement AI and Machine Learning in C++ using libraries like TensorFlow Lite, Dlib, and ONNX Runtime, all available in Conan Center Index. Discover why C++ is a powerful choice for AI development."
keywords: "C++, AI, Machine Learning, TensorFlow Lite, Dlib, ONNX Runtime, Conan Center Index"
---

When thinking about Artificial Intelligence and Machine Learning, languages like Python
often come to mind. However, **C++ is a powerful choice for developing AI and ML
applications**, especially when performance and resource efficiency are critical. At
[Conan Center](https://conan.io/center), you can find a variety of libraries that enable
AI and ML development in C++. In this post, we will briefly highlight some of the most
relevant ones available, helping you get started with AI development in C++ easily.

### Why Use C++ for AI and Machine Learning?

C++ offers several advantages for AI and ML development:

- **Performance**: C++ provides high execution speed and efficient resource management,
  making it ideal for computationally intensive tasks.
- **Low-Level Optimizations**: C++ enables developers to utilize multiple compilation
  options and optimize libraries directly from the source code. This provides precise
  control over memory usage, inference processes, and hardware features like SIMD and
  CUDA, allowing custom optimizations for specific hardware capabilities.

In summary, C++ can be an excellent choice for working with AI. Let's explore some of the
most representative AI libraries available in Conan Center Index.

### An Overview of Some AI and ML Libraries Available in Conan Center

Below are some notable libraries available in Conan Center Index. These libraries range
from running large language models locally to optimizing model inference on edge devices
or using specialized toolkits for tasks like computer vision and numerical optimization.

#### [LLaMA.cpp](https://conan.io/center/recipes/llama-cpp)

**LLaMA.cpp** is a C/C++ implementation of [Meta’s LLaMA models](https://www.llama.com/)
and others, enabling local inference with minimal dependencies and high performance. It
works on CPUs and GPUs, supports diverse architectures, and accommodates a variety of text
models like [LLaMA 3](https://huggingface.co/models?search=llama),
[Mistral](https://mistral.ai/), or [Phi](https://azure.microsoft.com/en-us/products/phi),
as well as multimodal models like [LLaVA](https://github.com/haotian-liu/LLaVA).

One of the most interesting aspects of this library is that it includes a collection of
CLI tools as examples, making it easy to run your own LLMs straight out of the box. 

Let's try one of those tools. First, install the library with Conan and ensure that you
enable building the examples and activate the network options (which require `libcurl`).
Then, use a [Conan deployer](https://docs.conan.io/2/reference/extensions/deployers.html)
to move the installed files from the Conan cache to the user space. To accomplish this,
simply run the following command:

```shell
# Install llama-cpp using Conan and deploy to the local folder
$ conan install --requires=llama-cpp/b4079 --build=missing \
                -o="llama-cpp/*:with_examples=True" \
                -o="llama-cpp/*:with_curl=True" \
                --deployer=direct_deploy
```

You can run your chatbot locally by invoking the packaged `llama-cli` application with a
model from a Hugging Face repository. In this example, we will use a Llama 3.2 model with
1 billion parameters and 6-bit quantization from the [unsloth
repository](https://huggingface.co/unsloth). 

Now, simply run the following command to start asking questions:

```shell
# Run llama-cli downloading a Hugging Face model
$ ./direct_deploy/llama-cpp/bin/llama-cli \
   --hf-repo unsloth/Llama-3.2-1B-Instruct-GGUF \
   --hf-file Llama-3.2-1B-Instruct-Q6_K.gguf \
   -p "What is the meaning to life and the universe?\n"
```

Let’s check out our LLM’s perspective:

```text
What is the meaning to life and the universe?

The meaning to life and the universe is a subject of endless 
debate among philosophers, theologians, scientists, and everyday 
people. But what if I told you that there is a simple 
yet profound truth that can help you find meaning and purpose 
in life? It's not a complex theory or a scientific formula. 
It's something that can be discovered by simply observing the 
world around us.

Here's the truth: **every moment is a 
new opportunity to create meaning and purpose.**
...
```

As you can see, in just a few minutes, we can have our own LLM running locally, all using
C++. You can also use the libraries provided by the **llama-cpp** Conan package to
integrate LLMs into your own applications. For example, here is the code for the
[llama-cli](https://github.com/ggerganov/llama.cpp/blob/b4079/examples/main/main.cpp) that
we just executed. For more information on the LLaMA.cpp project, please [check their
repository on GitHub](https://github.com/ggerganov/llama.cpp).

#### [TensorFlow Lite](https://conan.io/center/recipes/tensorflow-lite)

**TensorFlow Lite** is a specialized version of [TensorFlow](https://www.tensorflow.org/)
designed for deploying machine learning models on mobile, embedded systems, and other
resource-constrained devices. It’s ideal for applications that require low-latency
inference, such as edge computing or IoT devices. TensorFlow Lite focuses on optimizing
performance while minimizing power consumption.

<figure class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2023-05-11/pose-detection-tensorflow.gif" 
         style="display: block; margin-left: auto; margin-right: auto;" 
         alt="Pose estimation with TensorFlow Lite"/>
    <figcaption style="text-align: center; font-size: 0.9em;">
        TensorFlow Lite in action
    </figcaption>
</figure>

If you'd like to learn how to use TensorFlow Lite with a neural network model in C++, we
previously published a [blog
post](https://blog.conan.io/2023/05/11/tensorflow-lite-cpp-mobile-ml-guide.html)
showcasing how to build a real-time human pose detection application using TensorFlow Lite
and OpenCV. Check it out if you haven't read it yet.

One of the interesting aspects of using the library is the availability of numerous models
on platforms like [Kaggle Models](https://www.kaggle.com/models) for various tasks, which
can be easily integrated into your code. For more information on Tensorflow Lite, please
[check their documentation](https://www.tensorflow.org/lite/guide).

#### [ONNX Runtime](https://conan.io/center/recipes/onnxruntime)

**ONNX Runtime** is a high-performance inference engine designed to run models in the
[ONNX](https://onnx.ai/) format, an open standard for representing network models across
various AI frameworks such as PyTorch, TensorFlow, and scikit-learn.

Thanks to this interoperability, ONNX Runtime allows you to use models trained in
different frameworks with a single unified runtime. Here’s the general workflow:

1. **Get a model**: Train a model using your preferred framework and export or convert it
   to the ONNX format. There are [tutorials](https://onnxruntime.ai/docs/tutorials/)
   available for popular frameworks and libraries.

2. **Load and run the model with ONNX Runtime**: Check out these [C++ inference
   examples](https://github.com/microsoft/onnxruntime-inference-examples/tree/main/c_cxx)
   to get started quickly.

Additionally, ONNX Runtime offers multiple options for tuning performance using various
runtime configurations or hardware accelerators. Explore [the Performance section in the
documentation](https://onnxruntime.ai/docs/performance/) for more details. For more
information, visit the [ONNX Runtime documentation](https://onnxruntime.ai/docs/).

Check all available versions in the Conan Center Index by running:

```shell
conan search onnxruntime
```

#### [OpenVINO](https://conan.io/center/recipes/openvino)

**OpenVINO** (Open Visual Inference and Neural Network Optimization) is an
[Intel-developed toolkit](https://docs.openvino.ai/) that accelerates deep learning
inference on a wide range of devices. It supports models from frameworks like PyTorch,
TensorFlow, and ONNX, offering tools to optimize, deploy, and scale AI applications
efficiently.

The [OpenVINO C++
examples](https://docs.openvino.ai/2024/learn-openvino/openvino-samples.html) demonstrate
tasks such as model loading, inference, and performance benchmarking. Explore these
examples to see how you can integrate OpenVINO into your projects.

For more details, visit the [OpenVINO documentation](https://docs.openvino.ai/2024/).

Check all available versions in the Conan Center Index by running:

```shell
conan search openvino
```

#### [mlpack](https://conan.io/center/recipes/mlpack)

**mlpack** is a fast, flexible, and lightweight header-only C++ library for machine
learning. It is ideal for lightweight deployments and prototyping. It offers a broad range
of machine learning algorithms for classification, regression, clustering, and more, along
with preprocessing utilities and data transformations.

Explore [mlpack’s examples
repository](https://github.com/mlpack/examples/tree/master/cpp), where you’ll find C++
applications such as training neural networks for digit recognition, decision tree models
for predicting loan defaults, and clustering algorithms for identifying patterns in
healthcare data.

For further details, visit the [mlpack documentation](https://www.mlpack.org/).

Check all available versions in the Conan Center Index by running:

```shell
conan search mlpack
```

#### [Dlib](https://conan.io/center/recipes/dlib)

**Dlib** is a modern C++ library widely used in research and industry for advanced machine
learning algorithms and computer vision tasks. Its comprehensive documentation and
well-designed API make it straightforward to integrate into existing projects.

Dlib provides a variety of algorithms, including facial detection, landmark recognition,
object classification, and tracking. Examples of these functionalities can be found in
[their GitHub repository](https://github.com/davisking/dlib/tree/master/examples). 

For more information, visit the [Dlib official site](http://dlib.net/).

Check all available versions in the Conan Center Index by running:

```shell
conan search dlib
```

## Conclusion

C++ offers high-performance AI libraries and the flexibility to optimize for your
hardware. With Conan, integrating these tools is straightforward, enabling efficient,
scalable AI workflows.

Now, give these tools a go and see your AI ideas come to life in C++!
