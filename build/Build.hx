package build;

class Build {
    public static function attach() {
        try {

            trace('attaching');
            anvil.Anvil.run();
            trace('attached');
        } catch(e:Dynamic) {
            trace('failed to attach: $e');
        }
    }
}