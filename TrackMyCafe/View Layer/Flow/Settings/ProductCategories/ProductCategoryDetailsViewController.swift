import PhotosUI
import TinyConstraints
import UIKit

final class ProductCategoryDetailsViewController: UIViewController, Loggable {
    private let viewModel: ProductCategoryDetailsViewModelType
    private var isImagePresent: Bool = false
    private var isSaving = false

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UIConstants.standardPadding
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        view.isUserInteractionEnabled = true
        view.backgroundColor = UIColor.TabBar.tint.alpha(0.12)
        view.accessibilityTraits = [.image]
        return view
    }()

    private lazy var imageLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var nameInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.productCategories(),
            inputType: .text(keyboardType: .default),
            isEditable: true,
            placeholder: R.string.global.enterProductName()
        )
        container.setReturnKeyType(.done)
        container.setDelegate(self)
        return container
    }()

    private lazy var saveButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.save(), for: .normal)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()

    init(viewModel: ProductCategoryDetailsViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Main.background
        title = viewModel.title

        view.addSubview(scrollView)
        view.addSubview(saveButton)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(nameInputContainer)
        imageView.addSubview(imageLoadingIndicator)

        imageView.height(180)
        imageLoadingIndicator.centerInSuperview()
        nameInputContainer.height(
            UIConstants.cellHeight + UIConstants.largeSpacing + UIConstants.standardPadding)

        scrollView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        scrollView.bottomToTop(of: saveButton, offset: -UIConstants.standardPadding)

        let horizontalInset = UIConstants.standardPadding
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let fillWidth = stackView.widthAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.widthAnchor,
            constant: -2 * horizontalInset
        )
        fillWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: UIConstants.largeSpacing
            ),
            stackView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -UIConstants.largeSpacing
            ),
            stackView.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            stackView.leadingAnchor.constraint(
                greaterThanOrEqualTo: scrollView.frameLayoutGuide.leadingAnchor,
                constant: horizontalInset
            ),
            stackView.trailingAnchor.constraint(
                lessThanOrEqualTo: scrollView.frameLayoutGuide.trailingAnchor,
                constant: -horizontalInset
            ),
            fillWidth,
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
        ])

        saveButton.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
        saveButton.height(UIConstants.buttonHeight)
        let saveBottom = saveButton.bottomAnchor.constraint(
            equalTo: view.keyboardLayoutGuide.topAnchor,
            constant: -UIConstants.standardPadding
        )
        saveBottom.isActive = true

        imageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(imageTapped)))

        nameInputContainer.text = viewModel.name
        applyInitialImage()
    }

    private func applyInitialImage() {
        let placeholder = AppImagePlaceholder.category()
        if let path = viewModel.imagePath, !path.isEmpty {
            isImagePresent = true
            imageView.setImage(pathOrURL: path, placeholder: placeholder)
        } else {
            isImagePresent = false
            imageView.image = placeholder
        }
    }

    @objc private func imageTapped() {
        guard !isSaving else { return }
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )

        alert.addAction(
            UIAlertAction(title: R.string.global.gallery(), style: .default) { [weak self] _ in
                self?.presentPhotoPicker()
            }
        )

        if isImagePresent {
            alert.addAction(
                UIAlertAction(title: R.string.global.delete(), style: .destructive) {
                    [weak self] _ in
                    self?.viewModel.markImageDeleted()
                    self?.applyInitialImage()
                }
            )
        }

        alert.addAction(UIAlertAction(title: R.string.global.cancel(), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = imageView
            popover.sourceRect = imageView.bounds
        }

        present(alert, animated: true)
    }

    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func saveTapped() {
        view.endEditing(true)
        setSavingState(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                self.viewModel.setName(self.nameInputContainer.text)
                try await self.viewModel.save()
                _ = await MainActor.run {
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                _ = await MainActor.run {
                    let description =
                        error.localizedDescription.isEmpty
                        ? R.string.global.failedToSaveProductCategory()
                        : error.localizedDescription
                    PopupFactory.showPopup(
                        title: R.string.global.error(),
                        description: description
                    ) {}
                }
            }
            _ = await MainActor.run {
                self.setSavingState(false)
            }
        }
    }

    private func setSavingState(_ isSaving: Bool) {
        self.isSaving = isSaving
        saveButton.isEnabled = !isSaving
        saveButton.setTitle(
            isSaving ? R.string.global.loading() : R.string.global.save(),
            for: .normal
        )
    }

    private func setImageLoading(_ isLoading: Bool) {
        imageView.isUserInteractionEnabled = !isLoading && !isSaving
        if isLoading {
            imageLoadingIndicator.startAnimating()
        } else {
            imageLoadingIndicator.stopAnimating()
        }
    }

    private func makeJPEGData(from image: UIImage) -> Data? {
        let maxDimension: CGFloat = 1400
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > 0 else { return nil }
        let scale = min(1, maxDimension / longestSide)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return rendered.jpegData(compressionQuality: 0.86)
    }
}

extension ProductCategoryDetailsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ProductCategoryDetailsViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let item = results.first?.itemProvider else { return }

        Task { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.setImageLoading(true)
            }
            defer {
                Task { @MainActor [weak self] in
                    self?.setImageLoading(false)
                }
            }
            let image = await self.loadImage(from: item)
            guard let image else { return }

            let data = self.makeJPEGData(from: image)
            guard let data else { return }

            self.viewModel.setSelectedImageData(data)
            _ = await MainActor.run {
                self.imageView.image = image
                self.isImagePresent = true
            }
        }
    }

    private func loadImage(from provider: NSItemProvider) async -> UIImage? {
        await withCheckedContinuation { continuation in
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    continuation.resume(returning: object as? UIImage)
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}
