//
//  OnboardingViewController.swift
//  TrackMyCafe
//

import TinyConstraints
import UIKit

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
        pc.currentPageIndicatorTintColor = UIColor.Button.background
        pc.pageIndicatorTintColor = Theme.current.secondaryText.withAlphaComponent(0.35)
        pc.isUserInteractionEnabled = false
        return pc
    }()

    private lazy var nextButton: DefaultButton = {
        let button = DefaultButton()
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
        updateButtonTitle()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = Theme.current.primaryBackground

        view.addSubview(collectionView)
        view.addSubview(pageControl)
        view.addSubview(nextButton)

        collectionView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        collectionView.bottomToTop(of: pageControl, offset: -12)

        pageControl.centerXToSuperview()
        pageControl.bottomToTop(of: nextButton, offset: -16)

        nextButton.leftToSuperview(offset: 24)
        nextButton.rightToSuperview(offset: -24)
        nextButton.bottomToSuperview(offset: -20, usingSafeArea: true)
        nextButton.height(56)
    }

    private func updateButtonTitle() {
        guard viewModel.slides.indices.contains(currentPage) else { return }
        nextButton.setTitle(viewModel.slides[currentPage].buttonTitle, for: .normal)
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

extension OnboardingViewController: UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
{

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        viewModel.slides.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OnboardingCell.reuseId,
                for: indexPath
            ) as? OnboardingCell
        else {
            return UICollectionViewCell()
        }
        cell.configure(with: viewModel.slides[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.frame.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        guard width > 0 else { return }
        currentPage = Int(scrollView.contentOffset.x / width)
    }
}
