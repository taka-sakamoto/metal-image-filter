# Metal Image Filter App

A real-time image filtering app built with Metal and SwiftUI.

## 🚀 Features

- Grayscale filter
- Sepia filter
- Blur filter (multi-sampling)
- Intensity control slider
- Before / After comparison slider
- Image saving to Photos
- Save confirmation toast message

## 🛠 Tech Stack

- SwiftUI
- Metal (GPU-based rendering)
- MTKView

## ✨ Highlights

- Real-time image processing using GPU
- Custom fragment shaders for each filter
- Adjustable intensity for all filters
- Interactive Before/After comparison with a draggable slider
- Clean UI built with SwiftUI

## 📱 Screenshots

<p float="left">
  <img src="Iscreenshot1.png" />
  <img src="Iscreenshot2.png" />
  <img src="Iscreenshot3.png" />
</p>

## 🎯 Purpose

This project was built to learn and demonstrate:
- GPU-based rendering with Metal
- Shader programming
- Integration of Metal with SwiftUI
- Real-time UI interaction

## 📌 Notes

- Blur is implemented using a simple 1-pass multi-sampling approach
- No third-party libraries are used

## 🔧 Future Improvements

- Implement Gaussian blur (2-pass)
- Add more filters (e.g., vignette, edge detection)
- Support real-time camera input
- Improve UI/UX


