// rollup.config.js
import typescript from "@rollup/plugin-typescript";
import nodeResolve from "@rollup/plugin-node-resolve";
import terser from "@rollup/plugin-terser";

export default {
    input: "src/code-mirror.ts",
    output: {
        dir: "dist",
        format: "es",
        sourcemap: true,
        // plugins: [terser()],
    },
    plugins: [typescript(), nodeResolve()],
};
