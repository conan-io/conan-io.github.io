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

C++ offers some advantages for AI and ML development:

- **Performance**: C++ provides high execution speed and efficient resource management,
  making it ideal for computationally intensive tasks.
- **Fine-Grained Control through Compilation**: C++ allows developers to utilize multiple
  compilation options and optimize libraries directly from the source code to tailor
  performance for specific hardware, offering a level of fine-grained control.

In summary, C++ can be an excellent choice for working with AI. Let's explore some of the
most representative libraries on this topic available in the Conan Center Index.

### An Overview of Some AI and ML Libraries Available in Conan Center

Below are some notable libraries you can easily integrate with your C++ projects through
Conan Center. These libraries range from running large language models locally to
optimizing model inference on edge devices or using specialized toolkits for tasks like
computer vision and numerical optimization.

#### LLaMA.cpp

**LLaMA.cpp** is a C/C++ implementation of [Meta’s LLaMA models](https://www.llama.com/)
and others, enabling local inference with minimal dependencies and high performance. It
works on CPUs and GPUs, supports diverse architectures, and accommodates a variety of text
models like LLaMA 3, Mistral, or Phi, as well as multimodal models like LLaVA 1.6.

One of the most interesting aspects of this library is that it includes a collection of
CLI tools as examples, making it easy to run your own LLMs straight out of the box. To
install the library with Conan, ensure that you enable building the examples and activate
the network options (which require `libcurl`). Then, use a [Conan
deployer](https://docs.conan.io/2/reference/extensions/deployers.html) to move the
installed files from the Conan cache to the user space. To accomplish this, simply run the
following command:

```shell
# Install llama-cpp using Conan and deploy to the local folder
$ conan install --requires=llama-cpp/b4079 --build=missing \
                -o="llama-cpp/*:with_examples=True" \
                -o="llama-cpp/*:with_curl=True" \
                --deployer=full_deploy
```

You can run your chatbot locally by simply by invoking the packaged `llama-cli`
application with a model from a Hugging Face repository (in this case we will be using a
Llama 3.2 model with 1 billion parameters and 6 bit quantization from the [unsloth
repo](https://huggingface.co/unsloth))  and starting to ask questions:

```shell
# Run llama-cli downloading a Hugging Face model
$ ./direct_deploy/llama-cpp/bin/llama-cli \
   --hf-repo unsloth/Llama-3.2-1B-Instruct-GGUF \
   --hf-file Llama-3.2-1B-Instruct-Q6_K.gguf \
   -p "What is the meaning to life and the universe?\n"
```

Now, let’s check out our LLM’s perspective:

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

#### TensorFlow Lite

**TensorFlow Lite** is a specialized version of [TensorFlow](https://www.tensorflow.org/)
designed for deploying machine learning models on mobile, embedded systems, and other
resource-constrained devices. It’s ideal for applications that require low-latency
inference, such as edge computing or IoT devices. TensorFlow Lite focuses on optimizing
performance while minimizing power consumption.

<figure class="centered">
    <img src="{{ site.baseurl }}/assets/post_images/2023-05-11/pose-detection-tensorflow.gif" 
         style="display: block; margin-left: auto; margin-right: auto;" 
         alt="Pose estimation with TensorFlow Lite"/>
</figure>

If you'd like to see TensorFlow Lite in action, we previously published a [blog
post](https://blog.conan.io/2023/05/11/tensorflow-lite-cpp-mobile-ml-guide.html)
showcasing how to build a real-time human pose detection application using TensorFlow Lite
and OpenCV. If you haven't read it yet, we recommend checking it out for a detailed
walkthrough of an exciting use case.

One of the interesting aspects of using the library is the availability of numerous models
on platforms like [Kaggle Models](https://www.kaggle.com/models) for various tasks, which
can be easily integrated into your code. For more information on Tensorflow Lite, please
[check their documentation](https://www.tensorflow.org/lite/guide).

#### ONNX Runtime

**ONNX Runtime** is a high-performance inference engine designed to run models in the
[ONNX](https://onnx.ai/) format, an open standard that facilitates representing and
transferring neural network models across various AI frameworks such as PyTorch,
TensorFlow, or scikit-learn.

Thanks to this interoperability, you can run models trained in multiple frameworks using a
single unified runtime. The general idea is:

1. **Get a model**: Train it using your preferred framework and export or convert it to
   the ONNX format. There are [tutorials](https://onnxruntime.ai/docs/tutorials/) showing
   how to do this for popular frameworks and libraries.

2. **Load and run the model with ONNX Runtime**: Check out these [C++ inference
   examples](https://github.com/microsoft/onnxruntime-inference-examples/tree/main/c_cxx)
   to quickly get started with some code samples. 
   
From there, ONNX Runtime offers options to tune performance using various runtime
configurations or hardware accelerators. There are many possibilities—check [the
Performance section in the documentation](https://onnxruntime.ai/docs/performance/) for a
more in-depth look.

ONNX Runtime’s flexibility allows you to experiment with models from diverse sources,
integrate them into your C++ applications, and scale as needed. For more details, check
out the [ONNX Runtime documentation](https://onnxruntime.ai/docs/).

#### OpenVINO

**OpenVINO** (Open Visual Inference and Neural Network Optimization) is an
[Intel-developed toolkit](https://docs.openvino.ai/) that accelerates deep learning
inference across a range of devices. It supports models from popular frameworks like
PyTorch, TensorFlow, and ONNX, offering tools to optimize, deploy, and scale AI
applications efficiently.

You can check some of their [C++
examples](https://docs.openvino.ai/2024/learn-openvino/openvino-samples.html)
demonstrating tasks like model loading, inference, and performance benchmarking, to help
you get started.

For more details, visit the [OpenVINO documentation](https://docs.openvino.ai/2024/).

#### mlpack

**mlpack** is a fast and flexible header-only C++ library for machine learning, designed
for both lightweight deployment and interactive prototyping via tools like C++ notebooks.
It offers a broad range of algorithms for classification, regression, clustering, and
more, along with preprocessing utilities and transformations.

To explore [mlpack](https://www.mlpack.org/), visit the [examples
repository](https://github.com/mlpack/examples/tree/master/cpp), which showcases C++
applications like training neural networks for digit recognition, using decision trees to
predict loan defaults, and applying clustering to find patterns in healthcare datasets.

For more details, visit the [mlpack documentation](https://www.mlpack.org/).

### Dlib

**Dlib** is a modern C++ library offering advanced machine learning algorithms and
computer vision functionalities, widely adopted in research and industry. Its
well-designed API and comprehensive documentation make it easy to integrate ML
capabilities into existing projects.

It provides algorithms for facial detection, landmark recognition, object classification,
and tracking. Examples showcasing these algorithms can be found in [their GitHub
repository](https://github.com/davisking/dlib/tree/master/examples). For more details,
visit the [Dlib official site](http://dlib.net/).

## Conclusion

There is a wide variety of libraries available in C++ for working with AI. An additional
advantage is the ability to customize optimizations for different platforms, enabling
faster and more energy-efficient AI workflows. With Conan, integrating these libraries
into your projects is both straightforward and flexible.

With C++ and these libraries, getting started with AI is easier than you think. Give them
a try and see what you can build!
