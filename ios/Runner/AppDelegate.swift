import UIKit
import Flutter
import ZIPFoundation

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
        
        print("import URL: \(url.absoluteURL)")
        
        if (url.isFileURL) {
            _ = handleInputUrl(url: url, options: options)
        } else {
            print("URL does not belong to file")
        }
        
        return super.application(app, open: url, options: options)
    }
    
    func handleInputUrl(url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let targetDirectory = paths[0]
        let canAccess = url.startAccessingSecurityScopedResource()
        if (canAccess) {
            if (url.pathExtension == "zip") {
                print("Extracting zip to: \(targetDirectory)")
                do {
                    try FileManager().createDirectory(at: targetDirectory, withIntermediateDirectories: true, attributes: nil)
                    try FileManager().unzipItem(at: url, to: targetDirectory)
                } catch {
                    print("Extraction of ZIP archive failed with error:\(error)")
                }
            } else {
                _ = handleFile(at: url, to: targetDirectory, options: options)
            }
        } else {
            print("Couldn't access file at: \(url)")
        }
        url.stopAccessingSecurityScopedResource()
        return true
    }
    
    func handleFile(at srcUrl: URL, to dstDirectory: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let fileName = srcUrl.lastPathComponent
        let dstUrl = dstDirectory.appendingPathComponent(fileName)
        print("Destination URL: \(dstUrl.absoluteURL)")
        if (options[.openInPlace] as? Bool) {
            print("Got file with OpenInPlace key => copying to documents")
            _ = copyFile(at: srcUrl, to: dstUrl)
        } else {
            print("Got file without OpenInPlace key => moving to documents")
            _ = moveFile(at: srcUrl, to: dstUrl)
        }
        return true
    }
    
    func copyFile(at srcUrl: URL, to dstUrl: URL) -> Bool {
        do {
            _ = removeExistingFile(at: dstUrl)
            try FileManager.default.copyItem(at: srcUrl, to: dstUrl)
        } catch (let error) {
            print("Could not copy item from: \(srcUrl) to: \(dstUrl), error: \(error)")
            return false
        }
        return true
    }
    
    func moveFile(at srcUrl: URL, to dstUrl: URL) -> Bool {
        do {
            _ = removeExistingFile(at: dstUrl)
            try FileManager.default.moveItem(at: srcUrl, to: dstUrl)
        } catch (let error) {
            print("Could not move file from: \(srcUrl), to: \(dstUrl), error: \(error)")
            return false
        }
        return true
    }
    
    func removeExistingFile(at url: URL) -> Bool {
        if (FileManager.default.fileExists(atPath: url.path)) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch (let error) {
                print("Could not remove file already existing at: \(url), error: \(error)")
                return false
            }
        }
        return true
    }
}
