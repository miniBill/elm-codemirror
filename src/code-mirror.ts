import { markdown } from "@codemirror/lang-markdown";
import { EditorState } from "@codemirror/state";
import { ViewUpdate } from "@codemirror/view";
import { EditorView } from "@codemirror/view";
import { oneDark } from "@codemirror/theme-one-dark";
import { basicSetup } from "codemirror";

class CodeMirror extends HTMLElement {
    view: EditorView | null;

    constructor() {
        super();
        this.view = null;
    }

    extensions() {
        const mirror = this;
        let plugin = EditorView.updateListener.of((update: ViewUpdate) => {
            if (update.docChanged) {
                let doc = update.state.doc.toString();

                mirror.setAttribute("value", doc);

                let event = new Event("input", {
                    bubbles: true,
                    cancelable: true,
                });
                mirror.dispatchEvent(event);
            }
        });

        return [plugin, basicSetup, markdown(), oneDark];
    }

    static get observedAttributes() {
        return ["value"];
    }

    attributeChangedCallback(
        name: string,
        _oldValue: string,
        newValue: string
    ) {
        switch (name) {
            case "value":
                this.setState(newValue ?? "");
                break;
        }
    }

    setState(doc: string) {
        if (!this.view || doc == this.view.state.doc.toString()) {
            return;
        }

        let editorState = EditorState.create({
            doc: doc,
            extensions: this.extensions(),
            selection: this.view.state.selection,
        });
        this.view.setState(editorState);
    }

    connectedCallback() {
        const shadow = this.attachShadow({ mode: "open" });
        const state = EditorState.create({
            doc: this.getAttribute("value") ?? "",
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
