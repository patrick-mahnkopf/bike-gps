import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
override func application(
_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  GeneratedPluginRegistrant.register(with: self)
  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
    
override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

    print("import URL: \(url.absoluteURL)");
    
    if (url.isFileURL) {
        let canAccess = url.startAccessingSecurityScopedResource();
        if (canAccess) {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            let fileName = url.lastPathComponent;
            let newPath = documentsDirectory.appendingPathComponent(fileName);
            print("newPath: \(newPath.absoluteURL)");
            if (url.absoluteURL != newPath.absoluteURL) {
                _ = self.copyFile(at: url, to: newPath);
            } else {
                print("Opened file from app's document directory");
            }
        } else {
            print("Could not access file at: \(url)")
        }
    } else {
        print("URL does not belong to file");
    }

    return super.application(app, open: url, options: options)
  }

func copyFile(at srcURL: URL, to dstURL: URL) -> Bool {
    do {
        if FileManager.default.fileExists(atPath: dstURL.path) {
            try FileManager.default.removeItem(at: dstURL)
        }
        try FileManager.default.copyItem(at: srcURL, to: dstURL)
    } catch (let error) {
        print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
        return false
    }
    return true
}

}
