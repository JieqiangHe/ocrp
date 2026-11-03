---
name: jh-ocrp-tbtools
description: Package ocrp as a TBtools plugin (.plugin) and send its translations through TBtools' model (window.tbtools.ai) when that bridge is present. Use when the user mentions an ocrp plugin, installing ocrp in TBtools, or tbmodel / the TBtools model for this reader.
---

# ocrp → TBtools plugin

ocrp stays one `index.html` on GitHub Pages. The plugin is a staged copy of that file, plus pdf.js on disk, plus `tbtools-ai.json`. The Java shell is not copied here: compile and zip with svguest's skill `jh-html-to-tbtools-plugin` (`scripts/build.sh`, `PluginInject.java`). Do not add the ChatGPT / SIWC bridge; ocrp does not use it.

## 1. Model bridge, in the repo

Edit `index.html` (the Pages file), not a fork. `ask(model,msgs,myAc,ui)` is the only model call. When `window.tbtools && window.tbtools.ai` exists, call that and return. Otherwise keep the DeepSeek fetch unchanged, so a normal browser still needs the key.

```js
const tbAi=()=>window.tbtools&&window.tbtools.ai;
// at the top of ask(), before the fetch:
if(tbAi()){
  const ai=window.tbtools.ai,p=ai.chat(msgs.map(m=>({role:m.role,content:String(m.content??'')})),{onDelta:s=>ui.text(s)});
  const stop=()=>{try{ai.abort(p.requestId)}catch(_){}};
  myAc.signal.addEventListener('abort',stop,{once:true});
  if(myAc.signal.aborted){stop();throw Error('aborted')}
  const out=await p;ui.text(out);return{out,cut:0}
}
```

- `onDelta` receives the whole reply so far, not a token. There is no reasoning stream; do not call `ui.think`.
- `abort(requestId)` rejects with message `aborted`. Other codes: `denied`, `busy`, `closed`, `invalid`, `too_many`, `too_large`. Keep a request within 32,000 characters and 20 messages.
- No API key. Skip the first-run card when the bridge is there: `$('mKey').value||tbAi()||($('mKeyFirst').hidden=false)`.
- Opt-in file, copied by the stage script, not committed next to the Pages `index.html`:

```json
{"version": 1, "capabilities": ["chat"]}
```

`chat` is text. Do not declare `vision`; ocrp does not send images.

## 2. Stage

Never package the repo directory itself.

```bash
bash .claude/skills/jh-ocrp-tbtools/scripts/ocrp-stage.sh <ocrp_repo> <staging_dir>
```

The script copies `index.html` to `<staging_dir>/index.html`, rewrites the two pdf.js 3.11.174 CDN urls to `vendor/pdf.min.js` and `vendor/pdf.worker.min.js`, downloads those files and pdf.js's Apache-2.0 `LICENSE`, and copies `tbtools-ai.json`. It leaves the repo's CDN urls alone: Pages keeps loading cdnjs.

Under `file://` a remote `<script src>` is unreliable, and `crossorigin` / SRI would fail. ocrp's tags have neither. pdf-lib is already inlined; do not vendor it again. Do not add another top-level `.jar`.

## 3. Package

From a checkout of svguest:

```bash
bash .claude/skills/jh-html-to-tbtools-plugin/scripts/build.sh <tbtools_jar> <staging_dir> ocrp
```

`<tbtools_jar>` is the TBtools main jar (`WebGuiJPanel.class` inside). Name is `ocrp`: folder, menu item, and tab title. No `MenuConfig.ini` unless the user asks for a submenu. The result is `./ocrp.plugin`. Install it from TBtools' Install Plugin. Commit `ocrp.plugin` only when the user asks to ship it.

Without the jar, follow that skill's stub-classpath note. Do not invent a second `PluginInject`.

## 4. Check

- Staged `index.html` contains `vendor/pdf.min.js` and `tbAi`, and does not contain the cdnjs host.
- `tbtools-ai.json` sits next to `index.html`. No `siwc.json`.
- In a browser build, `ask` still posts to DeepSeek when `window.tbtools` is absent.
- Inside TBtools, one translation completes with no key stored. A Save of the Markdown or the commented PDF must show a Save dialog (the shell hooks downloads). Failures on stderr are prefixed `PluginInject:`.

## Licences

ocrp is GPL-3.0-or-later. pdf.js is Apache-2.0 (the staged `vendor/pdfjs-LICENSE`). pdf-lib is MIT and is already inlined, with its notice. Both can sit inside a GPLv3 build; do not strip those notices.
