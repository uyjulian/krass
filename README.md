# krass

This Kirikiri (2/Z) plugin provides a subtitle renderer for the ASS/SSA (Advanced Substation Alpha/Substation Alpha) subtitle format.

## Building

After cloning submodules and placing `ncbind` and `tp_stub` in the parent directory, a simple `make` will generate `krass.dll`.

## How to use

After `Plugins.link("krass.dll");` is used, the additional functions will be exposed under the `Layer` class. Please read `manual.tjs` for documentation of the interface.

## License

This project is licensed under the MIT license. Please read the `LICENSE` file for more information.
