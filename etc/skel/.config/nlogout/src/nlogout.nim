import std/[os, osproc, strutils, tables, sequtils]
import nigui
import parsetoml

type
  ButtonConfig = object
    text, iconPath, shortcut, backgroundColor: string
    iconSize: int

  WindowConfig = object
    width, height: int
    title, backgroundColor: string

  Config = object
    buttons: Table[string, ButtonConfig]
    window: WindowConfig
    programsToTerminate: seq[string]
    fontFamily: string
    fontSize: int
    fontColor: string
    buttonWidth: int
    buttonHeight: int
    buttonPadding: int
    buttonTopPadding: int
    lockScreenApp: string

const
  CONFIG_PATH = getHomeDir() / ".config/nlogout/config.toml"
  DEFAULT_CONFIG = Config(
    buttons: {
      "cancel": ButtonConfig(text: "Cancel", iconPath: "", shortcut: "Escape", backgroundColor: "#f5e0dc", iconSize: 32),
      "logout": ButtonConfig(text: "Logout", iconPath: "", shortcut: "L", backgroundColor: "#cba6f7", iconSize: 32),
      "reboot": ButtonConfig(text: "Reboot", iconPath: "", shortcut: "R", backgroundColor: "#f5c2e7", iconSize: 32),
      "shutdown": ButtonConfig(text: "Shutdown", iconPath: "", shortcut: "S", backgroundColor: "#f5a97f", iconSize: 32),
      "suspend": ButtonConfig(text: "Suspend", iconPath: "", shortcut: "U", backgroundColor: "#7dc4e4", iconSize: 32),
      "hibernate": ButtonConfig(text: "Hibernate", iconPath: "", shortcut: "H", backgroundColor: "#a6da95", iconSize: 32),
      "lock": ButtonConfig(text: "Lock", iconPath: "", shortcut: "K", backgroundColor: "#8aadf4", iconSize: 32)
    }.toTable,
    window: WindowConfig(width: 740, height: 118, title: "nlogout", backgroundColor: "#FFFFFF"),
    programsToTerminate: @[""],
    fontFamily: "Open Sans",
    fontSize: 16,
    fontColor: "#363a4f",
    buttonWidth: 100,
    buttonHeight: 100,
    buttonPadding: 3,
    buttonTopPadding: 5,
    lockScreenApp: "loginctl lock-session"
  )
  BUTTON_ORDER = ["cancel", "logout", "reboot", "shutdown", "suspend", "hibernate", "lock"]

proc standardizeKeyName(key: string): string =
  result = key.toLower()
  if result.startsWith("key_"):
    result = result[4..^1]
  if result == "esc": result = "escape"
  elif result == "return": result = "enter"

proc hexToRgb(hex: string): Color =
  var hexColor = hex.strip()
  if hexColor.startsWith("#"):
    hexColor = hexColor[1..^1]
  if hexColor.len == 6:
    let
      r = byte(parseHexInt(hexColor[0..1]))
      g = byte(parseHexInt(hexColor[2..3]))
      b = byte(parseHexInt(hexColor[4..5]))
    result = rgb(r, g, b)
  else:
    result = rgb(0.byte, 0.byte, 0.byte)

proc loadConfig(): Config =
  result = DEFAULT_CONFIG
  if fileExists(CONFIG_PATH):
    let toml = parsetoml.parseFile(CONFIG_PATH)
    if toml.hasKey("window"):
      let windowConfig = toml["window"]
      result.window.width = windowConfig.getOrDefault("width").getInt(740)
      result.window.height = windowConfig.getOrDefault("height").getInt(118)
      result.window.title = windowConfig.getOrDefault("title").getStr("nlogout")
      result.window.backgroundColor = windowConfig.getOrDefault("background_color").getStr("#FFFFFF")
    
    if toml.hasKey("buttons"):
      let buttonConfigs = toml["buttons"]
      for key in BUTTON_ORDER:
        if buttonConfigs.hasKey(key):
          let btnConfig = buttonConfigs[key]
          var iconPath = btnConfig.getOrDefault("icon_path").getStr(result.buttons[key].iconPath)
          
          # Resolve relative paths
          if not isAbsolute(iconPath):
            iconPath = getCurrentDir() / iconPath
          
          result.buttons[key] = ButtonConfig(
            text: btnConfig.getOrDefault("text").getStr(result.buttons[key].text),
            iconPath: iconPath,
            shortcut: standardizeKeyName(btnConfig.getOrDefault("shortcut").getStr(result.buttons[key].shortcut)),
            backgroundColor: btnConfig.getOrDefault("background_color").getStr(result.buttons[key].backgroundColor),
            iconSize: btnConfig.getOrDefault("icon_size").getInt(result.buttons[key].iconSize)
          )
    
    if toml.hasKey("programs_to_terminate"):
      result.programsToTerminate = toml["programs_to_terminate"].getElems().mapIt(it.getStr())
    
    if toml.hasKey("font"):
      let fontConfig = toml["font"]
      result.fontFamily = fontConfig.getOrDefault("family").getStr(result.fontFamily)
      result.fontSize = fontConfig.getOrDefault("size").getInt(result.fontSize)
      result.fontColor = fontConfig.getOrDefault("color").getStr(result.fontColor)
    
    if toml.hasKey("button"):
      let buttonConfig = toml["button"]
      result.buttonWidth = buttonConfig.getOrDefault("width").getInt(result.buttonWidth)
      result.buttonHeight = buttonConfig.getOrDefault("height").getInt(result.buttonHeight)
      result.buttonPadding = buttonConfig.getOrDefault("padding").getInt(result.buttonPadding)
      result.buttonTopPadding = buttonConfig.getOrDefault("top_padding").getInt(result.buttonTopPadding)

    if toml.hasKey("lock_screen_app"):
      result.lockScreenApp = toml["lock_screen_app"].getStr(result.lockScreenApp)

