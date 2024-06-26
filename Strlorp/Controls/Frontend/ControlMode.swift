//
//  ControlMode.swift
//  Strlorp
//

import Foundation
import GameController

let mode = ControlMode.mode

public enum ControlModeLiteral: String {
    case TEXT_INPUT = "textInput"
    case CAMERA_ROTATE = "cameraRotate"
    case ARBITRARY_CLICK = "arbitraryClick"
    case OFF = "off"
    case EDITOR = "editor"
}
// This class handles different control logic under different control mode

public class ControlMode: Equatable {
    static public let mode = ControlMode()

    private var controlMode = ControlModeLiteral.OFF

    private var keyboardAdapter: KeyboardEventAdapter!
    private var mouseAdapter: MouseEventAdapter!
    private var controllerAdapter: ControllerEventAdapter!

    public func cursorHidden() -> Bool {
        return mouseAdapter?.cursorHidden() ?? false
    }

    public func initialize() {
        let centre = NotificationCenter.default
        let main = OperationQueue.main
        if PlaySettings.shared.noKMOnInput {
            centre.addObserver(forName: UITextField.textDidEndEditingNotification, object: nil, queue: main) { _ in
                ModeAutomaton.onUITextInputEndEdit()
                Toucher.writeLog(logMessage: "uitextinput end edit")
            }
            centre.addObserver(forName: UITextField.textDidBeginEditingNotification, object: nil, queue: main) { _ in
                ModeAutomaton.onUITextInputBeginEdit()
                Toucher.writeLog(logMessage: "uitextinput begin edit")
            }
            centre.addObserver(forName: UITextView.textDidEndEditingNotification, object: nil, queue: main) { _ in
                ModeAutomaton.onUITextInputEndEdit()
                Toucher.writeLog(logMessage: "uitextinput end edit")
            }
            centre.addObserver(forName: UITextView.textDidBeginEditingNotification, object: nil, queue: main) { _ in
                ModeAutomaton.onUITextInputBeginEdit()
                Toucher.writeLog(logMessage: "uitextinput begin edit")
            }
            set(.ARBITRARY_CLICK)
        } else {
            set(.OFF)
        }

        centre.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: main) { _ in
            GCController.current?.extendedGamepad?.valueChangedHandler = {profile, element in
                self.controllerAdapter.handleValueChanged(profile, element)
            }
        }

        Noiaaree.shared!.setupKeyboard(keyboard: { keycode, pressed, isRepeat in
            self.keyboardAdapter.handleKey(keycode: keycode, pressed: pressed, isRepeat: isRepeat)},
          swapMode: ModeAutomaton.onOption)

        if PlaySettings.shared.enableScrollWheel {
            Noiaaree.shared!.setupScrollWheel({deltaX, deltaY in
                self.mouseAdapter.handleScrollWheel(deltaX: deltaX, deltaY: deltaY)
            })
        }

        Noiaaree.shared!.setupMouseMoved({deltaX, deltaY in
            self.mouseAdapter.handleMove(deltaX: deltaX, deltaY: deltaY)
        })

        Noiaaree.shared!.setupMouseButton(left: true, right: false, {_, pressed in
            self.mouseAdapter.handleLeftButton(pressed: pressed)
        })

        Noiaaree.shared!.setupMouseButton(left: false, right: false, {id, pressed in
            self.mouseAdapter.handleOtherButton(id: id, pressed: pressed)
        })

        Noiaaree.shared!.setupMouseButton(left: false, right: true, {id, pressed in
            self.mouseAdapter.handleOtherButton(id: id, pressed: pressed)
        })

        ActionDispatcher.build()
    }

    public func set(_ mode: ControlModeLiteral) {
        let wasHidden = mouseAdapter?.cursorHidden() ?? false
        let first = mouseAdapter == nil
        keyboardAdapter = EventAdapters.keyboard(controlMode: mode)
        mouseAdapter = EventAdapters.mouse(controlMode: mode)
        controllerAdapter = EventAdapters.controller(controlMode: mode)
        controlMode = mode
        if !first {
//            Toast.showHint(title: "should hide cursor? \(mouseAdapter.cursorHidden())",
//                       text: ["current state: " + mode])
        }
        if mouseAdapter.cursorHidden() != wasHidden && settings.keymapping {
            if wasHidden {
                NotificationCenter.default.post(name: NSNotification.Name.playtoolsCursorWillShow,
                                                object: nil, userInfo: [:])
                if screen.fullscreen {
                    screen.switchDock(true)
                }

                if mode == .OFF || mode == .EDITOR {
                    ActionDispatcher.invalidateActions()
                }

                Noiaaree.shared!.unhideCursor()
            } else {
                NotificationCenter.default.post(name: NSNotification.Name.playtoolsCursorWillHide,
                                                object: nil, userInfo: [:])
                Noiaaree.shared!.hideCursor()
                if screen.fullscreen {
                    screen.switchDock(false)
                }
            }
            Toucher.writeLog(logMessage: "cursor show switched to \(!wasHidden)")
        }
    }

    public static func == (lhs: ControlModeLiteral, rhs: ControlMode) -> Bool {
        lhs == rhs.controlMode
    }

    public static func == (lhs: ControlMode, rhs: ControlModeLiteral) -> Bool {
        rhs == lhs
    }

    public static func == (lhs: ControlMode, rhs: ControlMode) -> Bool {
        rhs.controlMode == lhs.controlMode
    }

}

extension NSNotification.Name {
    public static let playtoolsCursorWillHide: NSNotification.Name
                    = NSNotification.Name("playtools.cursorWillHide")

    public static let playtoolsCursorWillShow: NSNotification.Name
                    = NSNotification.Name("playtools.cursorWillShow")
}
