import { type Component } from "solid-js";
import cx from "clsx";

interface Props {
  html: string;
  width: number;
  setWidth: (width: number) => void;
  dragging: boolean;
  setDragging: (dragging: boolean) => void;
}

const Email: Component<Props> = (props) => (
  <div class="h-full w-full flex justify-center">
    <iframe
      class={cx(
        `bg-white dark:bg-black h-full transition-[border-color] duration-200 border-4 border-slate-800 rounded-2xl dark:border-slate-200 overflow-scroll`,
        props.dragging &&
          `!border-red-300 dark:!border-red-500 pointer-events-none`,
      )}
      style={{
        width: `${props.width}px`,
      }}
      srcdoc={props.html}
    />
    <div
      class="flex items-center justify-center p-2 hover:cursor-col-resize group"
      onMouseDown={(e) => {
        props.setDragging(true);
        const startX = e.clientX;
        const startWidth = props.width;
        const onMouseMove = (e: MouseEvent) => {
          const newWidth = startWidth + (e.clientX - startX) * 2;
          if (newWidth >= 200) {
            props.setWidth(newWidth);
          }
        };
        const onMouseUp = () => {
          props.setDragging(false);
          window.removeEventListener(`mousemove`, onMouseMove);
          window.removeEventListener(`mouseup`, onMouseUp);
        };
        window.addEventListener(`mousemove`, onMouseMove);
        window.addEventListener(`mouseup`, onMouseUp);
      }}
    >
      <div class="w-2 h-20 bg-slate-500/15 dark:bg-slate-300/30 rounded-full group-hover:bg-slate-500/50 dark:group-hover:bg-slate-300/60 group-active:bg-slate-500 dark:group-active:bg-slate-300 group-active:scale-75 transition-[height,background-color,transform] duration-200" />
    </div>
  </div>
);

export default Email;
