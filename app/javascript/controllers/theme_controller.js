import { Controller } from "@hotwired/stimulus"

// Manages dark-mode toggling on <html>.
// Persists explicit choice in localStorage; absent key = light (cream) default.
export default class extends Controller {
  static targets = ["modeButton"]

  connect() {
    this._mql = window.matchMedia("(prefers-color-scheme: dark)")
    this._onSystemChange = () => {
      if (this._storedMode() === "system") this._apply()
    }
    this._mql.addEventListener("change", this._onSystemChange)
    this._apply()
  }

  disconnect() {
    this._mql.removeEventListener("change", this._onSystemChange)
  }

  setMode(event) {
    const mode = event.params.mode
    localStorage.setItem("theme", mode)
    this._apply()
  }

  toggle() {
    const mode = this._storedMode()
    if (mode === null || mode === "light") {
      localStorage.setItem("theme", "dark")
    } else if (mode === "dark") {
      localStorage.setItem("theme", "system")
    } else {
      localStorage.removeItem("theme")
    }
    this._apply()
  }

  _storedMode() {
    return localStorage.getItem("theme")
  }

  _shouldBeDark() {
    const mode = this._storedMode()
    if (mode === "dark") return true
    if (mode === "system") return this._mql.matches
    return false
  }

  _apply() {
    const dark = this._shouldBeDark()
    document.documentElement.classList.toggle("dark", dark)

    const mode = this._storedMode() ?? "light"
    this._highlightActiveButton(mode)
    document.dispatchEvent(new CustomEvent("theme:changed", { detail: { dark } }))
  }

  _highlightActiveButton(mode) {
    for (const btn of this.modeButtonTargets) {
      btn.setAttribute("aria-pressed", btn.dataset.themeModeParam === mode)
    }
  }
}
