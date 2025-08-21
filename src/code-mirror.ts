import { markdown } from "@codemirror/lang-markdown";
import { ChangeSet, Compartment, EditorState } from "@codemirror/state";
import { ViewUpdate } from "@codemirror/view";
import { EditorView } from "@codemirror/view";
import { oneDark } from "@codemirror/theme-one-dark";
import { basicSetup } from "codemirror";
import { vim } from "@replit/codemirror-vim";

class CodeMirror extends HTMLElement {
    view: EditorView | null = null;
    #changes: ChangeSet[] = [];
    #appliedChanges: ChangeSet[] = [];
    #vimMode: boolean = false;
    vim: Compartment = new Compartment();

    // constructor() {
    //     super();
    // }

    get vimMode(): boolean {
        return this.#vimMode;
    }

    set vimMode(value: boolean) {
        if (value === this.#vimMode) {
            return;
        }

        this.#vimMode = value;
        this.update();
    }

    get changes(): ChangeSet[] {
        return this.#changes;
    }

    set changes(value: ChangeSet[]) {
        if (
            value.length === this.#changes.length &&
            value.every((v, index) => v === this.#changes[index])
        ) {
            return;
        }

        this.#changes = value;
        this.update();
    }

    extensions() {
        const mirror = this;
        let plugin = EditorView.updateListener.of((update: ViewUpdate) => {
            if (update.docChanged) {
                this.changes.push(update.changes);
                this.#appliedChanges.push(update.changes);
                let doc = update.state.doc.toString();

                let event = new CustomEvent("doc-changed", {
                    bubbles: true,
                    cancelable: true,
                    detail: {
                        changes: update.changes,
                        doc: doc,
                    },
                });
                mirror.dispatchEvent(event);
            }
        });

        return [plugin, this.vim.of([]), basicSetup, markdown(), oneDark];
    }

    update() {
        console.debug("update");
        let changes: ChangeSet[] = [];
        for (
            let index = this.#appliedChanges.length;
            index < this.changes.length;
            index++
        ) {
            changes.push(this.changes[index]!);
        }

        this.view?.dispatch({
            changes: changes,
            effects: this.vim.reconfigure(this.vimMode ? vim() : []),
        });
    }

    override focus(_options?: FocusOptions): void {
        console.debug("focus");
        this.view?.focus();
    }

    connectedCallback() {
        console.debug("connectedCallback");
        const shadow = this.attachShadow({
            mode: "open",
            // delegatesFocus: true,
        });
        const state = EditorState.create({
            doc: this.getAttribute("doc-source") ?? "",
            extensions: this.extensions(),
        });
        this.view = new EditorView({
            state,
            parent: shadow,
        });
    }

    disconnectedCallback() {
        this.view?.destroy();
    }
}

customElements.define("code-mirror", CodeMirror);
