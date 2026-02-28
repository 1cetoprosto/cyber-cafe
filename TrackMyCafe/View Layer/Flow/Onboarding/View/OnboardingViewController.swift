import UIKit
import TinyConstraints

protocol OnboardingViewControllerDelegate: AnyObject {
    func didFinishOnboarding()
}

final class OnboardingViewController: UIViewController {

    weak var delegate: OnboardingViewControllerDelegate?
    private let viewModel: OnboardingViewModelType
    private var currentPage = 0 {
        didSet {
            pageControl.currentPage = currentPage
            updateButtonTitle()
        }
    }

    // MARK: - UI Elements

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(OnboardingCell.self, forCellWithReuseIdentifier: OnboardingCell.reuseId)
        return cv
    }()

    private lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.numberOfPages = viewModel.slides.count
        pc.currentPage = 0
        pc.currentPageIndicatorTintColor = UIColor.Main.text
        pc.pageIndicatorTintColor = UIColor.Main.secondaryText
        pc.isUserInteractionEnabled = false
        return pc
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor.Main.text
        button.setTitleColor(UIColor.Main.background, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(viewModel: OnboardingViewModelType = OnboardingViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor.Main.background

        view.addSubview(collectionView)
        view.addSubview(pageControl)
        view.addSubview(nextButton)

        collectionView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        collectionView.bottomToTop(of: pageControl, offset: -20)

        pageControl.centerXToSuperview()
        pageControl.bottomToTop(of: nextButton, offset: -20)

        nextButton.edgesToSuperview(excluding: .top, insets: .bottom(50) + .left(24) + .right(24))
        nextButton.height(50)
    }

    private func updateButtonTitle() {
        let title = (currentPage == viewModel.slides.count - 1) ? "Get Started" : "Next"
        nextButton.setTitle(title, for: .normal)
    }

    // MARK: - Actions

    @objc private func nextButtonTapped() {
        if currentPage == viewModel.slides.count - 1 {
            delegate?.didFinishOnboarding()
        } else {
            currentPage += 1
            let indexPath = IndexPath(item: currentPage, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

// MARK: - UICollectionViewDelegate & DataSource

extension OnboardingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.slides.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnboardingCell.reuseId, for: indexPath) as! OnboardingCell
        cell.configure(with: viewModel.slides[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        currentPage = Int(scrollView.contentOffset.x / width)
    }
}
