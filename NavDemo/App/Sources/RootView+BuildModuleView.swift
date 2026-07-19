//
//  RootView+BuildModuleView.swift
//  NavDemo
//
//  Created by Pratap Kumar Malempati on 7/19/26.
//

import SwiftUI
import AuthPublicAPI
import HomePublicAPI
import PaymentsPublicAPI

extension RootView {
    
    /// The one place in the codebase that turns an erased route back into
    /// a real screen — used for push, sheet, fullScreenCover, AND deep
    /// links, all funneling through here now.
    ///
    /// TRADE-OFF, stated plainly: this is an `as?` cascade, not a
    /// compiler-exhaustive `switch`. Forgetting to add a new module's
    /// case here means a push/sheet to that module's routes silently
    /// renders EmptyView instead of failing to compile. This used to be
    /// true only for sheets/deep links; collapsing push into the same
    /// AnyHashable path means push now carries the same risk, in
    /// exchange for needing only ONE .navigationDestination registration
    /// no matter how many modules exist. Mitigation: adding a module
    /// already requires touching this file once anyway (to add its
    /// RoutingAdapter + here), so the risk is "forgot a line in a file
    /// you were already editing," not "forgot a file entirely" — and
    /// App/Tests/DeepLinkDispatchTests.swift exercises each module's
    /// route end to end.
    @ViewBuilder
    func buildAny(_ route: AnyHashable) -> some View {
        if let r = route.base as? AuthRoute {
            AuthModule.makeView(for: r, container: container, router: AuthRoutingAdapter(appRouter: router))
        } else if let r = route.base as? HomeRoute {
            HomeModule.makeView(for: r, container: container, router: HomeRoutingAdapter(appRouter: router))
        } else if let r = route.base as? PaymentsRoute {
            PaymentsModule.makeView(for: r, container: container, router: PaymentsRoutingAdapter(appRouter: router))
        } else {
            EmptyView()
        }
    }
    
}
