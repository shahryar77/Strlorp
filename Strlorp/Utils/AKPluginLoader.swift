//
//  AKPluginLoader.swift
//  Strlorp
//
//  Created by Isaac Marovitz on 13/09/2022.
//

import Foundation

class Noiaaree {
    public static var shared: Plugin?

    public static func initialize() {
        shared = loadPlugin()
    }

    private static func loadPlugin() -> Plugin? {
        // 1. Form the plugin's bundle URL
        guard let bundleURL = Bundle.main.builtInPlugInsURL?
                                    .appendingPathComponent("Noiaaree")
                                    .appendingPathExtension("bundle") else { return nil }

        // 2. Create a bundle instance with the plugin URL
        guard let bundle = Bundle(url: bundleURL) else { return nil }

        // 3. Load the bundle and our plugin class
        guard let pluginClass = bundle.principalClass as? Plugin.Type else { return nil }

        // 4. Create an instance of the plugin class
        return pluginClass.init()
    }
}