proc createButton(cfg: ButtonConfig, config: Config, action: proc()): Control =
  var button = newControl()
  button.width = config.buttonWidth
  button.height = config.buttonHeight

  button.onDraw = proc(event: DrawEvent) =
    let canvas = event.control.canvas
    let buttonWidth = button.width.float
    let buttonHeight = button.height.float

    canvas.areaColor = hexToRgb(cfg.backgroundColor)
    canvas.drawRectArea(0, 0, buttonWidth.int, buttonHeight.int)

    canvas.fontFamily = config.fontFamily
    canvas.fontSize = config.fontSize.float
    canvas.fontBold = true
    canvas.textColor = hexToRgb(config.fontColor)

    var y = config.buttonTopPadding.float

    # Draw icon
    if cfg.iconPath != "" and fileExists(cfg.iconPath):
      var icon = newImage()
      icon.loadFromFile(cfg.iconPath)
      let iconX = (buttonWidth - cfg.iconSize.float) / 2
      let iconY = y
      canvas.drawImage(icon, iconX.int, iconY.int, cfg.iconSize, cfg.iconSize)
      y += cfg.iconSize.float + 5  # Add some padding after the icon

    # Draw text
    let textWidth = canvas.getTextWidth(cfg.text).float
    let textX = (buttonWidth - textWidth) / 2
    canvas.drawText(cfg.text, textX.int, y.int)
    y += config.fontSize.float + 5  # Add some padding after the text

    # Draw shortcut
    let shortcutText = "(" & cfg.shortcut & ")"
    let shortcutWidth = canvas.getTextWidth(shortcutText).float
    let shortcutX = (buttonWidth - shortcutWidth) / 2
    canvas.drawText(shortcutText, shortcutX.int, y.int)

  button.onClick = proc(event: ClickEvent) =
    action()

  return button

proc getDesktopEnvironment(): string =
  let xdgCurrentDesktop = getEnv("XDG_CURRENT_DESKTOP").toLower()
  if xdgCurrentDesktop != "":
    return xdgCurrentDesktop
  
  let desktopSession = getEnv("DESKTOP_SESSION").toLower()
  if desktopSession != "":
    return desktopSession
  
  return "unknown"

proc terminate(sApp: string) =
  discard execCmd("pkill " & sApp)

proc main() =
  let config = loadConfig()
  app.init()

  var window = newWindow()
  window.width = config.window.width
  window.height = config.window.height
  window.title = config.window.title

  var container = newLayoutContainer(Layout_Vertical)
  container.widthMode = WidthMode_Fill
  container.heightMode = HeightMode_Fill
  container.backgroundColor = hexToRgb(config.window.backgroundColor)
  window.add(container)

  # Top spacer
  var spacerTop = newControl()
  spacerTop.widthMode = WidthMode_Fill
  spacerTop.heightMode = HeightMode_Expand
  container.add(spacerTop)

  # Button container
  var buttonContainer = newLayoutContainer(Layout_Horizontal)
  buttonContainer.widthMode = WidthMode_Fill
  buttonContainer.height = config.buttonHeight + (2 * config.buttonPadding)
  container.add(buttonContainer)

  # Left spacer in button container
  var spacerLeft = newControl()
  spacerLeft.widthMode = WidthMode_Expand
  spacerLeft.heightMode = HeightMode_Fill
  buttonContainer.add(spacerLeft)

  proc logout() {.closure.} =
    for program in config.programsToTerminate:
      terminate(program)
    let desktop = getDesktopEnvironment()
    terminate(desktop)
    quit(0)

  let actions = {
    "cancel": proc() {.closure.} = app.quit(),
    "logout": logout,
    "reboot": proc() {.closure.} = discard execCmd("systemctl reboot"),
    "shutdown": proc() {.closure.} = discard execCmd("systemctl poweroff"),
    "suspend": proc() {.closure.} = discard execCmd("systemctl suspend"),
    "hibernate": proc() {.closure.} = discard execCmd("systemctl hibernate"),
    "lock": proc() {.closure.} = 
      if config.lockScreenApp != "":
        discard execCmd(config.lockScreenApp)
      else:
        discard execCmd("loginctl lock-session")
  }.toTable

  for key in BUTTON_ORDER:
    if key in config.buttons and key in actions:
      var button = createButton(config.buttons[key], config, actions[key])
      buttonContainer.add(button)

  # Right spacer in button container
  var spacerRight = newControl()
  spacerRight.widthMode = WidthMode_Expand
  spacerRight.heightMode = HeightMode_Fill
  buttonContainer.add(spacerRight)

  # Bottom spacer
  var spacerBottom = newControl()
  spacerBottom.widthMode = WidthMode_Fill
  spacerBottom.heightMode = HeightMode_Expand
  container.add(spacerBottom)

  window.onKeyDown = proc(event: KeyboardEvent) =
    let keyString = standardizeKeyName($event.key)
    for key, cfg in config.buttons:
      let standardizedShortcut = standardizeKeyName(cfg.shortcut)
      if standardizedShortcut == keyString:
        if key in actions:
          actions[key]()
          return

  window.show()
  app.run()

main()