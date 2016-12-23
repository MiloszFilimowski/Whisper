import UIKit

let shoutView = ShoutView()

open class ShoutView: UIView {

  public struct Dimensions {
    public static let indicatorHeight: CGFloat = 6
    public static let indicatorWidth: CGFloat = 50
    public static let imageSize: CGFloat = 42
    public static let secondaryImageSize: CGFloat = 24
    public static let imageOffset: CGFloat = 18
    public static var textOffset: CGFloat = 75
    public static var touchOffset: CGFloat = 40
  }

  open fileprivate(set) lazy var backgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Shout.background
    view.alpha = 0.98
    view.clipsToBounds = true

    return view
    }()

  open fileprivate(set) lazy var indicatorView: UIView = {
    let view = UIView()
    view.backgroundColor = ColorList.Shout.dragIndicator
    view.layer.cornerRadius = Dimensions.indicatorHeight / 2
    view.isUserInteractionEnabled = true

    return view
    }()

  open fileprivate(set) lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.layer.cornerRadius = Dimensions.imageSize / 2
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFill

    return imageView
    }()

  open fileprivate(set) lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 2
    label.lineBreakMode = .byWordWrapping
    return label
    }()
  
  open fileprivate(set) lazy var secondaryImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.layer.cornerRadius = 5
    imageView.clipsToBounds = true
    imageView.contentMode = .scaleAspectFill
    
    return imageView
    }()

  open fileprivate(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
    let gesture = UITapGestureRecognizer()
    gesture.addTarget(self, action: #selector(ShoutView.handleTapGestureRecognizer))

    return gesture
    }()

  open fileprivate(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = { [unowned self] in
    let gesture = UIPanGestureRecognizer()
    gesture.addTarget(self, action: #selector(ShoutView.handlePanGestureRecognizer))

    return gesture
    }()

  open fileprivate(set) var announcement: Announcement?
  open fileprivate(set) var displayTimer = Timer()
  open fileprivate(set) var panGestureActive = false
  open fileprivate(set) var shouldSilent = false
  open fileprivate(set) var completion: (() -> ())?

  private var titleLabelOriginalHeight: CGFloat = 0
  private var internalHeight: CGFloat = 0

  // MARK: - Initializers

  public override init(frame: CGRect) {
    super.init(frame: frame)

    addSubview(backgroundView)
    [imageView, titleLabel, secondaryImageView, indicatorView].forEach {
      $0.autoresizingMask = []
      backgroundView.addSubview($0)
    }

    clipsToBounds = false
    isUserInteractionEnabled = true
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOffset = CGSize(width: 0, height: 0.5)
    layer.shadowOpacity = 0.1
    layer.shadowRadius = 0.5
    
    backgroundView.addGestureRecognizer(tapGestureRecognizer)
    addGestureRecognizer(panGestureRecognizer)

    NotificationCenter.default.addObserver(self, selector: #selector(ShoutView.orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
  }

  // MARK: - Configuration

  open func craft(_ announcement: Announcement, to: UIViewController, completion: (() -> ())?) {
    panGestureActive = false
    shouldSilent = false
    configureView(announcement)
    shout(to: to)

    self.completion = completion
  }

  open func configureView(_ announcement: Announcement) {
    self.announcement = announcement
    
    self.backgroundView.backgroundColor = announcement.backgroundColor
    imageView.image = announcement.image
    secondaryImageView.image = announcement.secondaryImage
    titleLabel.textColor = announcement.titleColor
    titleLabel.font = announcement.titleFont
    
    if let title = announcement.title {
      titleLabel.text = title
    }
    
    if let attributedTitle = announcement.attributedTitle {
      titleLabel.attributedText = attributedTitle;
    }
    
    displayTimer.invalidate()
    displayTimer = Timer.scheduledTimer(timeInterval: announcement.duration,
      target: self, selector: #selector(ShoutView.displayTimerDidFire), userInfo: nil, repeats: false)

    setupFrames()
  }

  open func shout(to controller: UIViewController) {
    controller.view.addSubview(self)

    frame.size.height = 0
    UIView.animate(withDuration: 0.35, animations: {
      self.frame.size.height = self.internalHeight + Dimensions.touchOffset
    })
  }

  // MARK: - Setup

  public func setupFrames() {
    internalHeight = (UIApplication.shared.isStatusBarHidden ? 70 : 85)

    let totalWidth = UIScreen.main.bounds.width
    let offset: CGFloat = UIApplication.shared.isStatusBarHidden ? 2.5 : 5
    let textOffsetX: CGFloat = imageView.image != nil ? Dimensions.textOffset : 18
    let imageSize: CGFloat = imageView.image != nil ? Dimensions.imageSize : 0
    let secondaryImageSize: CGFloat = secondaryImageView.image != nil ? Dimensions.secondaryImageSize : 0

    titleLabel.frame.size.width = totalWidth - imageSize - secondaryImageSize - (Dimensions.imageOffset * 4)
    titleLabel.sizeToFit()
    
    imageView.frame = CGRect(x: Dimensions.imageOffset, y: (internalHeight - imageSize) / 2 + offset,
      width: imageSize, height: imageSize)

    secondaryImageView.frame = CGRect(x: totalWidth - 50, y: (internalHeight - secondaryImageSize) / 2 + offset,
      width: secondaryImageSize, height: secondaryImageSize)
    
    titleLabel.frame.origin.x = textOffsetX
    titleLabel.center.y = imageView.center.y

    frame = CGRect(x: 0, y: 0, width: totalWidth, height: internalHeight + Dimensions.touchOffset)
  }

  // MARK: - Frame

  open override var frame: CGRect {
    didSet {
      backgroundView.frame = CGRect(x: 0, y: 0,
                                    width: frame.size.width,
                                    height: frame.size.height - Dimensions.touchOffset)

      indicatorView.frame = CGRect(x: (backgroundView.frame.size.width - Dimensions.indicatorWidth) / 2,
                                   y: backgroundView.frame.height - Dimensions.indicatorHeight - 5,
                                   width: Dimensions.indicatorWidth,
                                   height: Dimensions.indicatorHeight)
    }
  }

  // MARK: - Actions

  open func silent() {
    UIView.animate(withDuration: 0.35, animations: {
      self.frame.size.height = 0
      }, completion: { finished in
        self.completion?()
        self.displayTimer.invalidate()
        self.removeFromSuperview()
    })
  }

  // MARK: - Timer methods

  open func displayTimerDidFire() {
    shouldSilent = true

    if panGestureActive { return }
    silent()
  }

  // MARK: - Gesture methods

  @objc fileprivate func handleTapGestureRecognizer() {
    guard let announcement = announcement else { return }
    announcement.action?()
    silent()
  }
  
  @objc private func handlePanGestureRecognizer() {
    let translation = panGestureRecognizer.translation(in: self)

    if panGestureRecognizer.state == .began {
      titleLabelOriginalHeight = titleLabel.bounds.size.height
      titleLabel.numberOfLines = 0
      titleLabel.sizeToFit()
    } else if panGestureRecognizer.state == .changed {
      panGestureActive = true
      
      let maxTranslation = titleLabel.bounds.size.height - titleLabelOriginalHeight
      
      if translation.y >= maxTranslation {
        frame.size.height = internalHeight + maxTranslation
          + (translation.y - maxTranslation) / 25 + Dimensions.touchOffset
      } else {
        frame.size.height = internalHeight + translation.y + Dimensions.touchOffset
      }
    } else {
      panGestureActive = false
      let height = translation.y < -5 || shouldSilent ? 0 : internalHeight

      titleLabel.numberOfLines = 2
      titleLabel.sizeToFit()
      
      UIView.animate(withDuration: 0.2, animations: {
        self.frame.size.height = height + Dimensions.touchOffset
      }, completion: { _ in
          if translation.y < -5 {
            self.completion?()
            self.removeFromSuperview()
        }
      })
    }
  }


  // MARK: - Handling screen orientation

  func orientationDidChange() {
    setupFrames()
  }
}
