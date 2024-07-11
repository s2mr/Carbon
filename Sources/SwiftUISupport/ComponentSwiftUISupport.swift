#if canImport(SwiftUI) && !(os(iOS) && (arch(i386) || arch(arm)))

import SwiftUI

@available(iOS 13.0, *)
public extension Component where Self: View {
    /// Declares the content and behavior of this view.
    var body: some View {
        ComponentView(self)
    }
}

@available(iOS 13.0, *)
private struct ComponentView<C: Component>: View {
    var component: C
    var proxy = ComponentViewProxy()

    init(_ component: C) {
        self.component = component
    }

    var body: some View {
        ComponentRepresenting(component: component, proxy: proxy)
            .onAppear { self.proxy.uiView?.contentWillDisplay() }
            .onDisappear { self.proxy.uiView?.contentDidEndDisplay() }
    }
}

private struct ComponentRepresenting<C: Component>: UIViewRepresentable {
    var component: C
    var proxy: ComponentViewProxy

    func makeUIView(context: Context) -> UIComponentView {
        UIComponentView()
    }

    func updateUIView(_ uiView: UIComponentView, context: Context) {
        uiView.render(component: AnyComponent(component))
        proxy.uiView = uiView
    }

    @available(iOS 16.0, *)
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UIComponentView,
        context: Context
    ) -> CGSize? {
        if let width = proposal.width, width.isFinite {
            uiView.bounds.size.width = width
        }
        if let height = proposal.height, height.isFinite {
            uiView.bounds.size.height = height
        }

        if uiView.intrinsicContentSize != CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric) {
            return uiView.intrinsicContentSize
        }

        return uiView.systemLayoutSizeFitting(
            proposal.replacingUnspecifiedDimensions(by: UIView.layoutFittingCompressedSize),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
    }
}

private final class UIComponentView: UIView, ComponentRenderable {
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
    }

    override var intrinsicContentSize: CGSize {
        if let referenceSize = renderedComponent?.referenceSize(in: bounds) {
            return referenceSize
        }
        else if let component = renderedComponent, let content = renderedContent {
            return component.intrinsicContentSize(for: content)
        }
        else {
            return super.intrinsicContentSize
        }
    }
}

private final class ComponentViewProxy {
    var uiView: UIComponentView?
}

#endif
