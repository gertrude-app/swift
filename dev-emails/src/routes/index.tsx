import fs from "fs";
import cx from "clsx";
import { clientOnly } from "@solidjs/start";
import { createAsync, query } from "@solidjs/router";
import { createSignal, type Component } from "solid-js";

const Email = clientOnly(() => import(`../components/Email`));
const LightDarkToggle = clientOnly(
  () => import(`../components/LightDarkToggle`),
);

const getHtml = query(async () => {
  "use server";
  return fs.readFileSync(`../index.html`, `utf8`);
}, `html`);

const Home: Component = () => {
  let html = createAsync(() => getHtml())();

  for (const [key, value] of Object.entries(examples)) {
    html = html?.replace(`{{{${key}}}}`, value).replace(`{{${key}}}`, value);
  }

  const [theme, setTheme] = createSignal<"light" | "dark">(`light`);
  const [width, setWidth] = createSignal(600);
  const [dragging, setDragging] = createSignal(false);

  return (
    <div
      class={cx(
        `flex flex-col h-screen w-screen bg-slate-200/60 dark:bg-black`,
        theme(),
      )}
    >
      <main class="flex-grow flex justify-center items-center py-8">
        <Email
          html={html ?? `<h1>error</h1>`}
          width={width()}
          setWidth={setWidth}
          dragging={dragging()}
          setDragging={setDragging}
        />
      </main>
      <footer class="p-6 bg-white dark:bg-slate-900 border-t border-slate-300 dark:border-slate-800 justify-between flex items-center">
        <span
          class={cx(
            `font-mono font-medium px-2 py-0.5 rounded-lg transition-colors duration-200`,
            dragging()
              ? `text-red-600 bg-red-100 dark:text-red-400 dark:bg-red-500/20`
              : `text-slate-500 bg-slate-100 dark:text-slate-400 dark:bg-slate-800`,
          )}
        >
          {width()}px
        </span>
        <LightDarkToggle theme={theme()} setTheme={setTheme} />
      </footer>
    </div>
  );
};

export default Home;

const examples = {
  description: `Some description`,
  userName: `Little Jimmy`,
  explanation: `First this happened, then that happened.`,
  url: `https://gertrude.app`,
  unlockRequests: `3 new <b>network unlock requests</b>`,
  code: `212389`,
  currentYear: String(new Date().getFullYear()),
};
