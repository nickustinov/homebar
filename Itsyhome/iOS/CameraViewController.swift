//
//  CameraViewController.swift
//  Itsyhome
//
//  Grid of camera views displayed in the menu bar panel
//

import UIKit
import HomeKit

class CameraViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var emptyLabel: UILabel!
    private var streamContainerView: UIView!
    private var streamCameraView: HMCameraView!
    private var streamSpinner: UIActivityIndicatorView!
    private var backButton: UIButton!

    private static let gridWidth: CGFloat = 300
    private static let streamWidth: CGFloat = 530
    private static let streamHeight: CGFloat = 298 // 16:9

    private static let sectionTop: CGFloat = 15
    private static let sectionBottom: CGFloat = 15
    private static let sectionSide: CGFloat = 12
    private static let lineSpacing: CGFloat = 8
    private static let labelHeight: CGFloat = 28 // 2pt gap + 16pt label + 6pt bottom + 4pt

    private var cameraAccessories: [HMAccessory] = []
    private var snapshotControls: [UUID: HMCameraSnapshotControl] = [:]
    private var activeStreamControl: HMCameraStreamControl?
    private var snapshotTimer: Timer?
    private var hasLoadedInitialData = false

    private var macOSController: iOS2Mac? {
        (UIApplication.shared.delegate as? AppDelegate)?.macOSController
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        setupCollectionView()
        setupEmptyState()
        setupStreamView()
        loadCameras()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !hasLoadedInitialData && !cameraAccessories.isEmpty {
            hasLoadedInitialData = true
            emptyLabel.isHidden = !cameraAccessories.isEmpty
            collectionView.isHidden = cameraAccessories.isEmpty
            collectionView.reloadData()
            takeAllSnapshots()
        }

        collectionView.setContentOffset(.zero, animated: false)
        startSnapshotTimer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopSnapshotTimer()
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = Self.lineSpacing
        layout.minimumLineSpacing = Self.lineSpacing
        layout.sectionInset = UIEdgeInsets(top: Self.sectionTop, left: Self.sectionSide, bottom: Self.sectionBottom, right: Self.sectionSide)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CameraSnapshotCell.self, forCellWithReuseIdentifier: CameraSnapshotCell.reuseId)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyLabel = UILabel()
        emptyLabel.text = "No cameras found"
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .systemFont(ofSize: 14, weight: .medium)
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupStreamView() {
        streamContainerView = UIView()
        streamContainerView.translatesAutoresizingMaskIntoConstraints = false
        streamContainerView.backgroundColor = .black
        streamContainerView.isHidden = true
        view.addSubview(streamContainerView)

        NSLayoutConstraint.activate([
            streamContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            streamContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            streamContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            streamContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        streamSpinner = UIActivityIndicatorView(style: .medium)
        streamSpinner.color = .white
        streamSpinner.translatesAutoresizingMaskIntoConstraints = false
        streamSpinner.hidesWhenStopped = true
        streamContainerView.addSubview(streamSpinner)

        NSLayoutConstraint.activate([
            streamSpinner.centerXAnchor.constraint(equalTo: streamContainerView.centerXAnchor),
            streamSpinner.centerYAnchor.constraint(equalTo: streamContainerView.centerYAnchor)
        ])

        streamCameraView = HMCameraView()
        streamCameraView.translatesAutoresizingMaskIntoConstraints = false
        streamContainerView.addSubview(streamCameraView)

        NSLayoutConstraint.activate([
            streamCameraView.topAnchor.constraint(equalTo: streamContainerView.topAnchor),
            streamCameraView.leadingAnchor.constraint(equalTo: streamContainerView.leadingAnchor),
            streamCameraView.trailingAnchor.constraint(equalTo: streamContainerView.trailingAnchor),
            streamCameraView.bottomAnchor.constraint(equalTo: streamContainerView.bottomAnchor)
        ])

        backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(systemName: "chevron.left")?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        backButton.setTitle(" Back", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        backButton.backgroundColor = UIColor(white: 0, alpha: 0.5)
        backButton.layer.cornerRadius = 14
        backButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 12)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backToGrid), for: .touchUpInside)
        streamContainerView.addSubview(backButton)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: streamContainerView.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: streamContainerView.leadingAnchor, constant: 8)
        ])
    }

    // MARK: - Camera loading

    private func loadCameras() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
              let homeKitManager = appDelegate.homeKitManager else { return }

        cameraAccessories = homeKitManager.cameraAccessories

        // Store desired size on macOS side (for re-shows); sizeRestrictions set by CameraSceneDelegate
        let height = computeGridHeight()
        macOSController?.resizeCameraPanel(width: Self.gridWidth, height: height, animated: false)
    }

    private func updatePanelSize(width: CGFloat, height: CGFloat, animated: Bool) {
        #if targetEnvironment(macCatalyst)
        if let windowScene = view.window?.windowScene {
            windowScene.sizeRestrictions?.minimumSize = CGSize(width: width, height: height)
            windowScene.sizeRestrictions?.maximumSize = CGSize(width: width, height: height)
        }
        #endif
        macOSController?.resizeCameraPanel(width: width, height: height, animated: animated)
    }

    private func computeGridHeight() -> CGFloat {
        let count = cameraAccessories.count
        guard count > 0 else { return 150 }

        let cellWidth = Self.gridWidth - Self.sectionSide * 2
        let cellHeight = cellWidth * 9.0 / 16.0 + Self.labelHeight

        if count <= 3 {
            // Show all cameras fully
            return Self.sectionTop + CGFloat(count) * cellHeight + CGFloat(count - 1) * Self.lineSpacing + Self.sectionBottom
        } else {
            // Show 3 full + half of 4th to hint at scrollability
            return Self.sectionTop + 3 * cellHeight + 2 * Self.lineSpacing + Self.lineSpacing + cellHeight * 0.5
        }
    }

    // MARK: - Snapshots

    private func takeAllSnapshots() {
        for accessory in cameraAccessories {
            guard let profile = accessory.cameraProfiles?.first,
                  let snapshotControl = profile.snapshotControl else { continue }

            snapshotControl.delegate = self
            snapshotControls[accessory.uniqueIdentifier] = snapshotControl
            snapshotControl.takeSnapshot()
        }
    }

    private func startSnapshotTimer() {
        snapshotTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.takeAllSnapshots()
        }
    }

    private func stopSnapshotTimer() {
        snapshotTimer?.invalidate()
        snapshotTimer = nil
    }

    // MARK: - Streaming

    private func startStream(for accessory: HMAccessory) {
        guard let profile = accessory.cameraProfiles?.first,
              let streamControl = profile.streamControl else { return }

        streamContainerView.isHidden = false
        streamCameraView.isHidden = true
        streamSpinner.startAnimating()
        collectionView.isHidden = true
        stopSnapshotTimer()

        updatePanelSize(width: Self.streamWidth, height: Self.streamHeight, animated: true)

        activeStreamControl = streamControl
        streamControl.delegate = self
        streamControl.startStream()
    }

    @objc private func backToGrid() {
        activeStreamControl?.stopStream()
        activeStreamControl = nil
        streamCameraView.cameraSource = nil
        streamCameraView.isHidden = false
        streamSpinner.stopAnimating()
        streamContainerView.isHidden = true
        collectionView.isHidden = cameraAccessories.isEmpty
        collectionView.setContentOffset(.zero, animated: false)

        let height = computeGridHeight()
        updatePanelSize(width: Self.gridWidth, height: height, animated: false)
        startSnapshotTimer()
    }

    // MARK: - Public

    func stopAllStreams() {
        activeStreamControl?.stopStream()
        activeStreamControl = nil
        stopSnapshotTimer()
    }
}

