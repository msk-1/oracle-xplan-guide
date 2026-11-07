// 保存された配色を、描画前に適用する。既定は暗い配色で、"light" が保存されていれば明るい配色にする
(function () {
  try {
    if (localStorage.getItem("xplan-theme") === "light") {
      document.documentElement.setAttribute("data-theme", "light");
    }
  } catch (e) {
    /* 保存領域が使えない環境では既定の配色のまま */
  }
})();
