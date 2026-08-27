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

## User

> do this change

## Assistant

Converted every equation in the README's mathematical terminology section to
the delimiter syntax shared by VS Code and GitHub Markdown. All inline
`\(...\)` delimiters are now `$...$`, and all display `\[...\]` delimiters are
now `$$...$$`. The LaTeX inside each equation is unchanged.

Verified that no legacy delimiters remain and that the Markdown diff has no
whitespace errors. The documentation change was committed as `4f3ac5f` (`Use
portable Markdown math delimiters`).

## User

> i'm getting md errors from github now

The user attached GitHub-rendered screenshots showing a truncated parameter
ordering, a missing `cases` terminator error, two rejected `operatorname`
macros, an extra-brace error in the dynamic-programming recurrence, and an
unrendered inline `$d$` inside bold text.

## Assistant

Fixed the GitHub-specific math parsing failures in the README. Raw `<`
characters inside equations were replaced with the TeX comparison command
`\lt`; those characters had truncated the piecewise basis definition, ordered
parameter sequence, maximum-error subscript, and dynamic-programming recurrence.
The corresponding `M>2` comparison now uses `\gt` for consistency.

GitHub's rejected `\operatorname` uses were removed. The distance operator now
uses the allowed `\mathrm{dist}` form, and the `arg min` expression was restated
without an operator macro as

$$
E(T^*;\Gamma)=\min_T E(T;\Gamma).
$$

The signed-distance definition was also reworded so inline math no longer sits
inside a bold Markdown span. Local validation found paired display delimiters,
balanced braces, matched `cases` boundaries, no old delimiters, no raw `<`, and
no remaining `\operatorname` macros. The README fix was committed as `556643f`
(`Fix GitHub math rendering errors`).
