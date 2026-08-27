# Markdown equation preview compatibility

Date: 2026-08-26

## User

> it doesn't seem like the vscode md viewer is showing the equations properly.
> recommend a fix or a better viewer.

The user attached a screenshot of VS Code's built-in Markdown preview displaying
the README's LaTeX source as ordinary text.

## Assistant

The equations are valid LaTeX, but the README uses `\(...\)` for inline math and
`\[...\]` for display math. VS Code's built-in Markdown preview does not treat
those forms as math delimiters, so Markdown removes the escape backslashes and
shows the remaining source as text.

The recommended fix is to convert inline equations to `$...$` and display
equations to `$$...$$`. This is the best repository format because both VS
Code's built-in KaTeX preview and GitHub Markdown support those delimiters. For
example:

```markdown
A curve of degree $p$ is

$$
C(u)=\frac{\sum_i N_{i,p}(u)w_iP_i}{\sum_i N_{i,p}(u)w_i}.
$$
```

If dollar-delimited equations still fail, verify that VS Code's
`markdown.math.enabled` setting is `true`. It is not the primary problem shown
in the screenshot, because the current delimiters are incompatible with the
built-in preview regardless.

No alternate viewer is necessary for the README's present equations. For more
advanced MathJax features, PDF export, or richer diagrams, **Markdown Preview
Enhanced** is a reasonable optional extension. Viewing the committed README on
GitHub is another dependable check of its final rendering.

References:

- [VS Code Markdown documentation](https://code.visualstudio.com/docs/languages/markdown)
- [GitHub mathematical-expression documentation](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/writing-mathematical-expressions)
- [Markdown Preview Enhanced](https://www.marketplace.visualstudio.com/itemdetails?itemName=shd101wyy.markdown-preview-enhanced)
