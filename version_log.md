# Version Log

Every release of PokeTasks is recorded here, newest first.

## v1.1.1

Bug fix

* Fixed the blank "New subtask" field getting stuck open. If you chose Add Subtask and left the field empty, the task's arrow couldn't collapse it and there was no way to remove it without typing something.
* The arrow now hides the field when you collapse the task. An empty field also cancels itself when you click elsewhere, press Esc, or click the new X button on its right. The field is now focused as soon as it appears.

## v1.1

Bug fix

* Fixed the trash can (top right of the popover) so it now clears completed subtasks as well as completed tasks. Before, it removed completed tasks but left any completed subtasks behind under tasks that were still open. Unchecked subtasks are kept.
* The automatic cleanup follows the same rule. Subtasks use the same shared 6-hour timer as tasks: once it runs, completed tasks and completed subtasks are cleared together.

## v1.0

Initial release

* A to-do list that lives in your Mac's menu bar, where every completed task levels up a Pokémon.
* Generation 1 Pokémon: the three starters with their evolutions, the legendary birds, Mewtwo, and Mew, each with a shiny form.
* Friendship meter, legendary unlocks at level 50, and shiny resets at level 100.
