import { View, div } from "gpui-kit";
import { exec, focused, nextCommand, run, terminals } from "herdr";

const KEYS = { left: "ctrl+h", down: "ctrl+j", up: "ctrl+k", right: "ctrl+l" };
const VIM = /^g?\.?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?$/i;

const isVim = (program) => !!program && (VIM.test(program.key) || VIM.test(program.name));

// Vim-aware ctrl-h/j/k/l: hand the key to vim/nvim/fzf, otherwise move between panes.
export default class VimNav extends View {
  init(_props, cx) {
    cx.spawn(async (cx) => {
      for (;;) {
        const dir = await nextCommand();
        if (KEYS[dir]) await this.navigate(dir);
        cx.notify();
      }
    });
  }

  async navigate(dir) {
    const terminal = focused()?.terminal;
    const program = terminal && terminals().find((t) => t.address === terminal)?.program;
    if (isVim(program)) await exec("hc", ["keys", terminal, KEYS[dir]]);
    else run("pane.go", { direction: dir });
  }

  render() {
    return div();
  }
}
