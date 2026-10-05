/// A task that came out of the conversation, which the user can tick off.
class ActionItem {
  const ActionItem({required this.id, required this.text, this.isDone = false});

  /// Unique within its note.
  final String id;
  final String text;
  final bool isDone;

  ActionItem copyWith({bool? isDone}) {
    return ActionItem(id: id, text: text, isDone: isDone ?? this.isDone);
  }
}
