import {
    autocompletion,
    closeBrackets,
    closeBracketsKeymap,
    completionKeymap,
} from "@codemirror/autocomplete";
import { defaultKeymap, history, historyKeymap } from "@codemirror/commands";
import { markdown } from "@codemirror/lang-markdown";
import {
    bracketMatching,
    defaultHighlightStyle,
    foldKeymap,
    indentOnInput,
    syntaxHighlighting,
} from "@codemirror/language";
import { lintKeymap } from "@codemirror/lint";
import { highlightSelectionMatches, searchKeymap } from "@codemirror/search";
import { EditorState } from "@codemirror/state";
import {
    crosshairCursor,
    drawSelection,
    dropCursor,
    highlightActiveLine,
    highlightActiveLineGutter,
    highlightSpecialChars,
    keymap,
    rectangularSelection,
    ViewUpdate,
} from "@codemirror/view";
import { EditorView } from "@codemirror/view";
import { oneDark } from "@codemirror/theme-one-dark";

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

                mirror.setAttribute("doc", doc);

                let event = new CustomEvent("doc-changed", {
                    bubbles: true,
                    cancelable: true,
                    detail: doc,
                });
                mirror.dispatchEvent(event);
            }
        });

        return [
            plugin,
            // lineNumbers(),
            highlightActiveLineGutter(),
            highlightSpecialChars(),
            history(),
            // foldGutter(),
            drawSelection(),
            dropCursor(),
            EditorState.allowMultipleSelections.of(true),
            indentOnInput(),
            syntaxHighlighting(defaultHighlightStyle),
            bracketMatching(),
            closeBrackets(),
            autocompletion(),
            rectangularSelection(),
            crosshairCursor(),
            highlightActiveLine(),
            highlightSelectionMatches(),
            keymap.of([
                ...closeBracketsKeymap,
                ...defaultKeymap,
                ...searchKeymap,
                ...historyKeymap,
                ...foldKeymap,
                ...completionKeymap,
                ...lintKeymap,
            ]),
            markdown(),
            oneDark,
        ];
    }

    static get observedAttributes() {
        return ["doc"];
    }

    attributeChangedCallback(
        name: string,
        _oldValue: string,
        newValue: string
    ) {
        switch (name) {
            case "doc":
                this.setState(newValue ?? "");
                break;
        }
    }

    setState(doc: string) {
        if (!this.view || doc == this.view.state.doc.toString()) {
            return;
        }

        let editorState = this.view.state.toJSON();
        editorState.doc = doc;
        this.view.setState(EditorState.fromJSON(editorState));
    }

    connectedCallback() {
        const shadow = this.attachShadow({ mode: "open" });
        const state = EditorState.create({
            doc: this.getAttribute("doc") ?? "",
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
