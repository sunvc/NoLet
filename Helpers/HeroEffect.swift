//
//
//  pushback
//
//  Created by uuneo 2024/10/26.
//

import SwiftUI

// MARK: - Particle

/// Particle Model
struct Particle: Identifiable {
	var id: UUID = .init()
	var randomX: CGFloat = 0
	var randomY: CGFloat = 0
	var scale: CGFloat = 1
	/// Optional
	var opacity: CGFloat = 1
	
	/// Reset's All Properties
	mutating func reset() {
		randomX = 0
		randomY = 0
		scale = 1
		opacity = 1
	}
}


// MARK: Usage
/// - Drag the Hero.swift file into your app directory
/// - Wrap your App Entry Point with HeroWrapper { }
/// - Use SourceView, DestinationView & .heroLayer { } for hero effect
// NOTE: Each Hero Effect must contain its source, destination, and layer views, respectively.
// NOTE: Disable the default sheet interactive dismiss and navigation back button if you're using a sheet or navigation destination.
// NOTE: NavigationLink must be used with isPresented property, eg:
/// - .navigationDestination(isPresented: value, destination: view)

// MARK: Hero Wrapper
struct HeroWrapper<Content: View>: View {
	@ViewBuilder var content: Content
	/// View Properties
	@Environment(\.scenePhase) private var scene
	@State private var overlayWindow: PassthroughWindow?
	@StateObject private var heroModel: HeroModel = .init()
	var body: some View {
		content
			.customOnChange(value: scene) { newValue in
				if newValue == .active { addOverlayWindow() }
			}
			.environmentObject(heroModel)
	}
	
	/// Adding Overlay Window
	func addOverlayWindow() {
		for scene in UIApplication.shared.connectedScenes {
			/// Finding Active Scene
			if let windowScene = scene as? UIWindowScene, scene.activationState == .foregroundActive, overlayWindow == nil {
				let window = PassthroughWindow(windowScene: windowScene)
				window.backgroundColor = .clear
				window.isUserInteractionEnabled = false
				window.isHidden = false
				let rootController = UIHostingController(rootView: HeroLayerView().environmentObject(heroModel))
				rootController.view.frame = windowScene.screen.bounds
				rootController.view.backgroundColor = .clear
				
				window.rootViewController = rootController
				
				self.overlayWindow = window
			}
		}
		
		if overlayWindow == nil {
            NLog.log("NO WINDOW SCENE FOUND")
		}
	}
}

// MARK: Source View
struct SourceView<Content: View>: View {
	let id: String
	@ViewBuilder var content: Content
	@EnvironmentObject private var heroModel: HeroModel
	var body: some View {
		content
			.opacity(opacity)
			/// Continuous Source Anchor Update
			.anchorPreference(key: ContinuousAnchorKey.self, value: .bounds, transform: { anchor in
				if let index, heroModel.info[index].isActive {
					return [id: anchor]
				}
				
				return [:]
			})
			/// Source Anchor For Hero Animation
			.anchorPreference(key: AnchorKey.self, value: .bounds, transform: { anchor in
				if let index, heroModel.info[index].isActive {
					return [id: anchor]
				}
				
				return [:]
			})
			.onPreferenceChange(AnchorKey.self) { value in
				if let index, heroModel.info[index].isActive, heroModel.info[index].sourceAnchor == nil {
					heroModel.info[index].sourceAnchor = value[id]
				}
			}
			.onPreferenceChange(ContinuousAnchorKey.self) { value in
				if let index, heroModel.info[index].isActive, heroModel.info[index].updateSourceContinuously {
					heroModel.info[index].lastSourceAnchor = value[id]
				}
			}
	}
	
	var index: Int? {
		if let index = heroModel.info.firstIndex(where: { $0.infoID == id }) {
			return index
		}
		return nil
	}
	
	var opacity: CGFloat {
		if let index {
			return heroModel.info[index].destinationAnchor == nil ? 1 : 0
		}
		
		return 1
	}
}

// MARK: Destination View
struct DestinationView<Content: View>: View {
	var id: String
	@ViewBuilder var content: Content
	@EnvironmentObject private var heroModel: HeroModel
	var body: some View {
		content
			.opacity(opacity)
			.anchorPreference(key: AnchorKey.self, value: .bounds, transform: { anchor in
				if let index, heroModel.info[index].isActive {
					return ["\(id)DESTINATION": anchor]
				}
				
				return [:]
			})
			.onPreferenceChange(AnchorKey.self, perform: { value in
				if let index, heroModel.info[index].isActive, !heroModel.info[index].hideView {
					heroModel.info[index].destinationAnchor = value["\(id)DESTINATION"]
				}
			})
	}
	
	var index: Int? {
		if let index = heroModel.info.firstIndex(where: { $0.infoID == id }) {
			return index
		}
		return nil
	}
	
	var opacity: CGFloat {
		if let index {
			return heroModel.info[index].isActive ? (heroModel.info[index].hideView ? 1 : 0) : 1
		}
		
		return 1
	}
}

extension View {
	@ViewBuilder
	func heroLayer<Content: View>(
		id: String,
		animate: Binding<Bool>,
		sourceCornerRadius: CGFloat = 0,
		destinationCornerRadius: CGFloat = 0,
		zIndex: Double = 0,
		updateSourceContinuously: Bool = false,
		@ViewBuilder content: @escaping () -> Content,
		completion: @escaping (Bool) -> () = { _ in }
	) -> some View {
		self
			.modifier(HeroLayerViewModifier(
				id: id,
				animate: animate,
				sourceCornerRadius: sourceCornerRadius,
				destinationCornerRadius: destinationCornerRadius,
				zIndex: zIndex,
				updateSourceContinuously: updateSourceContinuously,
				layer: content,
				completion: completion
			))
	}
}

