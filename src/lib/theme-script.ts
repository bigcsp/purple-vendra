/** Runs before the page paints, so there's no flash of the wrong theme. */
export const themeScript = `(function(){try{var t=localStorage.getItem("pv-theme");if(t!=="light"&&t!=="dark"){t=window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light"}document.documentElement.dataset.theme=t}catch(e){}})();`;
