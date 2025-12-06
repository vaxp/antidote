class ShortcutItem {
  String modifier;
  String key;
  String command;

  ShortcutItem(this.modifier, this.key, this.command);

  String toCsvLine() => '$modifier,$key,$command';
}
