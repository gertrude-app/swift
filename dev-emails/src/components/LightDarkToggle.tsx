import cx from "clsx";
import { effect } from "solid-js/web";
import type { Component } from "solid-js";

interface Props {
  theme: "light" | "dark";
  setTheme: (theme: "light" | "dark") => void;
}

const LightDarkToggle: Component<Props> = (props) => {
  effect(() => {
    console.log(`runnning effect`);
    const savedTheme = localStorage.getItem(`theme`);
    console.log(savedTheme);
    if (savedTheme === `dark`) {
      props.setTheme(`dark`);
    } else if (savedTheme === `light`) {
      props.setTheme(`light`);
    }
  });

  return (
    <div
      class="flex gap-3 items-center cursor-pointer group select-none"
      onClick={() => {
        localStorage.setItem(
          `theme`,
          props.theme === `light` ? `dark` : `light`,
        );
        props.setTheme(props.theme === `light` ? `dark` : `light`);
      }}
    >
      <span class="text-slate-500 dark:text-slate-400">Light</span>
      <div class="w-12 h-6 bg-slate-200 dark:bg-slate-700 rounded-full relative group-hover:bg-slate-300 dark:group-hover:bg-slate-600 transition-colors duration-200">
        <div
          class={cx(
            `absolute w-4 h-4 bg-white dark:bg-black rounded-full top-1 transition-[left] duration-200`,
            props.theme === `light` ? `left-1` : `left-7`,
          )}
        />
      </div>
      <span class="text-slate-500 dark:text-slate-400">Dark</span>
    </div>
  );
};

export default LightDarkToggle;
