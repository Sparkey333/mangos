#import <Capacitor/Capacitor.h>

// Capacitor plugin registration — must match class name in Swift exactly.
CAP_PLUGIN(HapticBridgePlugin, "HapticBridge",
    CAP_PLUGIN_METHOD(play,      CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(supported, CAPPluginReturnPromise);
)
