import { Controller } from "@hotwired/stimulus"

// Manages dark-mode toggling on <html>.
// Persists explicit choice in localStorage; absent key = follow OS.
export default class extends Controller {
  static targets = ["modeButton"]

  connect() {
    this._mql = window.matchMedia("(prefers-color-scheme: dark)")
    this._onSystemChange = () => {
      if (!this._explicit()) this._apply()
    }
    this._mql.addEventListener("change", this._onSystemChange)
    this._apply()
  }

  disconnect() {
    this._mql.removeEventListener("change", this._onSystemChange)
  }

  setMode(event) {
    const mode = event.params.mode
    if (mode === "system") {
      localStorage.removeItem("theme")
    } else {
      localStorage.setItem("theme", mode)
    }
    this._apply()
  }

  toggle() {
    const mode = this._storedMode()
    if (mode === null) {
      localStorage.setItem("theme", "light")
    } else if (mode === "light") {
      localStorage.setItem("theme", "dark")
    } else {
      localStorage.removeItem("theme")
    }
    this._apply()
  }

  _storedMode() {
    return localStorage.getItem("theme")
  }

  _explicit() {
    return this._storedMode() !== null
  }

  _shouldBeDark() {
    const mode = this._storedMode()
    if (mode === "dark") return true
    if (mode === "light") return false
    return this._mql.matches
  }

  _apply() {
    const dark = this._shouldBeDark()
    document.documentElement.classList.toggle("dark", dark)

    const mode = this._storedMode() ?? "system"
    this._highlightActiveButton(mode)
    document.dispatchEvent(new CustomEvent("theme:changed", { detail: { dark } }))
  }

  _highlightActiveButton(mode) {
    for (const btn of this.modeButtonTargets) {
      btn.setAttribute("aria-pressed", btn.dataset.themeModeParam === mode)
    }
  }
}
