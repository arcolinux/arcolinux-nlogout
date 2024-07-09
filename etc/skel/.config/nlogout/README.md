# nlogout
`nlogout` is a GUI application that provides a configurable logout/power management menu. It uses a `config.toml` file located in the user's `.config/nlogout` directory to customize the application's appearance and functionality. The application is written in Nim.

![Alt text](https://github.com/DrunkenAlcoholic/arcolinux-nlogout/blob/main/Custom.Catppuccin.Theme.To.Match.Status.Bar.png?raw=true "Example theme to match statusbar")

## Configuration
The `config.toml` file allows you to configure the following aspects of the `nlogout` application:

### Window
- `width`: The width of the application window (in pixels).
- `height`: The height of the application window (in pixels).
- `title`: The title of the application window.
- `background_color`: The background color of the application window (in hex format).

### Font
- `family`: The font family used in the application.
- `size`: The font size used in the application.
- `color`: The font color used in the application (in hex format).

### Button
- `width`: The width of all buttons (in pixels).
- `height`: The height of all buttons (in pixels).
- `padding`: The padding between buttons (in pixels).
- `top_padding`: The padding at the top of each button (in pixels).
- `icon_size`: The size of the icons for all buttons (in pixels).
- `icon_theme`: The theme folder name for the icons (located in `~/.config/nlogout/themes/`).

### Buttons
Each button can be configured with the following options:
- `text`: The text displayed on the button.
- `shortcut`: The keyboard shortcut associated with the button.
- `background_color`: The background color of the button (in hex format).

The available buttons are:
- `cancel`
- `logout`
- `reboot`
- `shutdown`
- `suspend`
- `hibernate`
- `lock`

Additionally, the `programs_to_terminate` setting specifies a list of programs that should be terminated when logging out, this ensures there is only one instance when logging back in.

The `lock_screen_app` setting allows you to specify a custom lock screen application command.

## Installation
1. Clone the repository:
   ```
   git clone https://github.com/DrunkenAlcoholic/nlogout.git
   ```
2. Install the required dependencies:
   ```bash
   nimble install nigui@#head
   nimble install parsetoml
   ```
3. Compile the application:
   ```bash
   nim c -d:release nlogout.nim
   ```
4. Copy the `config.toml` to `~/.config/nlogout/`
5. Create icon themes in `~/.config/nlogout/themes/` (e.g., `~/.config/nlogout/themes/sardi-purple/`)

## Usage
1. Customize the `config.toml` file in the `~/.config/nlogout/` directory to match your preferences.
2. Add SVG icons to your theme folder (e.g., `~/.config/nlogout/themes/sardi-purple/cancel.svg`, `reboot.svg`, etc.)
3. Run the `nlogout` application.
4. Click on the desired button or use keyboard shortcuts to perform the corresponding action (logout, reboot, shutdown, etc.).

## Contributing
If you find any issues or have suggestions for improvements, please feel free to open an issue or submit a pull request.
