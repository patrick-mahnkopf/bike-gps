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
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let fileName = url.lastPathComponent;
        let newUrl = documentsDirectory.appendingPathComponent(fileName);
        print("newPath: \(newUrl.absoluteURL)");
        if (options[.openInPlace] as? Bool == true) {
            print("Got file with OpenInPlace key => copying to documents");
            let canAccess = url.startAccessingSecurityScopedResource();
            if (canAccess) {
                _ = self.copyFile(at: url, to: newUrl);
                url.stopAccessingSecurityScopedResource();
            } else {
                print("Couldn't access file at: \(url)")
            }
        } else {
            print("Got file without OpenInPlace key => moving to documents");
            do {
                do {
                    try FileManager.default.removeItem(at: newUrl);
                } catch {}
                _ = url.startAccessingSecurityScopedResource();
                try FileManager.default.moveItem(at: url, to: newUrl);
                url.stopAccessingSecurityScopedResource();
            } catch {
                print(error);
            }
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