// MARK: - UICollectionViewDataSource

extension CameraViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        cameraAccessories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraSnapshotCell.reuseId, for: indexPath) as! CameraSnapshotCell
        let accessory = cameraAccessories[indexPath.item]
        cell.configure(name: accessory.name)

        if let snapshotControl = snapshotControls[accessory.uniqueIdentifier],
           let snapshot = snapshotControl.mostRecentSnapshot {
            cell.cameraView.cameraSource = snapshot
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension CameraViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let accessory = cameraAccessories[indexPath.item]
        startStream(for: accessory)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension CameraViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = max(1, collectionView.bounds.width - CameraViewController.sectionSide * 2)
        let height = width * 9.0 / 16.0 + CameraViewController.labelHeight
        return CGSize(width: width, height: height)
    }
}

// MARK: - HMCameraSnapshotControlDelegate

extension CameraViewController: HMCameraSnapshotControlDelegate {
    func cameraSnapshotControl(_ cameraSnapshotControl: HMCameraSnapshotControl, didTake snapshot: HMCameraSnapshot?, error: Error?) {
        guard error == nil else { return }
        for (index, accessory) in cameraAccessories.enumerated() {
            if snapshotControls[accessory.uniqueIdentifier] === cameraSnapshotControl {
                let indexPath = IndexPath(item: index, section: 0)
                DispatchQueue.main.async {
                    self.collectionView.reloadItems(at: [indexPath])
                }
                break
            }
        }
    }
}

// MARK: - HMCameraStreamControlDelegate

extension CameraViewController: HMCameraStreamControlDelegate {
    func cameraStreamControlDidStartStream(_ cameraStreamControl: HMCameraStreamControl) {
        DispatchQueue.main.async {
            self.streamSpinner.stopAnimating()
            self.streamCameraView.isHidden = false
            self.streamCameraView.cameraSource = cameraStreamControl.cameraStream
        }
    }

    func cameraStreamControl(_ cameraStreamControl: HMCameraStreamControl, didStopStreamWithError error: Error?) {
        if error != nil {
            DispatchQueue.main.async {
                self.backToGrid()
            }
        }
    }
}

// MARK: - CameraSnapshotCell

private class CameraSnapshotCell: UICollectionViewCell {
    static let reuseId = "CameraSnapshotCell"

    let cameraView = HMCameraView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        contentView.layer.cornerRadius = 6
        contentView.clipsToBounds = true

        cameraView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cameraView)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 11, weight: .medium)
        nameLabel.textColor = .white
        nameLabel.textAlignment = .center
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -2),

            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            nameLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func configure(name: String) {
        nameLabel.text = name
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cameraView.cameraSource = nil
        nameLabel.text = nil
    }
}
