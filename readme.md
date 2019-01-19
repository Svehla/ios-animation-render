
# Ios Animation render

This project works for inspiration how to render CAnimation to `video` file

## Recommendation
Copy and paste source code of animation-render => read and customize source configs

### Test render on real device

Text of `CATextLayer` sometimes does not work because of virtual iphone on macbook 😔

[more about this issue](https://stackoverflow.com/questions/39760147/ios-10-0-10-1-avplayerlayer-doesnt-show-video-after-using-avvideocomposition)


## Usage
code is compatible with `swift 4.2` 

### Core animation
- you have to use CoreAnimation (UIView.animate can't be rendered to the video)

### Fake bg video
because AVVideoCompositionCoreAnimationTool cant render animation without bg video
you have to create `unecessaryVideo` to your xcode project
[more about this issue](https://stackoverflow.com/questions/10281872/catextlayer-doesnt-appear-in-an-avmutablecomposition-when-running-from-a-unit-t)

      


```swift
/*
        __
    ___( o)>
    \ <_. )
      `---'   svehlify...
*/
  let renderVideoAnimation: CALayer = /* your cool CALayer with core animation */
  
  let renderAnimator = RenderAnimation()
  // final length of video (animation) depends on length of audioUrl
  renderAnimator.renderAnimation(
    screenWidth: 500, /* px */
    screenHeight: 500, /* px */
    animationLayer: renderVideoAnimation,
    audioUrl: URL(/* ... path to audio ... */)
    complete: { pathToVideo in /* (URL?) -> Void callback  */
      /* ... */
    }
  )
/*
      __
    <(o )___
    ( ._> /
      `---'   ...svehlify
*/
```


## Should you use it?

`+` `animation-render.swift` is good for inspiration of your custom core video render project.

`-` if you're not advanced user. |ou should maybe try to install some more user friendly lib for video render instead of using custom implemenation like this.