fileprivate struct HeroLayerViewModifier<Layer: View>: ViewModifier {
	let id: String
	@Binding var animate: Bool
	var sourceCornerRadius: CGFloat
	var destinationCornerRadius: CGFloat
	var zIndex: Double
	var updateSourceContinuously: Bool
	@ViewBuilder var layer: Layer
	var completion: (Bool) -> ()
	/// Hero Model
	@EnvironmentObject private var heroModel: HeroModel
	func body(content: Content) -> some View {
		content
			.onAppear {
				if !heroModel.info.contains(where: { $0.infoID == id }) {
					heroModel.info.append(.init(id: id))
				}
			}
			.customOnChange(value: animate) { newValue in
				if let index = heroModel.info.firstIndex(where: { $0.infoID == id }) {
					/// Setting up all the necessary properties for the animation
					heroModel.info[index].isActive = true
					heroModel.info[index].layerView = AnyView(layer)
					heroModel.info[index].sCornerRadius = sourceCornerRadius
					heroModel.info[index].dCornerRadius = destinationCornerRadius
					heroModel.info[index].zIndex = zIndex
					heroModel.info[index].updateSourceContinuously = updateSourceContinuously
					heroModel.info[index].completion = completion
					
					if newValue {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
							withAnimation(.snappy(duration: 0.35, extraBounce: 0)) {
								heroModel.info[index].animateView = true
							}
						}
					} else {
						if let lastSourceAnchor = heroModel.info[index].lastSourceAnchor, updateSourceContinuously {
							heroModel.info[index].sourceAnchor = lastSourceAnchor
						}
						
						 DispatchQueue.main.async {
							heroModel.info[index].hideView = false
							withAnimation(.snappy(duration: 0.35, extraBounce: 0)) {
								heroModel.info[index].animateView = false
							}
						}
					}
				}
			}
	}
}

// MARK: Hero Layer View for Animation
fileprivate struct HeroLayerView: View {
	@EnvironmentObject private var heroModel: HeroModel
	var body: some View {
		GeometryReader { proxy in
			ForEach($heroModel.info) { $info in
				ZStack {
					if let sourceAnchor = info.sourceAnchor,
					   let destinationAnchor = info.destinationAnchor,
					   let layerView = info.layerView,
					   !info.hideView {
						/// Retreving Bounds data from the anchor values
						let sRect = proxy[sourceAnchor]
						let dRect = proxy[destinationAnchor]
						let animateView = info.animateView
						
						let size = CGSize(
							width: animateView ? dRect.size.width : sRect.size.width,
							height: animateView ? dRect.size.height : sRect.size.height
						)
						
						/// Position
						let offset = CGSize(
							width: animateView ? dRect.minX : sRect.minX,
							height: animateView ? dRect.minY : sRect.minY
						)
						
						layerView
							.frame(width: size.width, height: size.height)
							.clipShape(.rect(cornerRadius: animateView ? info.dCornerRadius : info.sCornerRadius))
							.offset(offset)
							.transition(.identity)
							.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
					}
				}
				.zIndex(info.zIndex)
				.customOnChange(value: info.animateView) { newValue in
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
						if !newValue {
							/// Resetting All data once the view goes back to it's source state
							info.isActive = false
							info.layerView = nil
							info.sourceAnchor = nil
							info.destinationAnchor = nil
							info.sCornerRadius = 0
							info.dCornerRadius = 0
							info.zIndex = 0
							
							info.completion(false)
						} else {
							info.hideView = true
							info.completion(true)
						}
					}
				}
			}
		}
	}
}

/// Environment Object
fileprivate class HeroModel: ObservableObject {
	@Published var info: [HeroInfo] = []
}

/// Individual Hero Animation View Info
fileprivate struct HeroInfo: Identifiable {
	private(set) var id: UUID = .init()
	private(set) var infoID: String
	var isActive: Bool = false
	var layerView: AnyView?
	var animateView: Bool = false
	/// Status of the Hero Animation Layer View
	var hideView: Bool = false
	var sourceAnchor: Anchor<CGRect>?
	var destinationAnchor: Anchor<CGRect>?
	/// Set this to true if you're source will move when a detailed view is shown.
	var updateSourceContinuously: Bool = false
	var lastSourceAnchor: Anchor<CGRect>?
	var sCornerRadius: CGFloat = 0
	var dCornerRadius: CGFloat = 0
	var zIndex: Double = 0
	var completion: (Bool) -> () = { _ in }
	
	init(id: String) {
		self.infoID = id
	}
}

fileprivate struct AnchorKey: PreferenceKey {
	static var defaultValue: [String: Anchor<CGRect>] = [:]
	static func reduce(value: inout [String : Anchor<CGRect>], nextValue: () -> [String : Anchor<CGRect>]) {
		value.merge(nextValue()) { $1 }
	}
}

fileprivate struct ContinuousAnchorKey: PreferenceKey {
	static var defaultValue: [String: Anchor<CGRect>] = [:]
	static func reduce(value: inout [String : Anchor<CGRect>], nextValue: () -> [String : Anchor<CGRect>]) {
		value.merge(nextValue()) { $1 }
	}
}

extension View {
	@ViewBuilder
	func customOnChange<Value: Equatable>(value: Value, completion: @escaping (Value) -> ()) -> some View {
		if #available(iOS 17, *) {
			self
				.onChange(of: value) { oldValue, newValue in
					completion(newValue)
				}
		} else {
			self
				.onChange(of: value, perform: { value in
					completion(value)
				})
		}
	}
}


