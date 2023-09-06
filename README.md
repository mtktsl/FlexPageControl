# FlexPageControl
ReadMe is currently work in progress. <br/>

Sample initializer:
```swift
lazy var flex: FlexPageControl = {
    let flex = FlexPageControl()
    flex.pageIndicatorTintColor = .white
    flex.pageIndicatorBorderColor = .darkGray
    flex.currentPageIndicatorTintColor = .systemPurple
    flex.currentPageIndicatorBorderColor = .purple
    flex.numberOfPages = 15
    flex.delegate = self
    return flex
}()
```
