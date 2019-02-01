//
//  ViewController.swift
//  MenuTest
//
//  Created by Simeon Saint-Saens on 3/1/19.
//  Copyright © 2019 Two Lives Left. All rights reserved.
//

import UIKit
import SnapKit
import Menu

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let menu = MenuView(title: .text("Hello"), theme: LightMenuTheme())
        menu.itemsSource = { () -> [MenuItem] in
            return [
                ShortcutMenuItem(name: "Right Bottom", shortcut: (.command, "Z"), action: {
                    menu.horizontalContentAlignment = .right
                    menu.verticalContentAlignment = .bottom
                }),
                
                ShortcutMenuItem(name: "Center Bottom", shortcut: (.command, "Z"), action: {
                    menu.horizontalContentAlignment = .center
                    menu.verticalContentAlignment = .bottom
                }),
                ShortcutMenuItem(name: "Left Bottom", shortcut: (.command, "Z"), action: {
                    menu.horizontalContentAlignment = .left
                    menu.verticalContentAlignment = .bottom
                }),
                ShortcutMenuItem(name: "Right Top", shortcut: (.command, "Z"), action: {
                    menu.horizontalContentAlignment = .right
                    menu.verticalContentAlignment = .top
                }),
                ShortcutMenuItem(name: "Center Top", shortcut: (.command, "Z"), action: {
                    menu.horizontalContentAlignment = .center
                    menu.verticalContentAlignment = .top
                }),
                ShortcutMenuItem(name: "Left Top", shortcut: (.command, "Z"), action: {
                    menu.horizontalContentAlignment = .left
                    menu.verticalContentAlignment = .top
                }),
                
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Insert Image…", shortcut: ([.command, .alternate], "I"), action: {}),
                ShortcutMenuItem(name: "Insert Link…", shortcut: ([.command, .alternate], "L"), action: {}),
                
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Help", shortcut: (.command, "?"), action: {}),
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Help", shortcut: (.command, "?"), action: {}),
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Help", shortcut: (.command, "?"), action: {}),
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Help", shortcut: (.command, "?"), action: {}),
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Help", shortcut: (.command, "?"), action: {}),
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Help", shortcut: (.command, "?"), action: {}),
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Help", shortcut: (.command, "?"), action: {}),
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "SFDSa", shortcut: (.command, "?"), action: {}),
                ]
        }
        
        menu.verticalContentAlignment = .top
        menu.horizontalContentAlignment = .center
        
        view.addSubview(menu)
        
        menu.tintColor = .black
        
        menu.snp.makeConstraints {
            make in
            
            make.center.equalToSuperview()
            
            //Menus don't have an intrinsic height
            make.height.equalTo(40)
        }
    }


}

