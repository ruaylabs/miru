# Weird Fixture

Adversarial content: injection attempts, odd characters, CJK, RTL, emoji.

## Script close inside a fence

```html
<script>alert('should be inert, and shown as text')</script>
```

## Script close inside inline code

Inline: `</script>` and `<\/script>` and `</SCRIPT>`.

## Raw HTML blocks (shown as literal text, not executed)

<script>alert('raw block must be dropped')</script>

## Backticks in inline code

A literal backtick: `` ` `` — and `` `nested` `` double.

## Escapes

\*not italic\* and \# not a heading and \`not code\`.

## CJK

見るは鏡、鏡は見る。Markdown 快速预览扩展。한국어 테스트입니다.

## RTL

The preview should remain LTR overall; this line is RTL: שלום, זהו מבחן
و هذه سطر عربي.

## Emoji

🎨 👀 🦀 🔥 ✅ ❌ — 👨‍👩‍👧‍👦 🇯🇵

## Combining marks and unusual spacing

câfé — éléve — naimainen​zero-width-space

## Long inline token (no spaces)

a-very-long-token-without-spaces-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa

## Tables with pipes

| `a|b` in code | escaped |
|---|---|
| pipe inside code span | must not split the cell |
